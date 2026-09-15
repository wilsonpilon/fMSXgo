;
; ------------------------------------------------------------
;  Apelido interno: Mamute (ver MamuteAssemblerGui.pbi para o resto do
;  historico do modulo). Comando EDIT (MamuteGui_Dispatch(),
;  MamuteAssemblerGui.pbi) - decima-nona leva, SEGUNDA reescrita na mesma
;  sessao depois de feedback do usuario: a 1a reescrita (ListIconGadget +
;  status line) ainda "nao estava como do ZX-81" - o pedido explicito foi
;  "um editor exatamente identico ao do ZX-81... exceto as teclas
;  tokenizadas" (essas nao fazem sentido com teclado de PC de verdade).
;  Modelo adotado, ponto a ponto do que o usuario descreveu:
;
;  - **A LISTAGEM E' a tela** (`G_Screen`, CanvasGadget desenhado a mao,
;    mesma tecnica de MamuteDumpGui.pbi/MamuteScrGui.pbi - nao um
;    EditorGadget de scrollback nem um ListIconGadget nativo, porque
;    precisamos de controle exato sobre QUANDO limpar/rolar) - sem echo de
;    prompt nem mensagem "OK" acumulando (pedido explicito: "nao mostre o
;    prompt e o OK na tela de cima"). So um `G_Status` fino pra erro de
;    sintaxe ou a pergunta de rolagem do LIST.
;  - **Cursor `>` entre o numero da linha e o comando** - a linha atual
;    (`MamuteEditState\CursorIndex`, indice dentro de MamuteEditProgram())
;    e' desenhada com `>` no lugar reservado; as demais linhas mostram um
;    espaco no mesmo lugar (mantem o alinhamento).
;  - **Setas Cima/Baixo movem o cursor** (`#MamuteEdit_UpShortcut`/
;    `DownShortcut`, atalhos de JANELA - funcionam com o campo de entrada
;    em foco, mesmo idioma ja usado pelo historico Cima/Baixo do MON>) -
;    SEM precisar alternar foco entre dois controles (diferente da 1a
;    reescrita, que precisava de TAB pra isso).
;  - **ENTER com o campo VAZIO puxa a linha do cursor pro campo** (pra
;    editar); **ENTER com o campo preenchido** grava a linha digitada
;    (nova ou substituindo por NN) - a mesma logica da 1a reescrita, so que
;    agora decidida pelo conteudo do campo em vez de qual gadget tem foco.
;  - **Quando a tela enche digitando linhas novas, limpa e rola META TELA**
;    (`MamuteEdit_EnsureCursorVisible()`) - pedido explicito do usuario.
;    Mesma funcao tambem cobre a rolagem por SETA (nao foi pedido um
;    comportamento diferente pra esse caso - decisao do Claude por
;    simplicidade/uniformidade, documentada aqui pra o usuario redirecionar
;    se quiser suave-linha-a-linha em vez de meia-tela nesse caso
;    especifico).
;  - **Comando `LIST`** (digitado no mesmo campo, sem NN - mesma logica de
;    "sem numero de linha = comando imediato" de qualquer BASIC classico):
;    limpa a tela, lista a partir da primeira linha; se o programa nao
;    cabe inteiro na tela, pergunta "Rolar mais uma tela? (S/N)" no
;    `G_Status` - a resposta tambem e' digitada no campo + ENTER (reusa o
;    mesmo mecanismo de entrada, sem captura de tecla avulsa). Sim: limpa,
;    mostra a proxima tela INTEIRA (nao meia-tela - diferente do
;    preenchimento automatico), poe o cursor na 1a linha dessa tela nova, e
;    pergunta de novo se ainda sobrar mais programa ("nao para por ali").
;    Nao (ou campo vazio): cancela o prompt, fica na tela atual.
;
;  Escopo continua o mesmo de antes: so aceitar/editar/listar - NEW/AUTO/
;  DELETE/RENUM e o assemblador de verdade (comando A) ficam pra sessoes
;  futuras.
;
;  **Indentacao automatica na listagem (mesma sessao, pedido explicito do
;  usuario)**: "label: coloque um TAB e o label fica na primeira coluna
;  util, diretivas como ORG tem um TAB antes, comandos do Z80 tambem um tab
;  antes, comentario com 3 tabs". So afeta o DESENHO (`MamuteEdit_Repaint`,
;  via `MamuteEdit_FormatLine`) - `RawText`/`Label`/`Instr`/`Operand`/
;  `Comment` continuam guardados exatamente como digitados
;  (`MamuteEditProgram()`), sem reformatar o dado em si; puxar uma linha
;  pro campo de edicao (ENTER com campo vazio) tambem continua mostrando o
;  texto cru, sem o preenchimento - reformatar o que ja esta sendo digitado
;  atrapalharia mais do que ajudaria. Caracteres TAB literais (Chr(9)) nao
;  foram usados pra desenhar - `DrawText()`/GDI no canvas nao expande tab
;  de forma confiavel (ao contrario de um RichEdit) - em vez disso,
;  `MamuteEdit_PadToColumn()` calcula o mesmo alinhamento visual com
;  espacos, usando as mesmas larguras fixas de "tab stop" (8 colunas) que
;  um tab literal teria numa fonte monoespacada.
;
;  **Comandos de gerenciamento do programa-fonte (mesma sessao, pedido
;  explicito do usuario)** - reconhecidos no mesmo campo, sem NN na frente
;  (mesma convencao "sem numero de linha = comando imediato" do LIST):
;  - **`NEW`** - apaga o programa inteiro da memoria (Mamute_AsmNew(),
;    MamuteSupport.pbi), sem confirmacao - mesmo comportamento direto do
;    manual original.
;  - **`DELETE <lininic>[-[<linfin>]]`** - apaga uma linha, um intervalo, ou
;    (`<lininic>-` sem <linfin>) da linha ate o fim do programa - a ultima
;    forma e' extensao sobre o manual (que so documenta com <linfin>
;    explicito), pedido explicito do usuario, mesma convencao do "LIST
;    <li>-" do proprio manual original.
;  - **`RENUM [<novali>[,<antigali>[,<incr>]]]`** - renumera do NUMERO ANTIGO
;    <antigali> em diante pra uma nova sequencia comecando em <novali> com
;    passo <incr> (default 10,10). **Nota**: seguida a ORDEM DE PARAMETROS
;    DO MANUAL ORIGINAL (novali,antigali,incr) - diferente da ordem que o
;    usuario escreveu ao pedir o comando (novalinha,incremento,
;    linhainicialtroca) - ver comentario de Mamute_AsmRenum()
;    (MamuteSupport.pbi) pro detalhe; fica facil trocar se o usuario
;    preferir mesmo a propria ordem.
;  - **`CHANGE '<string1>'[,'<string2>']`** - troca todas as ocorrencias de
;    <string1> por <string2> (ou apaga <string1>, se <string2> for omitido)
;    em qualquer lugar do CORPO de cada linha - sintaxe com virgula+aspas
;    adaptada pro idioma ja usado pelo SH/MS deste projeto (o manual
;    original mostra sem virgula: "CHANGE '<string1>'<string2>").
;  - **`SAVE`**/**`LOAD`** - abrem "Salvar como"/"Abrir" (sem digitar nome,
;    mesmo padrao ja usado pelo LOAD do MON> - MamuteGui_CmdLoad) - gravam/
;    leem o programa-fonte inteiro em ASCII puro (extensao `.mza`, uma
;    linha "NN corpo" por linha do programa) - **NAO** o formato binario
;    proprietario do MegaAssembler original (pedido explicito do usuario:
;    "inicialmente vamos salvar em ASCII... em outra oportunidade vamos
;    tentar ler e interpretar o padrao [proprietario]" - fica pra uma
;    sessao futura).
;  - **`MERGE`** (mesma sessao, pedido explicito do usuario: "igual ao
;    MERGE do BASIC") - mostra o MESMO dialogo do LOAD, mas NAO apaga o
;    programa em memoria - funde os dois; linhas do arquivo com o MESMO
;    numero de uma linha ja existente SOBREPOEM a existente (mesma regra
;    do manual original e do MERGE do BASIC). Reaproveita
;    Mamute_StoreAsmLine() sem nenhuma logica extra - substituir por NN
;    igual ja e' exatamente o que aquela funcao faz.
;  - **`SEARCH`/`LSEARCH`** (mesma sessao, pedido explicito do usuario,
;    sintaxe adaptada em relacao ao manual original): `SEARCH '<string>'`
;    (entre aspas) busca LITERAL, case-sensitive; `SEARCH <string>` (sem
;    aspas) busca LIVRE, case-insensitive - "strings, comandos, labels,
;    etc" (pedido do usuario) - ambas no CORPO cru de cada linha
;    (Mamute_AsmSearch(), MamuteSupport.pbi, mesmo escopo do CHANGE).
;    `SEARCH` liga `St\FilterMode` - a tela passa a mostrar SO as linhas
;    que bateram (`MamuteSearchMatches()`, MamuteSupport.pbi), navegaveis
;    com as MESMAS setas/ENTER-vazio de sempre (`MamuteEdit_ActiveCount()`/
;    `MamuteEdit_SelectProgramLineAt()` abstraem "programa inteiro" vs.
;    "so os resultados" pro resto do codigo nao precisar saber a
;    diferenca) - digitar `LIST` (ou qualquer outro comando/linha nova)
;    sai do filtro automaticamente. `LSEARCH` e' igual, mas manda pra
;    "impressora" (gera PDF, `Mamute_SavePdfListing()`, mesma infra do
;    L/LP/P/V) em vez de filtrar a tela.
;  - **`FIND`** (mesma sessao, pedido explicito do usuario) - so um
;    APELIDO de `SEARCH` (mesmo `Case`, mesmo Mamute_AsmSearch()). No
;    manual original `FIND` procurava so no INICIO de cada linha (mais
;    rapido que o `SEARCH`, que procura em qualquer lugar) - otimizacao
;    que fazia sentido num Z80 a poucos MHz, sem vantagem real num PC, por
;    isso a distincao nao foi replicada aqui.
;  - **`QUIT`** (mesma sessao, pedido explicito do usuario) - fecha a
;    janela do EDIT e volta pro MON>, SEM apagar `MamuteEditProgram()`
;    (que ja e' `Global`, sobrevive ao fechamento por padrao - nada
;    precisou ser feito alem de `Quit = #True`) - um `EDIT` novo continua
;    exatamente de onde parou.
;  - **`A`**/**`A O`** (mesma sessao, pedido explicito do usuario - "o
;    comando mais complexo") - monta o programa-fonte de verdade. Em vez
;    de escrever um compilador novo, `Mamute_AsmAssemble()`
;    (`MamuteSupport.pbi`) reaproveita `Z80Asm.pbi` (o assembler nativo M80/
;    Nestor80 do projeto, modulo 2, ja validado byte a byte contra o
;    N80.exe real) - como o vocabulario do EDIT ja e' um SUBCONJUNTO do que
;    `Z80Asm.pbi` entende, juntar as linhas de `MamuteEditProgram()` (via
;    `RawText`, sem NN) ja produz texto-fonte Nestor80 valido direto, sem
;    tradutor no meio. `A` sozinho so' valida (mostra erro com a linha
;    MAMUTE certa - `Z80Asm::GetAssembleErrorLine()` mapeado de volta via
;    `Mamute_AsmLineNumberAtSourceLine()`, já que a linha K do fonte
;    montado e' sempre o K-esimo elemento de `MamuteEditProgram()` - e
;    posiciona o cursor `>` nela). **`A O`** (espaco obrigatorio - decisao
;    conversada com o usuario: reaproveitar o split Verbo/Argumentos de
;    sempre em vez de escrever um parser dedicado pra "AO" colado, ao
;    custo de nao ser 100% identico ao manual original) tambem GRAVA os
;    bytes montados na RAM simulada, resolvido pelo mapeamento de `PAGE`
;    ATIVO agora - se `ORG 9000` for montado e a Pagina 2 (8000-BFFF)
;    estiver comutada pro Slot 3, e' no Slot 3 que os bytes vao parar
;    (`Mamute_WriteByte()`, mesma funcao/regra de sempre - só escreve de
;    verdade se a célula mapeada for RAM). Mensagens de erro DESCRITIVAS
;    (`Z80Asm::GetAssembleErrorText()`), não os codigos de 1 letra
;    (D/F/M/U/Q/O) do manual original - pedido explicito do usuario
;    ("vai facilitar"). Outras opções do manual (N/U/P/I/R/S/D/H,
;    `/<offset>`) e exportar pra disco ficam pra sessões futuras.
;  - **`MAP`** (mesma sessao, pedido explicito do usuario) - "mostra o
;    endereco inicial e final do programa que esta em memoria". Adaptado
;    pra esta porta: mostra o intervalo da ULTIMA montagem bem-sucedida
;    (`MamuteAsmHasResult`/`LastStartAddr`/`LastEndAddr`, `Global` em
;    `MamuteSupport.pbi`, atualizado por `Mamute_AsmAssemble()`) - `A`
;    sozinho JA' calcula esse intervalo, nao precisa de `A O` (os dois
;    chamam `Z80Asm::Assemble()` por baixo; `O` so' decide se ALEM disso
;    grava na RAM) - confirmado com o usuario antes de implementar. Se
;    nenhuma montagem ainda teve sucesso, mostra mensagem pedindo pra rodar
;    `A` primeiro, em vez de um endereco sem sentido.
;  - **Listagem detalhada PASSO-1/PASSO-2 de `A`/`A O`** (mesma sessao,
;    pedido explicito do usuario: "O comando A original mostra PASSO-1,
;    depois mostra PASSO-2 e lista as linhas do seguinte jeito:
;    numero_da_linha <TAB> o_endereco ou o_valor do EQU <TAB> XXXXXXXX
;    codigos hexa do comando gerado, ate 4, em caso de mais de quatro passa
;    para a linha de baixo <TAB> o conteudo da linha"). `MamuteEdit_
;    ShowPassMessage()`/`MamuteEdit_PumpDelay()` desenham "PASSO-1" e depois
;    "PASSO-2" (~400ms cada, bombeando `WindowEvent()` no meio pra nao
;    congelar a UI - `Delay()` puro trava o `WM_PAINT`, ja documentado em
;    outra parte deste arquivo/CLAUDE.md) antes de montar de verdade. A
;    listagem em si e' gerada por `Z80Asm::GetListingRowCount()`/
;    `GetListingRow()` (novo par de funcoes do modulo 2, `Z80Asm.pbi` -
;    grava uma `Z80ListingRow` por EQU/DEFL/ASET e por bloco de ate 4 bytes
;    de cada diretiva de dado/instrucao de CPU, durante o PASSE 2 real, sem
;    reimplementar o assembler) e formatada por `Mamute_
;    AsmBuildListingLines()` (`MamuteSupport.pbi`) em `MamuteAsmListingLines()`
;    - uma `List` de strings ja prontas pra desenhar, no formato NN/
;    endereco-ou-valor/ate-4-bytes-hex/conteudo-da-linha pedido; linhas de
;    continuacao (mais de 4 bytes) repetem so' a coluna de hex, com NN e
;    endereco em branco. `MamuteEditState\ListingMode` faz `MamuteEdit_
;    ActiveCount()`/`MamuteEdit_Repaint()` mostrarem essa lista em vez do
;    programa-fonte, reaproveitando o MESMO mecanismo de paginacao LIST-
;    style ("Rolar mais uma tela? (S/N)") ja existente - testado ao vivo com
;    um programa de 40+ linhas gerando listagem de 2 telas, cursor
;    reaparecendo corretamente no topo da tela nova a cada rolagem. `A O`
;    entra em `ListingMode` do mesmo jeito que `A` sozinho, so' que grava os
;    bytes na RAM ANTES de montar a lista de exibicao (mesma logica de
;    sempre) - verificado ao vivo mostrando "MONTADO E GRAVADO NA RAM..."
;    junto com a listagem completa. **Decisao do Claude, nao confirmada com
;    o usuario**: linhas `ORG`/`END` NAO geram linha na listagem (nenhum
;    endereco/valor/byte associado a elas no manual original tambem, e nao
;    houve pedido explicito cobrindo esses dois casos) - se o usuario
;    preferir ver `ORG`/`END` listados (por exemplo so' com NN+conteudo, sem
;    endereco/hex), e' so' adicionar as mesmas chamadas `ZListing_AddRow()`
;    (`Z80Asm.pbi`) nos `Case "ORG"`/`Case "END"` de `RunOnePass` - a
;    infraestrutura ja suporta uma linha sem bytes (mesmo caminho do EQU).
;  - **Opcao `N` do comando `A`/`A O`** (mesma sessao, pedido explicito do
;    usuario: "opcao N (por exemplo A O, ou A ON) nao mostra os numeros de
;    linha, de resto e' igual") - `N` e' a opcao do manual original
;    (`MEGASM.TXT` linha 793: "Nao lista o numero das linhas"). O parsing de
;    `AsmFlags` no `Case "A"` deixou de ser uma comparacao de string exata
;    (`= "O"`) e virou um loop caractere a caractere que aceita `O`/`N` em
;    qualquer ordem/combinacao no MESMO token de opcoes (`A O`, `A N`,
;    `A ON`, `A NO`) - mesmo espirito do manual original, onde as letras de
;    opcao vem coladas (`A [NUPOIRSDH/<offset>]`); qualquer outra letra
;    continua rejeitada com `?OPCAO NAO IMPLEMENTADA`. `Mamute_
;    AsmBuildListingLines()`/`Mamute_AsmAssemble()` (`MamuteSupport.pbi`)
;    ganharam um parametro `HideLineNumbers.b` - so' a coluna NN vira
;    `Space(5)` quando ativo, endereco/valor de EQU/bytes hexa/conteudo
;    continuam identicos. Verificado ao vivo: `A ON` (coluna NN em branco +
;    gravacao na RAM), `A N` sozinho (coluna NN em branco, SEM gravar).
;  - **Opcao `P` do comando `A`/`A O`/`A N`** (mesma sessao, pedido explicito
;    do usuario: "o Modificador P do comando A gera a listagem na
;    impressora, ou seja, no PDF, pode ser combinado com as outras opcoes
;    por exemplo A NP, A ONP etc") - `P` e' a opcao do manual original
;    (`MEGASM.TXT` linha 795: "A listagem saira na impressora"), adaptada
;    pra PDF (mesma decisao de projeto ja tomada pro `L`/`LP`/`P`/`V`/
;    `LSEARCH`: "por hora, gere apenas um PDF A4"). Reaproveita
;    `Mamute_SavePdfListing()` (`MamutePdf.pbi`) com a MESMA `List`
;    (`MamuteAsmListingLines()`) que vai pra tela - se `N` tambem estiver
;    ativo, o PDF sai sem numero de linha igual a' tela, sem nenhuma logica
;    extra (a lista ja' foi construida com `HideLineNumbers` aplicado antes
;    de chegar em `P`). `SaveFileRequester()` roda ANTES de decidir a
;    mensagem de status final, e o resultado (nome do arquivo gravado, erro
;    de gravacao, ou nada se o usuario cancelar o dialogo) e' ANEXADO a
;    qualquer que seja a mensagem final (pergunta de rolagem, confirmacao de
;    RAM, ou confirmacao simples) - cancelar o dialogo e' silencioso, mesmo
;    comportamento de desistir de qualquer outro `SaveFileRequester` do
;    projeto. Verificado ao vivo: `A ONP` (RAM gravada + coluna NN em branco
;    + PDF conferido byte a byte contra a listagem da tela, cabecalho
;    "MONTAGEM C100-C11A") e `A P` sozinho com o dialogo cancelado (segue
;    exatamente como um `A` sem `P`, sem sufixo nenhum na mensagem).
;  - **Opcao `I` do comando `A`/`A O`/`A N`/`A P`** (mesma sessao, pedido
;    explicito do usuario: "a I, ela funciona similar a O, salva em DISCO o
;    arquivo, abre o dialogo de save, e salva o header &HFE, os enderecos
;    inicial, final e execucao (ja sugira no dialogo), o slot (ja sugira os
;    ativos no momento) o usuario informa o nome e o binario e criado no
;    formato para o BLOAD do BASIC ou LOAD do Mamute Assembler") - `I` e' a
;    opcao do manual original (`MEGASM.TXT` linha 797: "O codigo-objeto
;    sera armazenado em fita"), adaptada de fita pra DISCO. Reaproveita a
;    MESMA janela do comando `SAVE` do `MON>` (`MamuteSave_Open()`,
;    `MamuteSaveGui.pbi`) - ja tinha exatamente os campos pedidos (arquivo,
;    slot 0-3 sugerido do mapeamento `PAGE` ativo, enderecos inicial/final/
;    execucao editaveis, formato BIN com cabecalho real do BSAVE do MSX:
;    `FE` + 3 enderecos LE). Ganhou um modo "buffer explicito"
;    (`UseExplicitBuffer`/`ExplicitBuf`, novo par de parametros) pra gravar
;    `AsmOutBytes()` (o array recem preenchido por `Mamute_AsmAssemble()`)
;    direto, em vez de exigir que os bytes ja estivessem em `MamuteMem()` -
;    `A I` funciona SOZINHO, sem precisar de `A O` antes (unico call site
;    pre-existente, o `SAVE` do `MON>`, atualizado pra passar um buffer
;    dummy sem mudar nada do comportamento dele). Endereco de execucao
;    sugerido = endereco inicial (mesma convencao ja usada pela propria
;    janela quando o campo fica vazio). Verificado ao vivo: `A I` no
;    programa de 12 linhas - janela abriu com `montagem.bin`/Slot 3/C100/
;    C11A/C100 pre-preenchidos, salvou com sucesso, arquivo conferido byte
;    a byte (`FE 00 C1 1A C1 00 C1` + os 27 bytes exatos da montagem, 34
;    bytes no total); `A ONI` com o dialogo de gravacao cancelado - RAM
;    gravada e numeros de linha escondidos continuaram funcionando, sem
;    nenhum sufixo de `I` (cancelar uma opcao nao afeta as outras).
;  - **Opcao `R` do comando `A`/`A O`/`A N`/`A P`/`A I`** (mesma sessao,
;    pedido explicito do usuario, com um print real do MegaAssembler
;    original de exemplo - `images/msxbasica-19.png`, usando o MESMO
;    programa de teste ja usado nesta sessao inteira: "ela gera no final da
;    listagem uma referencia cruzada dos labels: equ gera o valor e os
;    enderecos onde e' usado, os labels mostra onde foram definidos e onde
;    sao usados") - `R` e' a opcao do manual original ("Mostra uma listagem
;    em referencia cruzada dos labels apos assemblar o programa"). Exigiu
;    um mecanismo NOVO no motor compartilhado (`Z80Asm.pbi`):
;    `EvalPostfixExpr()` (`Case #Z80Tk_Symbol`) agora grava
;    `{nome, CurLoc}` em `SymbolRefs()` toda vez que resolve um simbolo
;    CONHECIDO, mas SO' durante o pass de EMISSAO - finalmente conectou o
;    `Global PassNumber` que ja existia (comentario "1 ou 2 - idem") mas
;    nunca tinha sido escrito de verdade (`RunOnePass()` agora seta
;    `PassNumber = 1`/`2` espelhando `SizeOnly`). `XrefBuildRows()` (fim de
;    `Assemble()`, incondicional em toda montagem bem-sucedida) ordena os
;    simbolos alfabeticamente e agrupa os usos em blocos de ate 4 (`Z80XrefRow`/
;    `GetXrefRowCount()`/`GetXrefRow()`, mesmo padrao de `Z80ListingRow`).
;    `Mamute_AsmBuildXrefLines()` (`MamuteSupport.pbi`) formata em
;    `MamuteAsmXrefLines()` - o `Case "R"` anexa isso (separado por 1 linha
;    em branco) ao FINAL de `MamuteAsmListingLines()` ANTES de calcular a
;    paginacao, virando parte da MESMA listagem/rolagem. Nao distingue
;    EQU/DEFL/ASET de rotulo posicional - `Symbols()\Addr\Value` ja e' o
;    valor certo pros dois casos, sem logica extra (confirmado pelo proprio
;    print: `CHPUT 00A2 C106` e `PRINT C10C C100` usam o MESMO layout de 3
;    colunas). Verificado ao vivo, byte a byte contra o print de
;    referencia: `A R` no programa de 12 linhas (identico ao do print) -
;    `CHPUT 00A2 C106` / `PRINT C10C C100` / `SALT C103 C10A`, EXATAMENTE
;    iguais ao print original. Teste adicional (nao coberto pelo print, so'
;    1 uso por simbolo la'): 5 `CALL CHPUT` extras (6 usos no total) -
;    primeira linha mostrou 4 enderecos, disparou paginacao corretamente, e
;    a segunda tela mostrou a linha de continuacao (nome/valor em branco)
;    com os 2 usos restantes - confirma o fatiamento em blocos de 4 e a
;    integracao com a paginacao existente.
;  - **Opcao `S` do comando `A`/`A O`/`A N`/`A P`/`A I`/`A R`** (mesma
;    sessao, pedido explicito do usuario: "ele gera ao final uma listagem
;    dos labels em ordem alfabetica e o endereco onde foram definidos, digo
;    o endereco para onde apontam") - `S` e' a opcao do manual original
;    ("Gera uma listagem em ordem alfabetica dos labels apos assemblar o
;    programa"). ZERO mudanca em `Z80Asm.pbi` - reaproveita a MESMA tabela
;    `Z80Asm::XrefRows()` ja construida pra "R" (entrada anterior, ja
;    ordenada alfabeticamente), so' que `Mamute_AsmBuildLabelListLines()`
;    (`MamuteSupport.pbi`) ignora `AddrCount`/`Addr0..3` (os enderecos de
;    USO, que sao o que diferencia `R` de `S`) - so' aproveita as linhas
;    com `HasValue`, formatando `NOME  VALOR` simples. Chamada
;    incondicionalmente do fim de `Mamute_AsmAssemble()`, mesmo espirito
;    de `Mamute_AsmBuildXrefLines()` - o `Case "S"` anexa
;    `MamuteAsmLabelListLines()` ao final de `MamuteAsmListingLines()`,
;    DEPOIS do bloco de `R` se os dois estiverem ativos (mesma ordem
;    alfabetica das proprias letras de opcao). Verificado ao vivo: `A RS`
;    no programa de 12 linhas - bloco `R` completo seguido do bloco `S`
;    (so' nome+valor) na mesma listagem/rolagem, paginacao cortando
;    corretamente entre os dois blocos (`SALT`, ultimo alfabeticamente,
;    apareceu certo na segunda tela dentro do bloco `S`); `A S` sozinho -
;    listagem simples `CHPUT 00A2` / `PRINT C10C` / `SALT C103`, sem
;    nenhum endereco de uso.
;  - **Opcao `D` do comando `A`/`A O`/`A N`/`A P`/`A I`/`A R`/`A S`** (mesma
;    sessao, pedido explicito do usuario: "e' identica a A S, porem a lista
;    de labels e' por ordem de aparicao e nao alfabetica") - `D` e' a opcao
;    do manual original ("Gera uma listagem dos labels apos assemblar o
;    programa" - SEM "em ordem alfabetica", diferenca textual exata em
;    relacao a `S`). Exigiu um mecanismo NOVO no motor compartilhado
;    (`Z80Asm.pbi`): `DefineSymbolSeg()` agora captura `WasKnownBefore`
;    (Bool de "ja estava IsKnown ANTES desta chamada") e so' grava em
;    `SymbolDefOrder()` (novo `Global NewList` de strings) na transicao
;    "ainda nao conhecido -> conhecido" - precisou disso porque uma
;    referencia PRA FRENTE (`LD HL,PRINT` antes de `PRINT:` ser definido)
;    ja cria a chave do simbolo no Map como placeholder ANTES da definicao
;    de verdade; gravar na 1a `AddMapElement()` capturaria ordem de 1a
;    MENCAO, nao de definicao. Como o pass 1 varre de cima pra baixo, essa
;    transicao JA e' a ordem de aparicao, sem precisar de `PassNumber` nem
;    numero de linha. `GetLabelDefOrderCount()`/`GetLabelDefOrderName()`
;    (novo par indice+getter) expoem isso pra fora do modulo - so' o NOME,
;    valor vem de `GetSymbolValue()` (ja publico). ZERO Structure nova
;    (diferente de `R`/`S`, que usam `Z80XrefRow`) - so' uma `List` de
;    strings e dois getters simples. `Mamute_AsmBuildLabelOrderLines()`
;    (`MamuteSupport.pbi`) formata o mesmo layout NOME+VALOR de `S`, mas
;    iterando essa nova ordem em vez de `Z80Asm::XrefRows()` - `Case "D"`
;    anexa ao final, DEPOIS do bloco de `S` se os dois estiverem ativos.
;    Verificado ao vivo com um caso onde as ordens REALMENTE divergem
;    (`SALT` definido na linha 40, `PRINT` so' na linha 100 - antes/depois
;    trocados em relacao a' ordem alfabetica): `A DS` mostrou os dois
;    blocos lado a lado, `S` alfabetico (`CHPUT`/`PRINT`/`SALT`) e `D` por
;    aparicao (`CHPUT`/`SALT`/`PRINT`) - confirma que sao ordens
;    genuinamente diferentes, nao coincidentemente iguais; `A D` sozinho -
;    mesma ordem de aparicao, cabendo numa tela so'.
;  - **Opcao `H` do comando `A`, combinada com `S` ou `D`** (mesma sessao,
;    pedido explicito do usuario: "mais um comando A H lista os labels na
;    impressora, deve ser usado com o D ou S") - `H` e' a opcao do manual
;    original ("Lista na impressora os labels"). ZERO mudanca em
;    `Z80Asm.pbi` - reaproveita `MamuteAsmLabelListLines()`/
;    `MamuteAsmLabelOrderLines()` (ja' construidas incondicionalmente pelas
;    entradas de "S"/"D") direto, sem depender delas estarem anexadas a
;    `MamuteAsmListingLines()`. Diferente de "P" (que manda a listagem
;    INTEIRA, codigo incluido, pro PDF): "H" manda SO' a(s) lista(s) de
;    labels, num PDF SEPARADO, independente de "P" tambem estar ativo ou
;    nao - leitura literal do pedido ("lista os labels", nao "a listagem
;    inteira"). Validacao explicita ANTES de montar: "H" sem "S" nem "D"
;    e' rejeitado com mensagem propria (nao ha lista nenhuma pra
;    imprimir), verificada junto com o check de `AsmFlagsOk` existente,
;    antes de sequer chamar `Mamute_AsmAssemble()`. Se "S" e "D"
;    estiverem ativos junto com "H", as duas listas vao pro MESMO
;    documento PDF, separadas por 1 linha em branco - mesma convencao de
;    separacao ja usada na tela. Verificado ao vivo: `A H` sozinho -
;    rejeitado corretamente, sem entrar em `ListingMode`; `A DSH` -
;    dialogo "Salvar labels (A H) como PDF" abriu, PDF conferido byte a
;    byte (cabecalho "LABELS C100-C11A", bloco `S` alfabetico + linha em
;    branco + bloco `D` por ordem de aparicao, identico ao que aparece na
;    tela), status final combinando a pergunta de rolagem com a
;    confirmacao do PDF.
;  - **Opcao `/<offset>` do comando `A`** (mesma sessao, PEDIDO EXPLICITO
;    DO USUARIO, ultima desta serie: "por fim, um comando /<offset>, este
;    comando compila o programa mas adiciona o OFFSET ao ORG para gerar em
;    outro endereco") - opcao do manual original ("Assembla o programa
;    para o endereco indicado pela pseudo-instrucao ORG gerando o codigo-
;    objeto no endereco dado pelo ORG mais <offset>"). ZERO mudanca em
;    `Z80Asm.pbi` - a solucao ficou inteira em `Mamute_AsmAssemble()`
;    (`MamuteSupport.pbi`, novo parametro `OffsetValue.i = 0`): ao
;    reconstruir o texto-fonte, toda linha `Instr = "ORG"` tem seu
;    operando envolvido em `(...)+0XXXXh` (parenteses por seguranca,
;    "0" na frente garante que o Z80Asm nunca confunda com um label mesmo
;    comecando com A-F) ANTES de passar pro assembler - o resto da
;    montagem (rotulos, saltos relativos, listagem, xref) segue
;    AUTOMATICAMENTE o ORG deslocado, ja que e' so' aritmetica resolvida
;    pelo proprio avaliador de expressao do Z80Asm. Se houver mais de um
;    `ORG`, o MESMO offset e' somado a todos. Sintaxe: `/` SEPARADA das
;    letras de flag - detectada ANTES do loop caractere-a-caractere
;    (`FindString(AsmFlags, "/")`), tudo depois dela e' o offset
;    (`Mamute_ParseHexAddr()`, 0000-FFFF), nao mais uma flag - combina com
;    qualquer outra opcao no mesmo token (`A O/8000`). Offset ausente/
;    invalido e' rejeitado ANTES de montar, mensagem propria distinta da
;    generica de flag invalida. Verificado ao vivo, byte a byte: `A
;    O/1000` no programa de teste padrao (`ORG 0C100H`) - TODO o programa
;    assemblado em D100-D11A em vez de C100-C11A, incluindo a referencia
;    interna `LD HL,PRINT` (corretamente `21 0C D1`, apontando pro
;    `PRINT:` deslocado em D10C), enquanto `CHPUT` (EQU, sem relacao com
;    ORG) e o salto relativo `JR SALT` (`18 F7`, offset relativo entre
;    duas posicoes que se moveram JUNTAS) continuaram corretamente
;    inalterados; `A O/ZZZZ` (nao-hexa) - rejeitado corretamente.
; ------------------------------------------------------------
;

#MamuteEdit_EnterShortcut  = 9501
#MamuteEdit_UpShortcut     = 9502
#MamuteEdit_DownShortcut   = 9503
#MamuteEdit_EscapeShortcut = 9504

#MamuteEdit_TabWidth    = 8  ; largura de 1 "tab stop", mesma convencao classica de assembler
#MamuteEdit_LabelCol    = #MamuteEdit_TabWidth      ; instrucao comeca aqui (1 tab depois do label, ou logo no inicio se nao tiver label)
#MamuteEdit_CommentCol  = #MamuteEdit_TabWidth * 3   ; comentario comeca aqui ("3 tabs", pedido explicito)

; Preenche Text com espacos ate TargetCol - se Text ja passou de TargetCol,
; avanca pro proximo multiplo de #MamuteEdit_TabWidth em vez de colar sem
; espaco nenhum (mesmo comportamento de um tab literal que "sempre anda
; pelo menos 1 coluna", mesmo already exatamente num tab-stop).
Procedure.s MamuteEdit_PadToColumn(Text.s, TargetCol.i)
  Protected Col.i = Len(Text)
  If Col >= TargetCol
    TargetCol = ((Col / #MamuteEdit_TabWidth) + 1) * #MamuteEdit_TabWidth
  EndIf
  ProcedureReturn Text + Space(TargetCol - Col)
EndProcedure

; Monta a linha formatada (Label/Instr/Operand/Comment, ja separados por
; Mamute_ParseAsmLine) alinhada em colunas fixas - so pra EXIBICAO na
; listagem (ver nota no topo do arquivo).
Procedure.s MamuteEdit_FormatLine(*Line.MamuteEditLine)
  Protected Text.s = ""
  If *Line\LabelText <> ""
    Text = *Line\LabelText + ":"
  EndIf
  Text = MamuteEdit_PadToColumn(Text, #MamuteEdit_LabelCol)

  Text + *Line\Instr
  If *Line\Operand <> ""
    Text + " " + *Line\Operand
  EndIf

  If *Line\Comment <> ""
    Text = MamuteEdit_PadToColumn(Text, #MamuteEdit_CommentCol)
    Text + ";" + *Line\Comment
  EndIf

  ProcedureReturn Text
EndProcedure

Structure MamuteChangeArgs
  String1.s
  String2.s
EndStructure

; Parser da sintaxe adaptada de CHANGE ('<string1>'[,'<string2>']) - ver
; nota no topo do arquivo sobre a diferenca com o manual original. String1
; sempre precisa vir entre apostrofos; String2 e a virgula sao opcionais.
; Fechamento do apostrofo de String2 tambem opcional (aceita ate o fim da
; entrada se faltar) - mesmo idioma ja usado pelo SH/MS (MamuteAssemblerGui.pbi).
Procedure.b MamuteEdit_ParseChangeArgs(Args.s, *Out.MamuteChangeArgs)
  Protected Trimmed.s = Trim(Args)
  If Left(Trimmed, 1) <> "'"
    ProcedureReturn #False
  EndIf
  Protected Close1.i = FindString(Trimmed, "'", 2)
  If Close1 = 0
    ProcedureReturn #False
  EndIf
  *Out\String1 = Mid(Trimmed, 2, Close1 - 2)
  *Out\String2 = ""

  Protected Rest.s = Trim(Mid(Trimmed, Close1 + 1))
  If Rest <> ""
    If Left(Rest, 1) <> ","
      ProcedureReturn #False
    EndIf
    Protected AfterComma.s = Trim(Mid(Rest, 2))
    If Left(AfterComma, 1) = "'"
      Protected Close2.i = FindString(AfterComma, "'", 2)
      If Close2 > 0
        *Out\String2 = Mid(AfterComma, 2, Close2 - 2)
      Else
        *Out\String2 = Mid(AfterComma, 2)
      EndIf
    EndIf
  EndIf

  ProcedureReturn #True
EndProcedure

Structure MamuteEditState
  TopIndex.i     ; indice (0-based) do 1o elemento mostrado no topo da tela
  CursorIndex.i  ; indice (0-based) da linha com o cursor ">"
  VisibleLines.i ; quantas linhas cabem em G_Screen (calculado 1x a partir da fonte/altura)
  PendingScroll.b ; #True = G_Status esta perguntando "Rolar mais uma tela? (S/N)" (comando LIST OU
                  ; a listagem do comando A, ver ListingMode abaixo)
  FilterMode.b    ; #True = tela mostra so MamuteSearchMatches() (resultado do ultimo SEARCH), nao
                  ; o programa inteiro - TopIndex/CursorIndex acima passam a indexar DENTRO desse
                  ; filtro em vez de MamuteEditProgram() direto (ver MamuteEdit_SelectProgramLineAt()).
  ListingMode.b   ; #True = tela mostra MamuteAsmListingLines() (texto ja' formatado da ultima
                  ; montagem, MamuteSupport.pbi) em vez do programa - NAO usa
                  ; MamuteEdit_SelectProgramLineAt() (linhas de continuacao nao correspondem a
                  ; nenhuma linha REAL de MamuteEditProgram()), Repaint() trata esse caso a parte.
                  ; So' TopIndex/VisibleLines importam aqui (sem cursor ">", e' so' leitura).
EndStructure

; Posicao (0-based) de LineNum dentro de MamuteEditProgram() - usado pra
; mover o cursor pra cima da linha recem-gravada (feedback imediato).
Procedure.i MamuteEdit_IndexOfLine(LineNum.i)
  Protected Idx.i = 0
  ForEach MamuteEditProgram()
    If MamuteEditProgram()\LineNum = LineNum
      ProcedureReturn Idx
    EndIf
    Idx + 1
  Next
  ProcedureReturn -1
EndProcedure

; Quantas "linhas" existem na sequencia ATIVA agora - o programa inteiro,
; ou (FilterMode) so os resultados do ultimo SEARCH (MamuteSearchMatches(),
; MamuteSupport.pbi). Usado por EnsureCursorVisible/Repaint/setas/Baixo pra
; nao precisar checar FilterMode em cada um desses pontos separadamente.
Procedure.i MamuteEdit_ActiveCount(*St.MamuteEditState)
  If *St\ListingMode
    ProcedureReturn ListSize(MamuteAsmListingLines())
  ElseIf *St\FilterMode
    ProcedureReturn ListSize(MamuteSearchMatches())
  Else
    ProcedureReturn ListSize(MamuteEditProgram())
  EndIf
EndProcedure

; Posiciona MamuteEditProgram() na linha REAL correspondente a Position
; dentro da sequencia ATIVA (ver MamuteEdit_ActiveCount() acima) - fora de
; FilterMode, Position JA' e' o indice direto; em FilterMode, Position e'
; um indice dentro de MamuteSearchMatches(), que por sua vez guarda o
; indice real. Devolve #False (MamuteEditProgram() fica numa posicao
; indefinida) se Position estiver fora da faixa valida.
Procedure.b MamuteEdit_SelectProgramLineAt(*St.MamuteEditState, Position.i)
  Protected RealIdx.i
  If *St\FilterMode
    If Position < 0 Or Position >= ListSize(MamuteSearchMatches())
      ProcedureReturn #False
    EndIf
    SelectElement(MamuteSearchMatches(), Position)
    RealIdx = MamuteSearchMatches()
  Else
    RealIdx = Position
  EndIf
  If RealIdx < 0 Or RealIdx >= ListSize(MamuteEditProgram())
    ProcedureReturn #False
  EndIf
  SelectElement(MamuteEditProgram(), RealIdx)
  ProcedureReturn #True
EndProcedure

; Garante que CursorIndex esteja dentro da janela [TopIndex,
; TopIndex+VisibleLines-1] - se nao estiver (linha nova fez a tela
; "encher", ou a seta moveu o cursor pra fora da janela atual), rola por
; METADE de uma tela na direcao certa, repetindo se precisar (pedido
; explicito do usuario: "quando a tela encher, limpe a tela e role metade
; dela pra caber mais linhas"). Opera sobre a sequencia ATIVA (programa
; inteiro OU resultados de SEARCH) via MamuteEdit_ActiveCount().
Procedure MamuteEdit_EnsureCursorVisible(*St.MamuteEditState)
  Protected Total.i = MamuteEdit_ActiveCount(*St)
  If Total = 0
    *St\TopIndex = 0
    *St\CursorIndex = 0
    ProcedureReturn
  EndIf
  If *St\CursorIndex < 0 : *St\CursorIndex = 0 : EndIf
  If *St\CursorIndex > Total - 1 : *St\CursorIndex = Total - 1 : EndIf

  Protected Half.i = *St\VisibleLines / 2
  If Half < 1 : Half = 1 : EndIf

  While *St\CursorIndex < *St\TopIndex
    *St\TopIndex - Half
    If *St\TopIndex < 0 : *St\TopIndex = 0 : EndIf
  Wend
  While *St\CursorIndex >= *St\TopIndex + *St\VisibleLines
    *St\TopIndex + Half
  Wend
EndProcedure

; Redesenha G_Screen inteiro a partir da sequencia ATIVA - o programa
; inteiro, resultados de SEARCH (ver MamuteEdit_SelectProgramLineAt()), OU
; (ListingMode) a listagem pronta da ultima montagem (MamuteAsmListingLines(),
; texto ja' formatado - sem cursor ">", so' leitura, ramo a parte porque
; linhas de continuacao nao correspondem a nenhuma linha REAL de
; MamuteEditProgram()) - comecando em St\TopIndex.
Procedure MamuteEdit_Repaint(G_Screen, *St.MamuteEditState)
  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor()
  If Not StartDrawing(CanvasOutput(G_Screen))
    ProcedureReturn
  EndIf
  DrawingFont(FontID(MamuteGui_Font))
  Box(0, 0, GadgetWidth(G_Screen), GadgetHeight(G_Screen), ColBack)

  Protected LineH.i = TextHeight("Ag")
  Protected Row.i = 0
  Protected Pos.i = *St\TopIndex
  Protected Marker.s, LineText.s

  If *St\ListingMode
    While Row < *St\VisibleLines And Pos < ListSize(MamuteAsmListingLines())
      SelectElement(MamuteAsmListingLines(), Pos)
      DrawText(4, Row * LineH, MamuteAsmListingLines(), ColFront, ColBack)
      Row + 1
      Pos + 1
    Wend
  Else
    While Row < *St\VisibleLines
      If Not MamuteEdit_SelectProgramLineAt(*St, Pos)
        Break
      EndIf
      Marker = " "
      If Pos = *St\CursorIndex : Marker = ">" : EndIf
      LineText = RSet(Str(MamuteEditProgram()\LineNum), 5) + " " + Marker + " " + MamuteEdit_FormatLine(@MamuteEditProgram())
      DrawText(4, Row * LineH, LineText, ColFront, ColBack)
      Row + 1
      Pos + 1
    Wend
  EndIf

  StopDrawing()
EndProcedure

; Limpa G_Screen e desenha so' Text (canto superior esquerdo) - usado pelo
; eco cosmetico "PASSO-1"/"PASSO-2" do comando A (ver MamuteEdit_PumpDelay()
; logo abaixo), reproduzindo o assembler de 2 passagens do manual original.
Procedure MamuteEdit_ShowPassMessage(G_Screen, Text.s)
  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor()
  If StartDrawing(CanvasOutput(G_Screen))
    DrawingFont(FontID(MamuteGui_Font))
    Box(0, 0, GadgetWidth(G_Screen), GadgetHeight(G_Screen), ColBack)
    DrawText(4, 4, Text, ColFront, ColBack)
    StopDrawing()
  EndIf
EndProcedure

; Pausa visivel de Ms milissegundos, mas continua PROCESSANDO mensagens do
; Windows enquanto espera (WindowEvent() num loop, em vez de Delay() cru) -
; senao o desenho de MamuteEdit_ShowPassMessage() logo antes corre o risco
; de nunca chegar a aparecer de verdade na tela (WM_PAINT pendente, janela
; "congelada" pro usuario durante a pausa).
Procedure MamuteEdit_PumpDelay(Ms.i)
  Protected Target.i = ElapsedMilliseconds() + Ms
  Protected Ev.i
  While ElapsedMilliseconds() < Target
    Ev = WindowEvent()
  Wend
EndProcedure

Procedure MamuteEdit_Open(ParentWindow)
  Protected WinW = 800, WinH = 560
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Mamute Assembler - EDIT",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn
  EndIf

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor(), ColBorder = Mamute_CurrentBorderColor()
  SetWindowColor(Win, ColBorder)

  Protected ScreenH = WinH - 16 - 90
  Protected G_Screen = CanvasGadget(#PB_Any, 16, 16, WinW - 32, ScreenH)

  Protected G_Status = TextGadget(#PB_Any, 16, 16 + ScreenH + 6, WinW - 32, 20, "")
  SetGadgetColor(G_Status, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Status, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Status, FontID(MamuteGui_Font))

  Protected G_Prompt = TextGadget(#PB_Any, 16, WinH - 46, 64, 24, "ASM>")
  SetGadgetColor(G_Prompt, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Prompt, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Prompt, FontID(MamuteGui_Font))

  Protected G_Input = StringGadget(#PB_Any, 80, WinH - 48, WinW - 96, 26, "")
  SetGadgetColor(G_Input, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Input, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Input, FontID(MamuteGui_Font))
  GadgetToolTip(G_Input, "NN Label: instrucao operando ;comentario grava. Campo vazio+ENTER edita a linha do cursor (>)." +
                          " LIST/NEW/DELETE/RENUM/CHANGE/SAVE/LOAD/MERGE/SEARCH/FIND/LSEARCH/QUIT/A/A O/MAP sao comandos" +
                          " imediatos (sem NN). Setas navegam.")

  ; Reaplica a fonte - mesmo cuidado de sempre contra App_StyleChildCallback
  ; (BadigEditor.pb) forcando Segoe UI no 1o WM_PAINT de qualquer controle.
  SetGadgetFont(G_Status, FontID(MamuteGui_Font))
  SetGadgetFont(G_Prompt, FontID(MamuteGui_Font))
  SetGadgetFont(G_Input, FontID(MamuteGui_Font))

  Protected St.MamuteEditState
  Protected LineH.i = 16
  If StartDrawing(CanvasOutput(G_Screen))
    DrawingFont(FontID(MamuteGui_Font))
    LineH = TextHeight("Ag")
    StopDrawing()
  EndIf
  If LineH < 1 : LineH = 16 : EndIf
  St\VisibleLines = GadgetHeight(G_Screen) / LineH
  If St\VisibleLines < 1 : St\VisibleLines = 1 : EndIf
  St\TopIndex = 0
  St\CursorIndex = 0
  St\PendingScroll = #False
  MamuteEdit_EnsureCursorVisible(@St)
  MamuteEdit_Repaint(G_Screen, @St)

  SetActiveGadget(G_Input)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteEdit_EnterShortcut)
  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteEdit_UpShortcut)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteEdit_DownShortcut)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteEdit_EscapeShortcut)

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Menu
        Select EventMenu()

          Case #MamuteEdit_UpShortcut
            If Not St\PendingScroll
              St\CursorIndex - 1
              If St\CursorIndex < 0 : St\CursorIndex = 0 : EndIf
              MamuteEdit_EnsureCursorVisible(@St)
              MamuteEdit_Repaint(G_Screen, @St)
            EndIf

          Case #MamuteEdit_DownShortcut
            If Not St\PendingScroll
              Protected TotalD.i = MamuteEdit_ActiveCount(@St)
              If St\CursorIndex < TotalD - 1
                St\CursorIndex + 1
              EndIf
              MamuteEdit_EnsureCursorVisible(@St)
              MamuteEdit_Repaint(G_Screen, @St)
            EndIf

          Case #MamuteEdit_EscapeShortcut
            SetGadgetText(G_Input, "")
            St\PendingScroll = #False
            SetGadgetText(G_Status, "")

          Case #MamuteEdit_EnterShortcut
            Protected Typed.s = Trim(GetGadgetText(G_Input))

            If St\PendingScroll
              ; Resposta ao "Rolar mais uma tela? (S/N)" - do LIST OU da
              ; listagem do comando A (ListingMode) - MamuteEdit_ActiveCount()
              ; ja' sabe qual sequencia esta ativa agora.
              If UCase(Typed) = "S" Or UCase(Typed) = "Y"
                St\TopIndex + St\VisibleLines
                Protected TotalS.i = MamuteEdit_ActiveCount(@St)
                If St\TopIndex > TotalS - 1 : St\TopIndex = TotalS - 1 : EndIf
                If St\TopIndex < 0 : St\TopIndex = 0 : EndIf
                St\CursorIndex = St\TopIndex
                If St\TopIndex + St\VisibleLines < TotalS
                  SetGadgetText(G_Status, "Rolar mais uma tela? (S/N)")
                Else
                  St\PendingScroll = #False
                  SetGadgetText(G_Status, "")
                EndIf
              Else
                St\PendingScroll = #False
                SetGadgetText(G_Status, "")
              EndIf
              SetGadgetText(G_Input, "")

            ElseIf Typed = ""
              ; Campo vazio - puxa a linha do cursor (>) pro campo, pra editar
              ; (funciona tambem dentro de um filtro de SEARCH ativo - so
              ; NAO altera St\FilterMode, mesma navegacao/consulta sem
              ; "sair" do resultado da busca). Em ListingMode nao existe
              ; cursor/linha pra puxar (e' so' leitura) - nao faz nada.
              If Not St\ListingMode And MamuteEdit_SelectProgramLineAt(@St, St\CursorIndex)
                Protected EditText.s = Str(MamuteEditProgram()\LineNum) + " " + MamuteEditProgram()\RawText
                SetGadgetText(G_Input, EditText)
                CompilerIf #PB_Compiler_OS = #PB_OS_Windows
                  SendMessage_(GadgetID(G_Input), #EM_SETSEL, Len(EditText), Len(EditText))
                CompilerEndIf
              EndIf

            Else
              ; Separa Verbo/Argumentos pelo 1o espaco - mesmo idioma de
              ; MamuteGui_Dispatch() (MamuteAssemblerGui.pbi). Um verbo so
              ; pode colidir com uma linha de programa se comecasse com
              ; digito, o que nunca acontece (NEW/DELETE/RENUM/CHANGE/
              ; SAVE/LOAD/LIST comecam com letra).
              Protected VSpacePos.i = FindString(Typed, " ")
              Protected Verb.s, VArgs.s
              If VSpacePos > 0
                Verb = UCase(Left(Typed, VSpacePos - 1))
                VArgs = Trim(Mid(Typed, VSpacePos + 1))
              Else
                Verb = UCase(Typed)
                VArgs = ""
              EndIf

              ; Qualquer comando/gravacao de linha "sai" de um filtro de
              ; SEARCH ou de uma listagem do comando A e volta a mostrar o
              ; programa inteiro - SO o proprio SEARCH/A ligam St\FilterMode/
              ; St\ListingMode de novo, no fim do Case de cada um. Isso cobre
              ; LIST/NEW/DELETE/RENUM/CHANGE/SAVE/LOAD/MERGE/gravar-linha-
              ; nova de uma vez so, sem precisar repetir a mesma linha em
              ; cada Case.
              St\FilterMode = #False
              St\ListingMode = #False

              Select Verb
                Case "LIST"
                  St\TopIndex = 0
                  St\CursorIndex = 0
                  SetGadgetText(G_Input, "")
                  If ListSize(MamuteEditProgram()) > St\VisibleLines
                    St\PendingScroll = #True
                    SetGadgetText(G_Status, "Rolar mais uma tela? (S/N)")
                  Else
                    SetGadgetText(G_Status, "")
                  EndIf

                Case "NEW"
                  Mamute_AsmNew()
                  St\TopIndex = 0
                  St\CursorIndex = 0
                  SetGadgetText(G_Input, "")
                  SetGadgetText(G_Status, "PROGRAMA APAGADO")

                Case "DELETE"
                  Protected DelCount.i = Mamute_AsmDelete(VArgs)
                  If DelCount < 0
                    SetGadgetText(G_Status, "?ERRO DE SINTAXE")
                  Else
                    MamuteEdit_EnsureCursorVisible(@St)
                    SetGadgetText(G_Input, "")
                    SetGadgetText(G_Status, Str(DelCount) + " LINHA(S) APAGADA(S)")
                  EndIf

                Case "RENUM"
                  If Mamute_AsmRenum(VArgs)
                    MamuteEdit_EnsureCursorVisible(@St)
                    SetGadgetText(G_Input, "")
                    SetGadgetText(G_Status, "RENUMERADO")
                  Else
                    SetGadgetText(G_Status, "?ERRO DE SINTAXE")
                  EndIf

                Case "CHANGE"
                  Protected ChArgs.MamuteChangeArgs
                  If MamuteEdit_ParseChangeArgs(VArgs, @ChArgs)
                    Protected ChCount.i = Mamute_AsmChange(ChArgs\String1, ChArgs\String2)
                    MamuteEdit_EnsureCursorVisible(@St)
                    SetGadgetText(G_Input, "")
                    SetGadgetText(G_Status, Str(ChCount) + " LINHA(S) ALTERADA(S)")
                  Else
                    SetGadgetText(G_Status, "?ERRO DE SINTAXE")
                  EndIf

                Case "SAVE"
                  Protected SaveMsg.s = Mamute_AsmSave()
                  SetGadgetText(G_Input, "")
                  If SaveMsg <> ""
                    SetGadgetText(G_Status, SaveMsg)
                  Else
                    SetGadgetText(G_Status, "CANCELADO")
                  EndIf

                Case "LOAD"
                  Protected LoadCount.i = Mamute_AsmLoad()
                  SetGadgetText(G_Input, "")
                  If LoadCount >= 0
                    St\TopIndex = 0
                    St\CursorIndex = 0
                    SetGadgetText(G_Status, Str(LoadCount) + " LINHA(S) CARREGADA(S)")
                  Else
                    SetGadgetText(G_Status, "CANCELADO")
                  EndIf

                Case "MERGE"
                  Protected MergeCount.i = Mamute_AsmMerge()
                  SetGadgetText(G_Input, "")
                  If MergeCount >= 0
                    St\TopIndex = 0
                    St\CursorIndex = 0
                    MamuteEdit_EnsureCursorVisible(@St)
                    SetGadgetText(G_Status, Str(MergeCount) + " LINHA(S) MESCLADA(S)")
                  Else
                    SetGadgetText(G_Status, "CANCELADO")
                  EndIf

                Case "SEARCH", "FIND"
                  ; FIND (manual original) so procurava no INICIO de cada
                  ; linha, mais rapido que o SEARCH (que procura em
                  ; qualquer lugar) - otimizacao que fazia sentido num Z80
                  ; a poucos MHz, irrelevante num PC. Pedido explicito do
                  ; usuario: FIND vira so um apelido do SEARCH, mesmo
                  ; comportamento, sem essa distincao.
                  Protected SearchCount.i = Mamute_AsmSearch(VArgs)
                  SetGadgetText(G_Input, "")
                  If SearchCount < 0
                    SetGadgetText(G_Status, "?ERRO DE SINTAXE")
                  ElseIf SearchCount = 0
                    SetGadgetText(G_Status, "NENHUMA OCORRENCIA")
                  Else
                    St\FilterMode = #True
                    St\TopIndex = 0
                    St\CursorIndex = 0
                    SetGadgetText(G_Status, Str(SearchCount) + " OCORRENCIA(S) - digite LIST pra voltar ao programa completo")
                  EndIf

                Case "LSEARCH"
                  Protected LSCount.i = Mamute_AsmSearch(VArgs)
                  SetGadgetText(G_Input, "")
                  If LSCount < 0
                    SetGadgetText(G_Status, "?ERRO DE SINTAXE")
                  ElseIf LSCount = 0
                    SetGadgetText(G_Status, "NENHUMA OCORRENCIA")
                  Else
                    Protected NewList PdfLines.s()
                    ForEach MamuteSearchMatches()
                      SelectElement(MamuteEditProgram(), MamuteSearchMatches())
                      AddElement(PdfLines())
                      PdfLines() = RSet(Str(MamuteEditProgram()\LineNum), 5) + "   " + MamuteEdit_FormatLine(@MamuteEditProgram())
                    Next
                    Protected LsPath.s = SaveFileRequester("Salvar busca (LSEARCH) como PDF", "busca.pdf", "PDF (*.pdf)|*.pdf", 0)
                    If LsPath = ""
                      SetGadgetText(G_Status, "CANCELADO")
                    Else
                      If LCase(Right(LsPath, 4)) <> ".pdf"
                        LsPath + ".pdf"
                      EndIf
                      If Mamute_SavePdfListing(LsPath, PdfLines(), "LSEARCH " + Trim(VArgs))
                        SetGadgetText(G_Status, "GRAVADO: " + GetFilePart(LsPath))
                      Else
                        SetGadgetText(G_Status, "?ERRO AO GRAVAR PDF")
                      EndIf
                    EndIf
                  EndIf

                Case "QUIT"
                  ; Fecha a janela e volta pro MON> - pedido explicito do
                  ; usuario: NAO apaga MamuteEditProgram() (que e' Global,
                  ; sobrevive a fechamentos de janela por padrao - nao
                  ; precisou de nenhum ClearList() extra) - um EDIT novo
                  ; continua exatamente de onde parou.
                  Quit = #True

                Case "A"
                  ; A [O][N][P][I][R][S][D] - monta o programa-fonte (Mamute_AsmAssemble(),
                  ; MamuteSupport.pbi - reaproveita Z80Asm.pbi por baixo,
                  ; ver comentario de topo daquela procedure). "A" sozinho
                  ; so' valida; "A O" (espaco obrigatorio - decisao
                  ; conversada com o usuario, reaproveita o mesmo split
                  ; Verbo/Argumentos de sempre em vez de um parser dedicado
                  ; pra "AO" colado) tambem grava os bytes montados na RAM
                  ; simulada, resolvido pelo mapeamento de PAGE ATIVO agora
                  ; (Mamute_WriteByte(), mesma regra de sempre - so escreve
                  ; de verdade se a celula mapeada for RAM). "N" (MEGASM.TXT
                  ; linha 793: "Nao lista o numero das linhas") - pedido
                  ; explicito do usuario, combinavel com O no MESMO token de
                  ; flags apos o espaco (ex.: "A ON" ou "A NO", igual ao
                  ; manual original onde as letras de opcao vem coladas -
                  ; "de resto e' igual", so' a coluna NN da listagem fica em
                  ; branco). "P" (MEGASM.TXT linha 795: "A listagem saira na
                  ; impressora") - pedido explicito do usuario: "gera a
                  ; listagem na impressora, ou seja, no PDF, pode ser
                  ; combinado com as outras opcoes por exemplo A NP, A ONP
                  ; etc" - reaproveita Mamute_SavePdfListing() (MamutePdf.pbi,
                  ; mesma infra do LSEARCH/L/LP/P/V) com o MESMO conteudo de
                  ; MamuteAsmListingLines() que vai pra tela (se "N" tambem
                  ; estiver ativo, o PDF sai sem numero de linha igual a
                  ; tela). "I" (MEGASM.TXT linha 797: "O codigo-objeto sera
                  ; armazenado em fita" - adaptado pra DISCO nesta porta) -
                  ; pedido explicito do usuario: "funciona similar a O, salva
                  ; em DISCO o arquivo, abre o dialogo de save, e salva o
                  ; header &HFE, os enderecos inicial, final e execucao (ja
                  ; sugira no dialogo), o slot (ja sugira os ativos no
                  ; momento)... o binario e criado no formato para o BLOAD do
                  ; BASIC ou LOAD do Mamute Assembler" - reaproveita a MESMA
                  ; janela do comando SAVE do MON> (MamuteSave_Open(),
                  ; MamuteSaveGui.pbi), agora com um modo "buffer explicito"
                  ; (UseExplicitBuffer/ExplicitBuf, adicionado nesta sessao)
                  ; que grava os bytes RECEM montados direto, sem depender de
                  ; "A O" ter escrito nada em MamuteMem antes - "I" funciona
                  ; sozinho. "R" (MEGASM.TXT: "Mostra uma listagem em
                  ; referencia cruzada dos labels apos assemblar o programa")
                  ; - pedido explicito do usuario, com um print real do
                  ; MegaAssembler original de exemplo (images/msxbasica-19.png):
                  ; "equ gera o valor e os enderecos onde e' usado, os labels
                  ; mostra onde foram definidos e onde sao usados". Anexa
                  ; MamuteAsmXrefLines() (ja' formatada por Mamute_
                  ; AsmBuildXrefLines(), MamuteSupport.pbi, sempre calculada
                  ; de novo em toda montagem - ver comentario la') ao FINAL
                  ; de MamuteAsmListingLines(), separada por 1 linha em
                  ; branco - vira parte da MESMA listagem/paginacao, nao um
                  ; passo separado. "S" (MEGASM.TXT: "Gera uma listagem em
                  ; ordem alfabetica dos labels apos assemblar o programa")
                  ; - pedido explicito do usuario: "gera ao final uma
                  ; listagem dos labels em ordem alfabetica e o endereco
                  ; onde foram definidos, digo o endereco para onde
                  ; apontam". Mesma tabela alfabetica de "R"
                  ; (Z80Asm::XrefRows()), so' NOME+VALOR sem os enderecos de
                  ; uso - Mamute_AsmBuildLabelListLines() (MamuteSupport.pbi)
                  ; reaproveita as mesmas linhas HasValue, ignora
                  ; AddrCount/Addr0..3. Anexa MamuteAsmLabelListLines() ao
                  ; final (depois do bloco de "R", se os dois estiverem
                  ; ativos), mesmo idioma de separacao por 1 linha em
                  ; branco. "D" (MEGASM.TXT: "Gera uma listagem dos labels
                  ; apos assemblar o programa" - SEM "em ordem alfabetica",
                  ; diferenca textual em relacao a "S" no manual original) -
                  ; pedido explicito do usuario: "e' identica a A S, porem a
                  ; lista de labels e' por ordem de aparicao e nao
                  ; alfabetica". Mesmo layout NOME+VALOR de "S", mas a fonte
                  ; dos nomes e' Z80Asm::GetLabelDefOrderCount()/
                  ; GetLabelDefOrderName() (ordem de DEFINICAO no fonte, novo
                  ; par de funcoes - ver comentario em DefineSymbolSeg(),
                  ; Z80Asm.pbi) em vez de Z80Asm::XrefRows() (alfabetica).
                  ; Anexa MamuteAsmLabelOrderLines() ao final (depois de "S",
                  ; se os tres - R/S/D - estiverem ativos). "H" (MEGASM.TXT:
                  ; "Lista na impressora os labels") - pedido explicito do
                  ; usuario: "lista os labels na impressora, deve ser usado
                  ; com o D ou S" - ao contrario de "P" (que manda a
                  ; listagem INTEIRA, codigo incluido), "H" manda SO' a(s)
                  ; lista(s) de labels (MamuteAsmLabelListLines()/
                  ; MamuteAsmLabelOrderLines(), conforme "S"/"D" estiverem
                  ; ativas - as DUAS, separadas por 1 linha em branco, se os
                  ; dois estiverem ativos junto) pra um PDF separado do de
                  ; "P". Rejeitado explicitamente ANTES de montar (mensagem
                  ; propria, distinta de "opcao nao implementada") se "H"
                  ; vier sozinho, sem "S" nem "D" - nao ha lista nenhuma pra
                  ; imprimir nesse caso. "/<offset>" (MEGASM.TXT: "Assembla
                  ; o programa para o endereco indicado pela pseudo-
                  ; instrucao ORG gerando o codigo-objeto no endereco dado
                  ; pelo ORG mais <offset>") - pedido explicito do usuario:
                  ; "compila o programa mas adiciona o OFFSET ao ORG para
                  ; gerar em outro endereco". Sintaxe: "/" (SEPARADO das
                  ; letras de flag - detectado ANTES do loop caractere a
                  ; caractere, tudo depois da "/" e' o offset, nao mais uma
                  ; flag) seguido de ate 4 digitos hexa (`Mamute_
                  ; ParseHexAddr()`, mesmo parser de endereco ja usado em
                  ; todo o resto do Mamute) - ex. "A O/8000". Repassado pra
                  ; `Mamute_AsmAssemble()` (novo parametro `OffsetValue`,
                  ; MamuteSupport.pbi - ver comentario la' pro detalhe
                  ; completo: soma ao operando de toda linha `ORG`, sem
                  ; tocar Z80Asm.pbi). Outras opcoes do manual original (U)
                  ; ainda nao implementadas - rejeitadas explicitamente em
                  ; vez de ignoradas silenciosamente.
                  Protected AsmFlags.s = UCase(Trim(VArgs))
                  Protected AsmOffsetValue.i = 0
                  Protected AsmHasOffset.b = #False
                  Protected AsmOffsetOk.b = #True
                  Protected AsmSlashPos.i = FindString(AsmFlags, "/")
                  Protected AsmLetterPart.s = AsmFlags
                  If AsmSlashPos > 0
                    AsmLetterPart = Left(AsmFlags, AsmSlashPos - 1)
                    Protected AsmOffsetText.s = Mid(AsmFlags, AsmSlashPos + 1)
                    If AsmOffsetText = "" Or Not Mamute_ParseHexAddr(AsmOffsetText, @AsmOffsetValue)
                      AsmOffsetOk = #False
                    Else
                      AsmHasOffset = #True
                    EndIf
                  EndIf
                  Protected AsmHasO.b = #False
                  Protected AsmHasN.b = #False
                  Protected AsmHasP.b = #False
                  Protected AsmHasI.b = #False
                  Protected AsmHasR.b = #False
                  Protected AsmHasS.b = #False
                  Protected AsmHasD.b = #False
                  Protected AsmHasH.b = #False
                  Protected AsmFlagsOk.b = #True
                  Protected AsmFlagIdx.i
                  Protected AsmFlagCh.s
                  For AsmFlagIdx = 1 To Len(AsmLetterPart)
                    AsmFlagCh = Mid(AsmLetterPart, AsmFlagIdx, 1)
                    Select AsmFlagCh
                      Case "O"
                        AsmHasO = #True
                      Case "N"
                        AsmHasN = #True
                      Case "P"
                        AsmHasP = #True
                      Case "I"
                        AsmHasI = #True
                      Case "R"
                        AsmHasR = #True
                      Case "S"
                        AsmHasS = #True
                      Case "D"
                        AsmHasD = #True
                      Case "H"
                        AsmHasH = #True
                      Default
                        AsmFlagsOk = #False
                    EndSelect
                  Next
                  If Not AsmFlagsOk
                    SetGadgetText(G_Input, "")
                    SetGadgetText(G_Status, "?OPCAO NAO IMPLEMENTADA (combine 'O'/'N'/'P'/'I'/'R'/'S'/'D'/'H', ex. 'A', 'A O', 'A N', 'A ONPIRSDH')")
                  ElseIf Not AsmOffsetOk
                    SetGadgetText(G_Input, "")
                    SetGadgetText(G_Status, "?OFFSET INVALIDO (hexa, 0000-FFFF, ex. 'A O/8000')")
                  ElseIf AsmHasH And Not (AsmHasS Or AsmHasD)
                    SetGadgetText(G_Input, "")
                    SetGadgetText(G_Status, "?OPCAO H PRECISA DE 'S' OU 'D' JUNTO (ex. 'A SH', 'A DH')")
                  Else
                    SetGadgetText(G_Input, "")
                    ; PASSO-1/PASSO-2 - eco cosmetico do assembler de 2
                    ; passagens do manual original, pedido explicito do
                    ; usuario ("o comando A original mostra PASSO-1, depois
                    ; mostra PASSO-2"). Num PC moderno os 2 passes DE
                    ; VERDADE (dentro de Z80Asm::Assemble(), chamado logo
                    ; depois) sao instantaneos - isso e' so' um flash
                    ; cronometrado (MamuteEdit_PumpDelay() continua
                    ; processando mensagens do Windows durante a pausa, a
                    ; janela nao "congela").
                    MamuteEdit_ShowPassMessage(G_Screen, "PASSO-1")
                    MamuteEdit_PumpDelay(400)
                    MamuteEdit_ShowPassMessage(G_Screen, "PASSO-2")
                    MamuteEdit_PumpDelay(400)

                    Protected AsmRes.MamuteAsmResult
                    Protected Dim AsmOutBytes.a(65535)
                    Mamute_AsmAssemble(@AsmRes, AsmOutBytes(), AsmHasN, AsmOffsetValue)
                    If Not AsmRes\Ok
                      If AsmRes\ErrorLine > 0
                        Protected ErrIdx.i = MamuteEdit_IndexOfLine(AsmRes\ErrorLine)
                        If ErrIdx >= 0
                          St\CursorIndex = ErrIdx
                          MamuteEdit_EnsureCursorVisible(@St)
                        EndIf
                        SetGadgetText(G_Status, "ERRO NA LINHA " + Str(AsmRes\ErrorLine) + ": " + AsmRes\ErrorText)
                      Else
                        SetGadgetText(G_Status, "ERRO: " + AsmRes\ErrorText)
                      EndIf
                    ElseIf AsmRes\ByteCount = 0
                      SetGadgetText(G_Status, "MONTADO SEM ERROS - NADA GERADO (so rotulos/EQU/diretivas)")
                    Else
                      If AsmHasO
                        Protected WByte.i
                        For WByte = 0 To AsmRes\ByteCount - 1
                          Mamute_WriteByte((AsmRes\StartAddr + WByte) & $FFFF, AsmOutBytes(WByte))
                        Next
                        MamuteAsmLastWroteToRam = #True ; ve o comentario junto do Global, MamuteSupport.pbi - habilita o comando FOSSAURO no MON>
                      EndIf

                      ; "P" - manda a MESMA listagem (ja' com/sem NN
                      ; conforme "N") pra um PDF, mesma infra do LSEARCH.
                      ; Feito ANTES de decidir a mensagem de status final,
                      ; pra poder anexar a confirmacao (ou erro) nela -
                      ; cancelar o dialogo (LsPath = "") nao gera nenhum
                      ; sufixo, comportamento silencioso igual a desistir de
                      ; um SaveFileRequester em qualquer outro comando.
                      Protected AsmPdfSuffix.s = ""
                      If AsmHasP
                        Protected AsmPdfPath.s = SaveFileRequester("Salvar montagem (A P) como PDF", "montagem.pdf", "PDF (*.pdf)|*.pdf", 0)
                        If AsmPdfPath <> ""
                          If LCase(Right(AsmPdfPath, 4)) <> ".pdf"
                            AsmPdfPath + ".pdf"
                          EndIf
                          If Mamute_SavePdfListing(AsmPdfPath, MamuteAsmListingLines(),
                                                    "MONTAGEM " + Mamute_Hex4(AsmRes\StartAddr) + "-" + Mamute_Hex4(AsmRes\EndAddr))
                            AsmPdfSuffix = " - PDF: " + GetFilePart(AsmPdfPath)
                          Else
                            AsmPdfSuffix = " - ERRO AO GRAVAR PDF"
                          EndIf
                        EndIf
                      EndIf

                      ; "I" - salva o codigo-objeto RECEM montado direto em
                      ; DISCO, formato BLOAD/BSAVE real do MSX (a MESMA
                      ; janela do comando SAVE do MON>, MamuteSave_Open(),
                      ; MamuteSaveGui.pbi - agora com "buffer explicito" pra
                      ; nao depender de MamuteMem/"A O"). Sugere nome, slot
                      ; (mapeamento PAGE ativo agora), enderecos inicial/
                      ; final/execucao (execucao = inicial, mesma convencao
                      ; ja usada pelo SAVE quando o campo fica vazio) -
                      ; usuario revisa/edita tudo na janela antes de gravar.
                      ; Cancelar e' silencioso (ResultMsg = ""), mesmo
                      ; comportamento de qualquer outro SaveFileRequester do
                      ; projeto.
                      Protected AsmIoSuffix.s = ""
                      If AsmHasI
                        Protected AsmIoMsg.s = MamuteSave_Open(Win, "montagem.bin", #True,
                                                                AsmRes\StartAddr, AsmRes\EndAddr, AsmRes\StartAddr,
                                                                #True, AsmOutBytes())
                        If AsmIoMsg <> ""
                          AsmIoSuffix = " - " + AsmIoMsg
                        EndIf
                      EndIf

                      ; "R" - anexa a referencia cruzada de simbolos (ja'
                      ; formatada por Mamute_AsmBuildXrefLines(), chamada
                      ; incondicionalmente de dentro de Mamute_AsmAssemble())
                      ; ao FINAL de MamuteAsmListingLines(), separada por 1
                      ; linha em branco - antes de decidir a paginacao, pra
                      ; ela contar as linhas extras corretamente.
                      If AsmHasR
                        AddElement(MamuteAsmListingLines())
                        MamuteAsmListingLines() = ""
                        ForEach MamuteAsmXrefLines()
                          AddElement(MamuteAsmListingLines())
                          MamuteAsmListingLines() = MamuteAsmXrefLines()
                        Next
                      EndIf

                      ; "S" - anexa a listagem alfabetica simples de labels
                      ; (ja' formatada por Mamute_AsmBuildLabelListLines(),
                      ; chamada incondicionalmente de dentro de Mamute_
                      ; AsmAssemble()) ao FINAL de MamuteAsmListingLines(),
                      ; separada por 1 linha em branco - depois do bloco de
                      ; "R" (se os dois estiverem ativos), mesmo motivo de
                      ; ordem antes da paginacao.
                      If AsmHasS
                        AddElement(MamuteAsmListingLines())
                        MamuteAsmListingLines() = ""
                        ForEach MamuteAsmLabelListLines()
                          AddElement(MamuteAsmListingLines())
                          MamuteAsmListingLines() = MamuteAsmLabelListLines()
                        Next
                      EndIf

                      ; "D" - anexa a listagem de labels em ORDEM DE
                      ; APARICAO (ja' formatada por Mamute_
                      ; AsmBuildLabelOrderLines(), chamada incondicionalmente
                      ; de dentro de Mamute_AsmAssemble()) ao FINAL de
                      ; MamuteAsmListingLines(), separada por 1 linha em
                      ; branco - depois do bloco de "S" (se os dois
                      ; estiverem ativos), mesmo motivo de ordem antes da
                      ; paginacao.
                      If AsmHasD
                        AddElement(MamuteAsmListingLines())
                        MamuteAsmListingLines() = ""
                        ForEach MamuteAsmLabelOrderLines()
                          AddElement(MamuteAsmListingLines())
                          MamuteAsmListingLines() = MamuteAsmLabelOrderLines()
                        Next
                      EndIf

                      ; "H" - manda SO' a(s) lista(s) de labels (S e/ou D,
                      ; conforme ativas - ja' validado acima que pelo menos
                      ; uma das duas esta' presente) pra um PDF SEPARADO do
                      ; de "P" (que manda a listagem inteira). As duas juntas
                      ; (se "S"/"D" ativas ao mesmo tempo) vao no MESMO
                      ; documento, separadas por 1 linha em branco.
                      Protected AsmHSuffix.s = ""
                      If AsmHasH
                        Protected NewList AsmHLines.s()
                        If AsmHasS
                          ForEach MamuteAsmLabelListLines()
                            AddElement(AsmHLines())
                            AsmHLines() = MamuteAsmLabelListLines()
                          Next
                        EndIf
                        If AsmHasD
                          If AsmHasS
                            AddElement(AsmHLines())
                            AsmHLines() = ""
                          EndIf
                          ForEach MamuteAsmLabelOrderLines()
                            AddElement(AsmHLines())
                            AsmHLines() = MamuteAsmLabelOrderLines()
                          Next
                        EndIf
                        Protected AsmHPath.s = SaveFileRequester("Salvar labels (A H) como PDF", "labels.pdf", "PDF (*.pdf)|*.pdf", 0)
                        If AsmHPath <> ""
                          If LCase(Right(AsmHPath, 4)) <> ".pdf"
                            AsmHPath + ".pdf"
                          EndIf
                          If Mamute_SavePdfListing(AsmHPath, AsmHLines(),
                                                    "LABELS " + Mamute_Hex4(AsmRes\StartAddr) + "-" + Mamute_Hex4(AsmRes\EndAddr))
                            AsmHSuffix = " - LABELS PDF: " + GetFilePart(AsmHPath)
                          Else
                            AsmHSuffix = " - ERRO AO GRAVAR PDF DE LABELS"
                          EndIf
                        EndIf
                      EndIf

                      ; Mostra a LISTAGEM estilo assembler classico
                      ; (MamuteAsmListingLines(), MamuteSupport.pbi, ja'
                      ; formatada por Mamute_AsmBuildListingLines()) em vez
                      ; de so' um resumo de 1 linha - pedido explicito do
                      ; usuario com o formato exato de coluna (numero da
                      ; linha / endereco ou valor do EQU / ate 4 bytes hexa,
                      ; continuando embaixo se precisar / conteudo da
                      ; linha). Paginacao igual ao LIST (tela cheia + "Rolar
                      ; mais uma tela?") se nao couber inteira.
                      St\ListingMode = #True
                      St\TopIndex = 0
                      St\CursorIndex = 0
                      If ListSize(MamuteAsmListingLines()) > St\VisibleLines
                        St\PendingScroll = #True
                        SetGadgetText(G_Status, "Rolar mais uma tela? (S/N)" + AsmPdfSuffix + AsmIoSuffix + AsmHSuffix)
                      ElseIf AsmHasO
                        SetGadgetText(G_Status, "MONTADO E GRAVADO NA RAM " + Mamute_Hex4(AsmRes\StartAddr) + "-" +
                                                 Mamute_Hex4(AsmRes\EndAddr) + " (" + Str(AsmRes\ByteCount) + " BYTES)" + AsmPdfSuffix + AsmIoSuffix + AsmHSuffix)
                      Else
                        SetGadgetText(G_Status, "MONTADO SEM ERROS " + Mamute_Hex4(AsmRes\StartAddr) + "-" +
                                                 Mamute_Hex4(AsmRes\EndAddr) + " (" + Str(AsmRes\ByteCount) + " BYTES)" + AsmPdfSuffix + AsmIoSuffix + AsmHSuffix)
                      EndIf
                    EndIf
                  EndIf

                Case "MAP"
                  ; MAP (MEGASM.TXT linha 780) - "mostra os enderecos inicial
                  ; e final do programa contido na memoria". Adaptado pra
                  ; esta porta: como o "programa em memoria" que faz sentido
                  ; aqui e' o CODIGO-OBJETO montado (nao ha conceito de
                  ; "memoria do EMA" guardando o texto-fonte por endereco -
                  ; MamuteEditProgram() e' so uma lista, nao memoria
                  ; simulada), MAP mostra o intervalo da ULTIMA montagem
                  ; bem-sucedida (MamuteAsmHasResult/LastStartAddr/
                  ; LastEndAddr, MamuteSupport.pbi). "A" sozinho JA' calcula
                  ; esse intervalo (nao precisa de "A O" - os dois chamam o
                  ; mesmo Z80Asm::Assemble() por baixo, "O" so' decide se
                  ; ALEM disso grava na RAM) - pedido explicito do usuario,
                  ; confirmado antes de implementar: "se puder ser calculado
                  ; Ok, caso nao seja possivel calcular, indique que precisa
                  ; compilar... primeiro".
                  SetGadgetText(G_Input, "")
                  If Not MamuteAsmHasResult
                    SetGadgetText(G_Status, "PROGRAMA AINDA NAO MONTADO - USE A (OU A O) PRIMEIRO")
                  ElseIf MamuteAsmLastByteCount = 0
                    SetGadgetText(G_Status, "ULTIMA MONTAGEM NAO GEROU CODIGO (SO ROTULOS/EQU/DIRETIVAS)")
                  Else
                    SetGadgetText(G_Status, "ENDERECO INICIAL: " + Mamute_Hex4(MamuteAsmLastStartAddr) +
                                             "  ENDERECO FINAL: " + Mamute_Hex4(MamuteAsmLastEndAddr))
                  EndIf

                Default
                  ; Grava a linha digitada (nova ou substituindo por NN).
                  Protected NewLine.MamuteEditLine
                  If Mamute_ParseAsmLine(Typed, @NewLine)
                    Mamute_StoreAsmLine(@NewLine)
                    Protected NewIdx.i = MamuteEdit_IndexOfLine(NewLine\LineNum)
                    If NewIdx >= 0
                      St\CursorIndex = NewIdx
                    EndIf
                    MamuteEdit_EnsureCursorVisible(@St)
                    SetGadgetText(G_Status, "")
                    SetGadgetText(G_Input, "")
                  Else
                    SetGadgetText(G_Status, "?ERRO DE SINTAXE")
                  EndIf
              EndSelect
            EndIf

            MamuteEdit_Repaint(G_Screen, @St)
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
