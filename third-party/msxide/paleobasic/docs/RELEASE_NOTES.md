# Release Notes

Notas de lançamento formais, uma entrada por versão com codinome — versão mais recente primeiro.
Para o histórico completo e detalhado sessão a sessão (incluindo versões sem codinome), ver
[`CHANGELOG.md`](../CHANGELOG.md). Para a arquitetura/spec de cada módulo, ver `docs/SPEC.md`.

---

## 8.7.5 — "NOTA NA PORTA" (2026-08-26)

**Tema da versão**: dois recursos novos e independentes chegam ao Mamute Assembler no mesmo dia — um
sistema de **notas por endereço** (comandos `XIM`/`XIC`/`XIL`/`XIS`/`XIR`, mais um campo de carga
automática em `Configurar → Mamute Assembler...`) e um **painel de portas I/O** (`XPP`/`XPI`/`XPO`),
que finalmente dá vida às 6 instruções de I/O do Z80 simulado — antes disso, todo `OUT` era descartado e
todo `IN` sempre lia `$FF`, "Fase 1, sem dispositivo real" desde que a CPU foi escrita. O nome da versão
é um trocadilho com as duas metades: uma "nota" física (post-it) colada numa "porta" (física OU de
I/O) — literalmente o que as duas features fazem juntas.

### Novidades

- **`XIM`/`XIC`/`XIL`/`XIS`** — porta o "note function" do SUPER-X: `XIM <endereço>,<slot>,<tipo>,<texto>`
  adiciona uma nota em memória; `XIC <endereço>` consulta todas as notas daquele endereço direto no
  `MON>` (podem existir mais de uma — 17 coincidências reais confirmadas nas 471 notas originais);
  `XIL`/`XIS` carregam/salvam um arquivo de notas num formato texto novo (UTF-8, `ENDEREÇO;SLOT;TIPO;
  TEXTO`), criado especificamente pra não truncar traduções mais longas que os 60 bytes por nota do
  formato binário original do SUPER-X.
- **As 471 notas do arquivo de exemplo original, já traduzidas pro português, viram um arquivo pronto
  pro uso** (`SUPER-X-PT.notas`, extraído da Ajuda existente via um script descartável) — `XIL` já
  sugere ele por padrão. Escolher justamente esse arquivo no campo novo "Notas SUPER-X padrão"
  (`Configurar → Mamute Assembler...`) marca ele como somente-leitura e cria automaticamente uma cópia
  editável (`SUPER-X-SHADOW.notas`), pra nunca sobrescrever o original sem querer.
- **`XIR`** — visualizador dedicado das notas em memória: uma nota por tela, botões `|<`/`<`/`>`/`>|`
  pra navegar, e o mesmo campo de busca (texto simples ou expressão regular, com ou sem diferenciar
  maiúsculas/minúsculas) já usado pelo `XTP`.
- **`XPP`** — painel de portas I/O: monitora até 256 portas, mostrando "Entrada" (o que o programa
  mandou por `OUT` por último) e "Saída" (o que uma `IN` vai ler) — botões pra incluir/excluir portas,
  edição manual dos dois valores, e destaque visual nas portas que sofreram alguma alteração.
- **`XPI <porta>`**/**`XPO <porta>,<byte>`** — leem/escrevem uma porta manualmente sem abrir o painel,
  criando a porta automaticamente se ainda não estiver lá.
- **As 6 instruções de I/O da CPU Z80 simulada passam a usar o painel de verdade** — `OUT (n),A`,
  `IN A,(n)`, `IN r,(C)`/`OUT (C),r` (ED-prefixadas) e os blocos `INI`/`IND`/`OUTI`/`OUTD` — em vez dos
  stubs "sempre `$FF`"/"descarta" que existiam desde que a CPU foi escrita.

### Bastidores

- **36 comandos com prefixo `X` ao todo** até esta versão (17 até a 8.6.0 + 19 novos nesta sessão,
  incluindo os 8 comandos de disco/`XDK` que tinham ficado de fora do resumo anterior por já existirem
  antes deste registro formal).
- `PI`/`PO` do inventário original do SUPER-X (módulo 45) estavam marcados "fora de escopo, utilidade
  questionável sem hardware de verdade atrás" numa nota de planejamento antiga — resolvido por pedido
  explícito do usuário, dando ao usuário controle manual sobre "Saída" em vez de esperar por uma
  simulação de hardware completa que ainda não existe.
- `XPP` (o comando que abre o painel) não tem equivalente no SUPER-X original — inventado nesta sessão;
  **não confundir com o `PP` do inventário antigo** (mapeador de RAM/segmentos, ainda não portado, e
  provavelmente não portável sem simular o MegaRAM primeiro).
- Toda a lógica de dados nova (inserção ordenada da lista de portas, arquivo de notas texto) foi
  verificada com testes isolados fora do projeto antes de confiar nela dentro do Mamute — incluindo os
  dois casos de fronteira do espaço de portas (porta `0` e porta `255`) e um ciclo completo de
  grava→recarrega do arquivo de notas.
- Sem verificação ao vivo das janelas novas (`XIR`, `XPP`) nem de um programa real rodando `OUT`/`IN`
  via `XGO` — mesmo bloqueio de teclado sintético neste ambiente de automação já documentado em sessões
  anteriores (módulo 45h do `docs/SPEC.md`).
- Ver `docs/SPEC.md`, módulos 45x-45z e 46, para o relato completo de cada decisão de design.

---

## 8.6.0 — "CRUZ CURADA" (2026-08-26)

**Tema da versão**: fecha o arco aberto pela 8.5.0. Naquela versão, a "cruz de modos" do SUPER-X nascia
com uma perna manca — `Char` sem nada por trás. Esta versão implementa o `XH` (editor de
caractere/sprite) e a cruz fecha de verdade, todos os 5 modos ligando pra uma tela real. Mas o resto da
versão foi bem além de só curar a perna: mais 12 comandos do SUPER-X chegaram — ferramentas de memória
intra-slots (`XBT`/`XRT`/`XFL`/`XCM`/`XFD`), checksum (`XCS`/`XTS`), e um salto de qualidade real: o
Mamute Assembler passa a EXECUTAR programas de verdade (`XGO`, com 5 breakpoints nomeados e 3 critérios
de parada "livre"), tracear passo a passo (`XTR`), editar registradores em pares incluindo os
"secretos" (`XRG`), exportar disassembly pra um compilador externo em 4 formatos (`XSD`), e — pela
primeira vez desde que o projeto existe — trocar de cor: `XCO` (nascido `CO`, renomeado por consistência
de prefixo) dá ao terminal, sempre verde-sobre-preto por decisão estética fixa, a paleta REAL de 16
cores do MSX1/TMS9918.

### Novidades

- **`XH`** — editor de caractere/sprite (bitmap 16×16, 4 caracteres/32 bytes por tela, miniatura 2×2
  montada como ficaria na tela MSX de verdade) — completa a cruz de modos de 5 pontas, zero
  placeholders restantes.
- **`XBT`/`XRT`/`XFL`/`XCM`/`XFD`** — transferência de bloco, realocação com ajuste de ponteiros
  absolutos internos, preenchimento, comparação (diferenças ou iguais) e busca por PADRÃO DE
  INSTRUÇÃO decodificada (não bytes crus) — todos "intra-slots", origem e destino podem ser
  slot/sub-slot/VRAM totalmente diferentes.
- **`XCS`/`XTS`** — alterna o tipo de checksum por linha do `XD`, ou calcula um checksum agregado de
  16 bits do bloco inteiro (HEX/BIN/DEC+/DEC±/OCT).
- **`XRG`** — mostra/edita os registradores Z80 simulados em pares, incluindo o par alternado
  `AF'`/`BC'`/`DE'`/`HL'` e o `PC`; `*` limpa tudo exceto a pilha, `+` reseta só a pilha; edita
  qualquer registrador nomeado, mais 5 breakpoints (`BP`/`BP1`/`BP2`/`BP3`/`BPF`) usados pelo `XGO`.
- **`XGO <endereço>[#slot]`** — executa o programa simulado, parando no breakpoint da vez em sequência
  (`BP`→`BP1`→`BP2`→`BP3`→`BPF`) ou rodando "livre" (até o `RET` de topo, até `ESC`, ou até um teto de
  segurança) quando não há breakpoint definido.
- **`XTR <endereço>`** — trace passo a passo interativo: uma instrução por `ENTER`, registradores
  mostrados a cada passo, `ESC` interrompe.
- **`XSD`** — "super disassembler": listagem assembly reassemblável (com `ORG`) pra compilador
  externo, ou exportação de bytes crus em `DEFB`/`DATA` (BASIC, com loop `FOR/READ/POKE/NEXT` já
  pronto)/dados embutidos do X-BASIC — sempre com diálogo "Salvar como".
- **`XCO [<frente>],[<fundo>],[<borda>]`** — cor da tela de verdade, paleta fixa do MSX1 (16 cores,
  índices decimais 0-15, convenção do `COLOR` do MSX BASIC), aplicada ao monitor inteiro (log/entrada
  de comandos, `XD`/`XA`/`XI`/`XH`/`XM`, debugger gráfico, `DM`/`ZAP`/`SCR`/`M`/`EDIT`).

### Bastidores

- **Lacuna de documentação encontrada e fechada, não escondida**: `XH`/`XBT`/`XRT`/`XFL`/`XCM`/`XFD`/
  `XCS`/`XTS` já existiam no código antes desta sessão de release, mas nunca tinham passado por
  `docs/SPEC.md`/`CHANGELOG.md` — registrados agora, de uma vez, junto com os 5 comandos genuinamente
  novos desta sessão (`XRG`/`XGO`/`XTR`/`XSD`/`XCO`, módulos 45j-45n do `SPEC.md`).
- **`XCO`: 72 ocorrências do mesmo par de cores hardcoded em 12 arquivos** — cada janela do Mamute
  guardava sua própria cópia local de `RGB(60, 220, 90)`/`RGB(0, 0, 0)`; todas migradas pra 3 funções
  centrais novas. Uma colisão incidental real (a cor de RAM no minimapa do debugger gráfico usava o
  mesmo valor só por coincidência) foi protegida em vez de trocada, pra não acoplar a codificação
  visual RAM/ROM/BASIC/vazio ao tema escolhido pelo usuário.
- **`XGO`: decisão confirmada com o usuário antes de codar** — o sufixo `#slot-subslot` pedido não é
  implementável sem threadar um parâmetro de alvo por todo o núcleo de execução Z80 (o mesmo núcleo
  compartilhado por `G`/Step/Run/Trace) — escolhido honrar só o slot PRIMÁRIO (via `PAGE` implícito),
  rejeitando sub-slot/VRAM explícito com erro de sintaxe.
- Compilado limpo a cada comando/arquivo tocado nesta sessão; verificação ao vivo completa (clique
  real, screenshots) não pôde ser feita — o `dist\PaleoBasic.exe` ficou travado por um processo já em
  execução durante boa parte da sessão. Rebuild final e empacotamento feitos assim que o processo foi
  encerrado.

---

## 8.5.0 — "CRUZ MANCA" (2026-08-24)

**Tema da versão**: início da portagem do **SUPER-X**, outro monitor/debugger clássico de MSX (mais
avançado que o MegaAssembler que o Mamute Assembler já herdava — breakpoint, notas persistentes por
endereço, exportação de disassembly, mapeador de RAM), pro Mamute Assembler. Quatro comandos batizados
com prefixo `X` pra não colidir com os já existentes (`XD`/`XA`/`XI`/`XM`, versões de `D`/`A`/`I`/`M`)
compartilham a mesma sintaxe de endereçamento estendida e a mesma "cruz de modos" — um menu em formato de
`+` copiado do próprio SUPER-X original que deixa trocar de tela sem digitar outro comando. Nome
escolhido pela própria cruz: dos 5 modos que ela liga (`Dump`/`Ascii`/`Char`/`Multi`/`Disasm`), 4 já
puxam pra uma tela de verdade — só **`Char`** (editor de sprite/fonte) ainda não tem nada por trás,
"AINDA NAO IMPLEMENTADO" no rótulo. Uma cruz de 5 pontas com 1 perna manca: anda, mas não é ainda a coisa
completa — nem perto do resto do SUPER-X (mais de 40 outros comandos no inventário, ver `docs/SPEC.md`
módulo 45, ainda intocados).

### Novidades

- **`XD`** — porta o `D` do SUPER-X (hex dump editável). Um endereço abre uma grade interativa 16×8
  hexa+ASCII (bloco ASCII também editável, tecla `"` pra digitar direto, `@` repete o byte anterior);
  dois ou três campos (`<inic>[,<fim>[,<arquivo>]]`) despejam texto no log ou gravam os bytes crus num
  arquivo binário (reaproveita o diálogo do `SAVE` já existente).
- **`XA`** — porta o `A` do SUPER-X (listagem/edição ASCII). Tela dedicada nova, 16×16 = 256 bytes por
  tela, só texto (sem coluna hexa) — qualquer caractere digitado escreve direto na memória e avança.
  Mesma sintaxe de dois/três campos do `XD`.
- **`XI`** — porta o `I` do SUPER-X (disassembly). Um endereço abre uma tela de VISUALIZAÇÃO (sem edição
  nem a pilha de navegação jump/call que o original tem — decisão deliberada, fica pra depois); dois/três
  campos despejam a listagem no log ou gravam a listagem de TEXTO num arquivo (diferente do `XD`/`XA`,
  que salvam bytes crus).
- **`XM`** — porta o `M` do SUPER-X (entrada assembler interativa: monta e grava linha a linha direto na
  memória, ou aceita campos de dado crus).
- **Endereçamento estendido** — qualquer um dos quatro aceita `<endereço>#<slot>[-<subslot>]` pra mirar
  um slot/sub-slot físico específico direto (até 1MB via slots expandidos), `#V`/`#4` pra VRAM e `#S`/`#5`
  pro slot de boot — sem precisar trocar o `PAGE` corrente primeiro.
- **`<fim>` opcional, default de 256 bytes** — `XD`/`XA`/`XI` aceitam `<inic>,<arquivo>` direto (sem
  precisar digitar o endereço final) quando o intervalo desejado é só os 256 bytes a partir do início.
- **Prefixo `?`** — na frente de `XD`/`XA`/`XI` manda a listagem pra um PDF em vez do log ("impressora"
  do SUPER-X original).
- **7 variáveis de debugger** (`@0`-`@3` + `@B`/`@E`/`@S`) — `@nome=endereço[#slot]` grava, `@` sozinho
  lista todas, `@nome` substitui um endereço completo em qualquer um dos quatro comandos.
- **Notas do `SUPER-X.TNK` traduzidas pro Ajuda** — as 471 notas originais (BIOS/work area/hooks, em
  japonês no arquivo original) viraram 11 tópicos de Ajuda em português, seção "SUPER-X - Notas". O
  carregador nativo do formato binário já existe; os comandos `MON>` que os usariam (`iM`/`iC`/`iL`/`iS`)
  ainda não.

### Correções

- **Sufixo de sub-slot aceitava `"3-"` (hífen sem dígito depois) como válido** — `Mamute_ParseSxSlotSuffix`
  não verificava se sobrava algo depois do hífen antes de aceitar.
- **Endereço-salto do `XM` sobrescrevia o alvo ativo mesmo sem sufixo `#`** — contradizia a regra
  documentada do próprio SUPER-X ("se o slot for omitido, assume o corrente").
- **`DAA`/`CCF` confundidos com endereço hexa no `XM`** — são os dois únicos mnemônicos Z80 de zero
  operandos cujo nome também é um hexadecimal válido; corrigido checando `Z80Asm::IsMnemonic()` antes de
  tentar interpretar o token como salto.

### Bastidores

- **O motor de disassembly (`L`/`LP`, desde o módulo 31) nunca honrava slot/VRAM explícito** — em vez de
  duplicar as tabelas de opcode Z80 (código historicamente delicado) pra um "XI-aware" separado, toda a
  cadeia de decodificação ganhou um parâmetro OPCIONAL (`*T.MamuteSxTarget = 0`) — os 7 call sites
  pré-existentes (inclusive o passo a passo da CPU ao vivo, `MamuteZ80Cpu.pbi`) continuam chamando sem
  esse parâmetro, comportamento idêntico a antes; confirmado ao vivo comparando `L 4000,4010` contra
  `XI 4000,4010`, byte a byte idênticos.
- **Escopo dos comandos-ponte confirmado por pergunta direta antes de codar, três vezes nesta sessão**:
  se a grade do `XD` seria reaproveitada pro `XA` (não — tela nova), se o `XI` sozinho abriria uma janela
  editável tipo `XD` (não — só visualização) e o que o terceiro campo do `XI` deveria salvar (listagem de
  texto, não bytes crus) — todas as três decisões documentadas em `docs/SPEC.md`, módulos 45h/45i.
- **Uma lacuna de verificação registrada, não escondida**: a digitação de caractere na grade do `XA`
  não pôde ser testada ao vivo neste ambiente de automação (três técnicas de injeção de teclado
  sintético falharam, incluindo `SendInput` de hardware devolvendo 0 eventos — cliques de mouse
  continuaram funcionando normalmente). O mecanismo é cópia literal do bloco ASCII do `XD`, já provado
  ao vivo antes — mas fica anotado como pendência de verificação, não como certeza.
- Verificado ao vivo em cada comando novo (compilação limpa a cada passo, `.exe` real, `WM_COMMAND`/
  `WM_SETTEXT`/`BM_CLICK`/`WM_LBUTTONDOWN` em HWNDs específicos, screenshots) — inclusive as 5 pontes de
  navegação da cruz de modos nos dois sentidos, o diálogo real de `SAVE`/PDF abrindo e sendo cancelado
  sem gravar, e os arquivos de teste apagados ao final de cada rodada. Detalhamento completo (todo achado,
  toda decisão, toda verificação) em `docs/SPEC.md`, módulos 45-45i.

---

## 8.4.0 — "PORTA DUPLA" (2026-08-21)

**Tema da versão**: duas peças novas para o sistema de projeto, as duas nascidas do mesmo pedido do
usuário — quem digita type-ins de revista/livro quer empacotar, num único `.msxproject`, os programas,
os artigos explicando como usá-los e os discos prontos, e precisa achar tudo isso de novo sem decorar
nome de arquivo. Nome escolhido pelas duas "portas" que a versão abre: a porta de verdade do Windows
(duplo clique num `.msxproject` já abre ele no Paleobasic) e a porta pro conteúdo do próprio projeto
(o índice cataloga tudo o que tem lá dentro, um clique abre o item certo).

### Novidades

- **Associação de arquivo `.msxproject`** (`Configurar → Associações de arquivo...`) — liga/desliga a
  associação de `.msxproject` com o Paleobasic no Windows (`HKEY_CURRENT_USER\Software\Classes`, sem
  precisar de administrador). Marcada, dar 2 cliques num `.msxproject` no Explorer abre esse projeto
  direto na IDE. Desmarcar só remove a associação se ela ainda apontar pra esta cópia do Paleobasic —
  nunca mexe numa associação de outro programa.
- **Índice de recursos do projeto** (`Projeto → Índice de recursos...`, `Ctrl+Alt+R`) — catálogo, numa
  lista só, de tudo que o `.msxproject` atual guarda: documentos (por tipo — Basic Dignified/MSX-BASIC/
  Assembly/Markdown), todo recurso numerado (sprites, alfabetos, sons, SFX, músicas, telas, Graphos III,
  Assembly Sub-Projects) e qualquer `.dsk` ao lado do projeto. Dois cliques leva pro lugar certo:
  documento troca de aba, disco abre o Gerenciador de disco já com o arquivo escolhido, qualquer outro
  recurso abre o editor daquele tipo.
- **Menu de topo `Projeto` novo** — reúne o que estava espalhado entre `Arquivo` (Novo/Abrir/Salvar
  projeto/Salvar projeto como...) e `Configurar` (Projeto..., renomeado "Configurações do projeto..."),
  mais o Índice de recursos novo.

### Bastidores

- **Achado de segurança que mudou o desenho do índice**: a primeira versão ia mostrar a Tag de cada
  recurso numerado, chamando `ProjectDB::Fetch*()`. Essas funções escrevem direto no `Array` parâmetro
  do tamanho REAL do recurso (grade do sprite, número de passos do som, etc.) sem nenhum `ReDim`
  interno — um array pré-dimensionado pequeno demais estoura o limite, mesma família de bug já
  documentada neste projeto (`CopyMap()` em mapa vazio). Decisão: a lista mostra só tipo + número desses
  recursos, sem arriscar um `Fetch` de payload pesado só pra exibir um nome.
- `RegCreateKeyExW`/`RegSetValueExW`/`RegOpenKeyExW`/`RegQueryValueExW`/`RegCloseKey`/`RegDeleteTreeW`
  (Advapi32.lib) e `SHChangeNotify` (Shell32.lib) não vêm disponíveis nem como WinAPI cru nem pela lib
  Registry do PureBasic nesta instalação do compilador — confirmado tentando as duas formas antes de
  escrever um `Import` manual (mesmo idioma já usado no dark mode, incluindo a decoração de nome pra
  builds x86).
- Verificado ao vivo em cada etapa (compilação limpa, `.exe` real, `WM_COMMAND`/`BM_CLICK` num HWND
  específico, screenshot, registro do Windows conferido por fora com PowerShell, um `.md` salvo de
  verdade reaparecendo no índice) — com uma exceção documentada: o clique duplo dentro do
  `ListIconGadget` do índice não foi testado por automação de mensagem (exigiria `LVM_SETITEMSTATE`,
  classe de mensagem que este projeto evita por risco de travar o processo alvo) nem por clique real de
  mouse na máquina do usuário; ficou verificado por revisão de código, reusando a mesma lógica já
  testada de "Abrir arquivo". Detalhamento completo em `docs/SPEC.md`, módulos 43/44.

---

## 8.3.0 — "TECLA FANTASMA" (2026-08-20)

**Tema da versão**: melhor integração do console do openMSX (`Executar → openMSX...`) com o fluxo de
editor/montador, motivada por um incômodo relatado ao vivo (a resposta de FPS poluindo os logs de
comando) e um pedido de teclas especiais na aba "Input Text" — que junto acabaram revelando dois bugs
reais e silenciosos, um deles vivo desde que os botões de estado dinâmico foram criados: o rótulo de 9
botões (Power incluso) nunca de fato atualizava na tela, e o botão STOP pressionava TAB. Nome escolhido
por isso — o rótulo "fantasma" que nunca mudava de "Power: ?" por baixo do capô, e as teclas "fantasmas"
que a nova aba Input Text agora sabe pressionar sem precisar de um teclado de verdade.

### Novidades

- **Display de FPS + atalho de Power na barra inferior** (sempre visível, qualquer aba): um "quadro"
  estilo mini-display digital (fundo escuro, texto verde) logo depois do botão "Reiniciar openMSX",
  atualizado ao vivo, e um botão Power ao lado — mesmo comando de sempre, sem precisar trocar pra aba
  "Outros comandos".
- **Teclas especiais na aba "Input Text"** — tags `⟦NOME⟧` (colchetes Unicode reservados, nunca
  confundidos com `[ESC]` ASCII literal dentro de um `PRINT` de verdade) viram um toque de tecla real
  (ESC, F1-F5, TAB, setas, GRAPH, CODE, SELECT, STOP, etc.) em vez de texto digitado — uma paleta de 23
  botões insere a tag no cursor, sem precisar digitar ⟦ ⟧ à mão. Verificado ao vivo contra a tela real
  do MSX.
- **Combos de tecla** (`⟦SHIFT+F1⟧`, por exemplo) — pressiona todas as teclas do combo primeiro, espera
  um instante, só depois solta todas (ao contrário da tag simples, que aperta E solta uma de cada vez).
  "Modo Combo" na paleta acumula os cliques num combo até "Inserir" escrever a tag combinada de uma vez
  só.
- **FPS parou de poluir os logs** — tanto o da aba "Console" quanto o da aba "Status Info": a resposta
  crua de `openmsx_info fps` (um número solto por segundo) tinha virador o próprio motivo do pedido
  desta versão, e agora fica de fora dos dois, já que o display dedicado acima cobre essa informação.

### Correções

- **`SetGadgetText()` não fazia NADA em nenhum botão temático da IDE** (`ThemedButton`, imagem
  desenhada na criação em vez de texto de verdade) — afetava silenciosamente 9 botões de estado
  dinâmico do console do openMSX (Power/Pause/Firmware/Ren Sha Turbo/VSync/Deinterlace/Limitar
  sprites/Tela cheia/Desabilitar sprites) desde que foram criados: o comando sempre era enviado certo,
  só o rótulo de volta nunca refletia a mudança na tela.
- **Botão STOP pressionava TAB** — a máscara usada (`0x08` na linha 7 da matriz de teclado) citava uma
  "confirmação" de sessão anterior contra um script real do openMSX que na verdade não existe nos
  scripts vendorizados. Corrigido pra `0x10` (o valor certo), cruzado desta vez contra duas fontes
  independentes que batem 100% entre si.

### Bastidores

- Verificado ao vivo em cada etapa (compilação limpa + screenshot real da janela rodando): display de
  FPS atualizando, botão de Power refletindo o estado corretamente pela primeira vez, paleta de teclas
  especiais renderizando e quebrando linha automaticamente, tag `⟦ESC⟧` resetando de verdade um prompt
  real do MSX sem afetar o texto `[ESC]` literal ao lado, combo `⟦SHIFT+F1⟧` montado e enviado sem
  travar o processo.
- Achado sobre a própria metodologia de verificação: automação de GUI por clique real de mouse
  (coordenadas absolutas de tela) é arriscada — um clique acabou atingindo a janela errada quando a
  janela de teste mudou de posição sem isso ser percebido a tempo. Reforça preferir sempre mensagens
  direcionadas (`BM_CLICK`/`WM_COMMAND` a um HWND específico) em vez de simulação de entrada real.
  Detalhamento completo em `docs/SPEC.md`, módulo 37.

---

## 8.2.0 — "ESQUELETO NOVO" (2026-08-19)

**Tema da versão**: o projeto inteiro trocou de esqueleto — `src/`, `dist/`, `resource/`, `docs/`,
`others/` no lugar de `editor/`/`fossauro/`/uma dúzia de pastas soltas na raiz — sem trocar de espécie:
a experiência de uso não muda (o `.exe` continua sendo o mesmo Paleobasic), mas por baixo praticamente
todo caminho relativo do programa foi reescrito e testado de novo. Release pra **teste**, não pra uso
despreocupado ainda: é a mudança de infraestrutura mais ampla que este projeto já passou de uma vez só.

### Reorganização de diretórios

- **`src/`** — todo código-fonte compilado. `src/editor/` dividido por função lógica (`core/`,
  `assemblers/`, `basic/`, `emulators/`, `visual_editors/`, `help/`, `tools/`); `src/fossauro/` movido
  inteiro. As 94 linhas `XIncludeFile` do `BadigEditor.pb` reescritas com o prefixo de subpasta
  correto - confirmado por teste empírico, antes de mexer em qualquer coisa, que `XIncludeFile`
  resolve caminho relativo ao arquivo que o contém, não ao arquivo raiz.
- **`dist/`** — tudo que o programa precisa pra rodar. **Os dois executáveis (`PaleoBasic.exe`,
  `fossauro.exe`) ficam na raiz**, cada um buscando help/config/recursos na subpasta com seu nome
  (`dist/editor/`, `dist/fossauro/`). `dist/roms/` guarda as ROMs de sistema do Fossauro (fonte
  canônica em `resource/roms/`, nunca versionada - direitos autorais). `dist/projects/` recebe o
  projeto padrão implícito (antes vivia na pasta temp do Windows, se perdia em qualquer limpeza ou
  troca de máquina - agora é permanente, ao lado do executável). `dist/sample/`, `dist/res/`
  continuam versionados junto.
- **`resource/`** — recursos não-compilados que o projeto possui (fontes, imagens de ajuda,
  ferramentas externas empacotadas) e cópias vendorizadas de referência (openMSX, Graphos, Aquarela,
  Nestor, etc.) - confirmado por grep que nenhuma é lida por código compilado, só citadas como
  referência.
- **`docs/`** — documentação consolidada, incluindo a do Fossauro que estava solta.
- **`others/`** — diretórios sem nenhuma referência no código (`prj/`, `support/`, `msxword/`,
  `superx/`, `filehunter/`) e dois achados reais inesperados: um binário Linux e ROMs duplicadas
  comitadas por engano dentro do antigo `editor/`. Candidatos a remoção futura, não apagados agora.

### Correções

- **`Configurar → Basic Dignified... → Emulador` / `Configurar → openMSX...`**: ordem dos campos
  corrigida (executável primeiro - antes um campo sem relação nenhuma com ele pedia "informe o
  executável primeiro"), `-setting` corrigido (existia na tela mas nunca virava flag de verdade),
  `-script` novo, e a extensão única virou **4 slots reais e independentes** (`-exta`/`-extb`/`-extc`/
  `-extd`, confirmado no código-fonte real do openMSX) com rótulo corrigido (não é só disco).
- **Comando `FOSSAURO` do Mamute Assembler**: não usa mais `RUN` cru (sequestrava `PC`/`SP` de uma
  sessão MSX já viva) - agora digita `DEFUSR0=&Hxxxx` na sessão via o buffer de teclado real do MSX,
  o mesmo mecanismo seguro usado pelo openMSX de verdade. Sintaxe corrigida (`DEFUSR0`/`USR0(0)`, não
  `DEFUSR(0)`/`USR(0)`) e nova flag opcional pra executar automaticamente após transferir.
- **Comando `OPENMSX` novo no Mamute Assembler** - mesmo fluxo do `FOSSAURO`, mirando uma instância
  real de openMSX via o bridge Tcl/XML já existente, em vez do protocolo próprio do Fossauro.

### Bastidores

- `build.ps1 -D`/`build.sh -D` agora são realmente idempotentes (bug real encontrado nesta sessão:
  rodar `-D` duas vezes aninhava pastas, `dist/editor/fonts/fonts/...`, em vez de sobrescrever).
- Verificado ao vivo em cada etapa: compilação limpa dos dois executáveis a partir da nova estrutura,
  `fossauro.exe` bootando com sucesso a partir de `dist/` (ROMs carregadas de `dist/roms/`),
  `PaleoBasic.exe` com ícone/fontes/menus renderizando normalmente, projeto padrão criado no lugar
  certo. Detalhamento completo em `docs/SPEC.md`, módulos 33 a 36.

---

## 8.1.7 — "PILHA EMPRESTADA" (2026-08-19)

**Tema da versão**: release menor, focada num único bug corrigido — o travamento do `RUN` do Fossauro
ao chamar rotinas de BIOS de verdade (`CHPUT`), reportado na sessão anterior (8.1.6) e diagnosticado
mas deixado em aberto de propósito. Nome escolhido porque a causa raiz era exatamente essa: o código
injetado nunca tinha seu próprio endereço de retorno, e acabava "emprestando" — sem pedir — a pilha da
sessão MSX que já estava rodando quando o comando chegava.

### Correções

- **`RUN <addr>` do protocolo de controle remoto do Fossauro (`\\.\pipe\fossauro`) travava de forma
  imprevisível ao chamar rotinas de BIOS de verdade**: a causa raiz não era um laço preso dentro do BIOS
  (a suspeita do módulo 32w) — era corrupção de pilha. `RUN` só trocava `PC`, nunca `SP`; quando o
  código injetado dava `RET` (direto, ou indiretamente via alguma chamada de BIOS mal-balanceada), o
  `POP` correspondente lia o topo da pilha da sessão MSX original que estava viva e em andamento no
  instante em que o `RUN` chegou, e a execução "ressurgia" dentro daquele call-chain alheio de forma
  imprevisível — confirmado reproduzindo o mesmo programa de teste duas vezes, em momentos de boot
  diferentes, e vendo o travamento em duas regiões de `PC` completamente sem relação entre si (a
  assinatura clássica desse tipo de bug, não de um laço determinístico). Fix: `RUN` agora empurra um
  endereço de retorno sintético — apontando pra um trap de 2 bytes (`JR $`, loop infinito inofensivo e
  detectável via `REGS`) — numa folga de 1024 bytes abaixo do `SP` herdado, antes de saltar. Qualquer
  `RET` cai nesse loop conhecido em vez de invadir código alheio. Verificado ao vivo: o mesmo programa
  de teste do módulo 32w (impressão de texto via `CHPUT`) agora completa a impressão inteira e para de
  forma estável e detectável; o teste original sem BIOS (módulo 32v) continua passando sem regressão.
  Ver `docs/SPEC.md` módulo 32x para o diagnóstico completo.

---

## 8.1.6 — "FÓSSIL NÃO CRESCE, MAS APRENDEU A SE EXPLICAR" (2026-08-18)

**Tema da versão**: o Fossauro se integra de vez ao Paleobasic (Executar/Configurar/Ajuda, tudo num só
menu) e ganha um menu de Vídeo de verdade — só que a escala 1:1 é a única que sai da caixa sem travar a
máquina, um bug real e reprodutível ainda não isolado. Nome escolhido pra render homenagem ao tema
paleontológico do projeto e à mesma honestidade das notas anteriores: o fóssil não cresce de tamanho,
mas pelo menos agora tem uma ajuda própria pra se consultar.

### Novidades

- **Integração completa Executar/Configurar/Ajuda → Fossauro**: o Paleobasic agora abre, configura e
  documenta o Fossauro sem sair do editor principal — `Executar → Fossauro` (F10) lança o emulador com
  as configurações salvas, `Configurar → Fossauro...` edita máquina/memória/caminho num diálogo dedicado
  (padrão `AsmsxSupport.pbi`: JSON ao lado do `.exe`, botões temáticos, Salvar/Cancelar), e
  `Ajuda → Fossauro...` abre uma referência estática (status atual, integração, teclado/linha de
  comando) reaproveitando o mesmo visualizador markdown do N80/MSXBas2Rom.
- **Menu Vídeo no Fossauro**: `Vídeo → Escala → 1:1/2:1/3:1/4:1` e `Forçar proporção de tela 4:3`, mais
  as flags de linha de comando equivalentes (`-vscale <1-4>`, `-4x3`). Só **1:1** e o **4:3** aplicam de
  verdade hoje — **2:1/3:1/4:1 mostram um aviso em vez de travar**: qualquer janela/canvas maior que
  512x384 trava o processo de forma 100% reproduzível nesta máquina, independente da técnica usada
  (redimensionar, recriar gadget, recriar janela inteira, até relançar o processo do zero) — causa raiz
  não isolada apesar de investigação extensa. Decisão consciente: travar nunca, mesmo que isso signifique
  entregar menos escala do que o planejado. Ver `docs/SPEC.md` módulo 32s para a investigação completa.
- Corrigido de quebra, achado durante essa mesma investigação: uma bandeira interna (`FramePending`)
  ficava presa em 1 se a janela fosse fechada com um frame pendente, parando o rendering pra sempre sem
  travar nem dar erro — silencioso o bastante pra passar despercebido até agora.

### Bastidores

- A ajuda nova do Fossauro (`fossauro/help/*.md`) tem um bug cosmético conhecido e não bloqueante:
  `**negrito**`, `` `código` `` e `## H2` aparecem com a sintaxe markdown literal em vez de formatados —
  só o título `# H1` renderiza certo. BOM UTF-8 testado como hipótese, não resolveu; causa raiz não
  isolada por falta de tempo nesta sessão. Conteúdo continua legível. Ver `docs/SPEC.md` módulo 32t.
- Metodologia: `WM_KEYDOWN`/`WM_KEYUP` injetados via `SendMessage`/`PostMessage` **não** disparam
  atalhos de teclado do PureBasic (`AddKeyboardShortcut()` depende do `TranslateAccelerator()` real do
  loop de mensagens) — `WM_COMMAND` com o ID numérico do menu (contado pela posição no bloco
  `Enumeration MenuItems`) é o jeito confiável de testar isso automatizado.

---

## 8.1.5 — "SOM E TELA DE VERDADE, DISCO QUE NÃO GIRA" (2026-08-18)

**Tema da versão**: o Fossauro ganha áudio e vídeo completos (PSG verificado tocando de ponta a ponta,
SCREEN 6/7 renderizando) na mesma sessão em que a tentativa de disco (FDC) esbarra numa regressão real de
boot ainda não resolvida — nome escolhido pra refletir os dois lados exatamente como aconteceram, não só
as vitórias.

### Novidades

- **Áudio do PSG (AY-3-8910) verificado de ponta a ponta**: `StartAudio()`/`StopAudio()` já estavam
  cabeados, mas nunca confirmados rodando de verdade. Novo harness `audio_verify.pb` renderiza um `.wav`
  real através do `PSG_Render()` de produção (tom/varredura/ruído/envelope/acorde) e testa a thread
  `waveOut` ao vivo — frequência medida bateu quase exata com a fórmula teórica.
- **SCREEN 6/7 (Graphic 5/6) implementadas** em `RefreshLine()` (`V9938.pbi`) — os dois únicos modos de
  vídeo do MSX2 que ainda caíam num fundo em branco. Verificado com um novo harness que renderiza barras
  de cor + um sprite direto pra `.bmp`. De quebra, achado e corrigido um bug real pré-existente:
  `FillMemory()` sem o parâmetro de tipo `#PB_Long` só preenchia o byte baixo da cor (invisível até agora
  porque preto tem todos os bytes iguais) — afetava toda borda/fundo não-cinza em 5 pontos do código.
- **FDC (WD1793) implementado e verificado isoladamente, mas NÃO conectado ao boot ainda**: mecanismo
  completo (RESTORE/SEEK/READ/WRITE SECTOR/etc.), porta mapeada por engenharia reversa do `DISK.ROM` real
  (sem o C fonte do fMSX nesta máquina), 4/4 testes passando byte-a-byte contra um `.dsk` real. Ligar o
  `DISK.ROM` de verdade no mapa de memória trava o boot do MSX2/2+ — causa raiz ainda não isolada, a
  chamada fica desativada por enquanto. Ver `docs/SPEC.md` módulos 32n-32p.

### Bastidores

- Achado e corrigido, gerando este mesmo pacote de distribuição: bug real no toolchain do
  `pbcompiler.exe` x86 desta máquina — `Import ... As "GetProcAddress"` sem decoração stdcall
  (`_GetProcAddress@8`) quebrava o link só em builds x86, nunca em x64. Ver `docs/SPEC.md` módulo 32q e
  `CLAUDE.md`.
- Metodologia decisiva de novo: harnesses de console que exercitam a função real de produção (não uma
  reimplementação) e, quando pixels/áudio importam, gravar um artefato inspecionável (`.bmp`/`.wav`) em
  vez de confiar só em texto de log.

---

## 8.1.3 — "MSX2 DE VERDADE" (2026-08-18)

**Tema da versão**: o Fossauro sai do "esqueleto que só boota MSX1/MSX2+" pra emulador MSX de verdade —
causa raiz do freeze de boot do MSX2 puro finalmente encontrada e corrigida (os três modelos bootam de
ponta a ponta agora), mais tamanho de RAM/VRAM configurável e suporte a mappers MegaROM em cartucho, tudo
portado fielmente do fonte C real do fMSX.

### Novidades

- **MSX2 puro agora boota completamente** ("MSX BASIC version 2.1"), depois de duas sessões anteriores
  sem conseguir isolar a causa. Achado: um comando de VDP LMMC (desenho do logo de boot) alimentado com
  127 de 128 bytes esperados — correto pelo protocolo real do V9938 (hardware consome o primeiro pixel
  imediatamente ao iniciar o comando), mas o `fossauro` exigia os 128 completos e nunca limpava o flag CE,
  travando toda espera de "VDP pronto" depois disso. Ver `docs/SPEC.md` módulo 32j.
- **Hardware → RAM Size** (64/128/256/512/1024KB) e **Hardware → VRAM Size** (16/32/64/128/192KB): mapeador
  de RAM por bancos (portas `$FC`-`$FF`) portado fielmente do `MSX.c` real, usado em todo modelo (o fMSX
  real não modela expansão de RAM do MSX1 como cartuchos separados, mesmo sendo a prática mais comum em
  hardware real da época). VRAM segue o mesmo padrão, com uma divergência proposital: MSX1 aceita 16KB de
  verdade (o fMSX real exige mínimo 32KB) — tamanho comum em hardware MSX1 real, escolha explícita do
  usuário. `-ram`/`-vram` na CLI finalmente ligados. Ver módulos 32k/32l/32m.
- **Hardware → Cartridge Slot A/B** com suporte a mappers MegaROM: Guess/Generic 8KB/Generic 16KB/Konami
  5000h(SCC)/Konami 4000h/ASCII 8KB/ASCII 16KB/GameMaster2/FMPAC, com RAM battery-backed (SRAM, só-sessão)
  pros que precisam. Corrigido de quebra um bug real onde o Slot A espelhava nos dois slots primários e
  roubava o Slot B se carregado depois. Ver módulo 32l.
- **Padrão de inicialização mudou pra MSX1, 64KB RAM, 16KB VRAM** (escolha explícita do usuário) — antes
  era MSX2/128KB/128KB. Ver módulo 32m.

### Bastidores

- Metodologia decisiva pro achado do MSX2: trace de instrução real (não desmontagem manual) numa faixa de
  endereço/frame exata, mais comparação linha-a-linha contra `fMSX/fMSX/V9938.c`/`MSX.c` reais quando o
  modelo simplificado do `fossauro` divergia do que hardware real faz - mais rápido que adivinhar a partir
  dos sintomas.
- Formato de snapshot `.fss` passou de v1 pra v3 (RAM de tamanho variável em v2, VRAM em v3) - snapshots
  salvos antes desta versão não carregam mais (checagem de versão já existente recusa educadamente).
- Achado durante o teste de MegaROM (não-relacionado, não é regressão): reproduzido um bug **já
  documentado** de sessão anterior (estouro de pilha do hook H.TIMI) com um cartucho simples que não passa
  por nenhum código novo desta versão - confirmado que não tem relação com o trabalho de hoje.

---

## 8.0.1 — "OVO DE FOSSAURO" (2026-08-15)

**Tema da versão**: navegação por cursor no debugger visual Z80, e o port nativo em PureBasic do fMSX
deixa de ser um acidente de sessão pra virar projeto irmão oficial dentro do repositório — apelido
**🦴 Fossauro**, renomeado de `bafmsx/` pra `fossauro/` (rename de verdade, não só cosmético), primeiro
salto de versão maior (`7.x` → `8.0`) desde o início do projeto.

### Novidades

- **Minimapa de memória no debugger** (`editor/MamuteDebuggerGui.pbi`): grade 16×16 de blocos de 256
  bytes cobrindo os 64KB inteiros, cor de base por página (RAM/ROM/BASIC/vazio) com brilho escalando pela
  fração de bytes não-zero no bloco, marcadores de `PC`/`SP`/breakpoints/bloco selecionado. Clique navega
  o minimonitor direto pro bloco escolhido — os dois painéis viraram uma coisa só de navegação.
- **Cursor de linha independente do PC**: setas Cima/Baixo movem um cursor próprio pelo disassembly
  (contorno branco, distinto da barra verde do `PC`); ao chegar no topo ou rodapé da janela visível, ela
  rola automaticamente pra acompanhar. Clique numa linha também move o cursor pra lá.
- **"Ir p/ endereço (G)"**: botão + atalho, abre uma caixa pra digitar um endereço em hexa e pula o
  disassembly (e o cursor) direto pra lá.
- **"PC = cursor (H)"**: botão + atalho, grava o endereço do cursor de volta no `PC` simulado —
  equivalente ao "Set Next Statement" de debuggers convencionais, só reposiciona de onde o próximo
  `Step`/`Run` vai partir, não executa nada sozinho.
- **`fossauro/` ("🦴 Fossauro", ex-`bafmsx/`) vira projeto irmão oficial**: port nativo em PureBasic do
  fMSX (núcleo Z80 e memória/slots/PPI/teclado já prontos; VDP V9938 e PSG AY-3-8910 ainda só esqueleto).
  O **fonte** do port (`.pbi`/`.pb`/`.md`/`LICENSE`/`build.ps1`/`translate.py`) passa a ser rastreado
  normalmente no git, decisão explícita do usuário.

### Bastidores

- Navegação por cursor verificada ao vivo, não só por leitura de código: automação via UI Automation +
  `SendKeys` + `PrintWindow` confirmou 20× `Down` rolando a janela mantendo o cursor colado no rodapé,
  25× `Up` rolando de volta, `G` pulando de `4000` pra `5000` de verdade, e `H` gravando `PC = 4008`
  depois de mover o cursor com as setas.
- **Achado e corrigido nesta sessão**: `bafmsx/` (nome do diretório antes do rename pra `fossauro/`, ver
  acima) tinha sido commitado por engano numa sessão anterior (`7.33.44`) com a cópia vendorizada inteira
  do fMSX original em C (`fMSX/`, dentro do diretório) e ROMs de BIOS do MSX com copyright próprio — nada
  disso deveria ter ido pro git. Corrigido sem apagar nada do disco: `git rm --cached` nesses arquivos
  (mais artefatos de build/teste, `.exe`/`debug.log`) e três regras novas no `.gitignore` (já apontando
  pro caminho novo, `fossauro/...`), mesma política já aplicada a `badig/`/`nestor80/`/`asmsx/`/etc. —
  material de referência de terceiros nunca entra no repositório, só o trabalho original deste projeto.
- **Pendência registrada no `docs/SPEC.md`** (módulo 32b, novo): integração futura entre o PaleoBasic e o
  Fossauro — canal de comunicação (mesmo espírito do pipe já existente com o openMSX real via
  `OpenMSXBridge.pbi`) e as funções que ainda faltam no Fossauro (V9938/PSG/carregamento de fita-disco)
  antes de uma integração de verdade fazer sentido. Duas arquiteturas possíveis registradas como estudo,
  nenhuma escolhida ainda (fora do processo via pipe, ou linkada direto no `PaleoBasic.exe` — esta
  segunda esbarra na licença não-comercial herdada do fMSX original, incompatível com a GPLv3 deste
  projeto do jeito que está hoje, decisão que precisa ser consciente do usuário antes de acontecer).

### Empacotamento deste lançamento

- Pacote de distribuição gerado via `build.ps1 -D` (pasta `distribute\`) e publicado como
  `paleobasic-v080001.zip`, substituindo `paleobasic-v073344.zip`.

---

## 7.33.44 — "KONPASSO" (2026-08-14)

**Tema da versão**: o comando `G` do Mamute Assembler finalmente executa código de verdade — debugger
visual Z80 completo (Fase 1 do módulo 32 do `docs/SPEC.md`: simulador Z80 puro, sem VDP/PSG/FDC/BIOS).

### Novidades

- **`G <endinic>[,<bp1>[,<bp2>]]`** abre uma janela de debugger visual — disassembly, registradores/
  flags, minimonitor de memória, pilha, mapa de páginas/slots e controles de execução — em vez de só
  validar a sintaxe e avisar "ainda não implementada".
- **Núcleo de execução Z80 nativo, tabela completa** (`editor/MamuteZ80Cpu.pbi`): as 256 instruções
  base, as 256 `CB`, a tabela `ED` documentada (blocos `LDI`/`LDD`/`LDIR`/`LDDR`/`CPI`/`CPD`/`CPIR`/
  `CPDR`/`INI`/`IND`/`INIR`/`INDR`/`OUTI`/`OUTD`/`OTIR`/`OTDR`, `ADC`/`SBC HL,rr`, `RRD`/`RLD`, `LD I,A`/
  `LD A,I`/`LD R,A`/`LD A,R`, `NEG`, `RETN`/`RETI`, `IM 0/1/2`) e `DD`/`FD`/`DDCB`/`FDCB` (`IX`/`IY`,
  incluindo os indocumentados `IXH`/`IXL`/`IYH`/`IYL` e a regra real de que `EX DE,HL` nunca é afetado
  pelo prefixo).
- **Registradores ampliados**: `PC`, par alternado `AF'`/`BC'`/`DE'`/`HL'`, `I`/`R`/`IFF1`/`IFF2`/`IM`
  — a `Structure MamuteGui_State` que já servia o comando `X` ganhou os campos que faltavam, todos
  editáveis direto na janela do debugger.
- **Controles de execução**: `Step Into`, `Step Over` (detecta `CALL`/`RST` e roda até o endereço de
  retorno), `Step Out` (roda até o `SP` desempilhar acima do valor de entrada), `Run` (até um dos 2
  breakpoints ou `HALT`) — todos com um teto de segurança contra loop infinito.
- **Layout inspirado no Konpass** (Nestor Soriano/Konamiman): disassembly acompanhando o `PC` por
  padrão (ou rolagem independente via checkbox "Seguir PC" + `^`/`v`), minimonitor hex+ASCII editável
  (mesma técnica de grade do comando `DM`), pilha editável, `PAGE`→`SLOT`→`TIPO` (sem linha `MAPPER` —
  o modelo de memória do Mamute não tem conceito de sub-slot/segmento).

### Bastidores

- Verificado com um harness de regressão novo, **`editor/tools/MamuteZ80CpuTestCli.pb`** (autocontido —
  duplica só a `Structure`/uma memória plana mínima em vez de arrastar a GUI inteira do Mamute pra
  dentro de um `/CONSOLE`): **60 verificações**, cobrindo ALU/flags (incluindo overflow de `ADD`/`SUB` e
  correção BCD do `DAA`), `LD`/`PUSH`/`POP`/`CALL`/`RET`, `Step Over` sobre um `CALL` real, `IX`+`DDCB`
  (`SET`/`BIT` indexado, com cópia pro registrador quando aplicável) e o bloco `LDIR` reexecutando a
  mesma instrução passo a passo até `BC=0` — todas passando.
- Simplificações conscientes desta primeira leva, documentadas no topo de `MamuteZ80Cpu.pbi` (não são
  bugs): F3/F5 de `BIT n,(HL)/(IX+d)/(IY+d)` usam o byte lido em vez do registrador interno `WZ`/MEMPTR
  real do hardware; a combinação não-documentada `DD`+`ED`/`FD`+`ED` trata o prefixo anterior como
  desperdiçado (mesmo comportamento real do Z80); flags de `INI`/`IND`/`OUTI`/`OUTD`/variantes `R` são
  aproximadas; sem cronometragem em T-states (não necessário pra um debugger passo-a-passo).
- Motor portado de forma independente a partir do conhecimento público da arquitetura Z80 — **não** do
  código-fonte do `bafmsx`/fMSX (mesma política já registrada no módulo 32 do SPEC: fatos de engenharia
  de opcode, não cópia de código; o fMSX tem licença não-comercial incompatível com a GPL v3 deste
  projeto).
- Rodada de polimento: janela (`1180×820`) e botões (`165×38`) maiores — os nomes dos botões estavam
  sendo cortados; disassembly ganhou rolagem independente; pilha passou a ser editável por clique (igual
  ao minimonitor); os 3 painéis desenhados à mão (disassembly/minimonitor/pilha) ganharam borda,
  aproximando do visual "boxed panel" do Konpass.

### Empacotamento deste lançamento

- Pacote de distribuição gerado via `build.ps1 -D -V "7.33.44"` (pasta `distribute\`) e publicado como
  `paleobasic-v073344.zip`.

---

## 7.33.43 — "OFFSET DE ORG" (2026-08-13)

**Tema da versão**: última opção da série do comando `A` — `/<offset>`, que desloca o `ORG` de toda a
montagem em tempo de compilação, sem editar o fonte.

### Novidades

- **`A O/<offset>`** monta o programa como se todo `ORG` tivesse `<offset>` (hexa) somado ao valor
  original — ex. `A O/8000` com `ORG 0C100H` monta em `0C100H+8000H`. O programa inteiro acompanha o
  deslocamento (rótulos, saltos, listagem), não é um resumo superficial de endereço.
- Combina livremente com qualquer outra opção do `A` no mesmo bloco (`A O/8000`, `A ONR/1000`).

### Bastidores

- Zero mudança no motor de montagem compartilhado (`Z80Asm.pbi`) — a solução ficou inteira em
  `Mamute_AsmAssemble()`, envolvendo o operando de toda linha `ORG` em `(...)+0XXXXh` antes de montar.
  O resto da montagem segue o deslocamento automaticamente, por ser aritmética resolvida pelo próprio
  avaliador de expressão.
- Verificado byte a byte: `A O/1000` deslocou um programa de `ORG 0C100H` inteiro para `D100-D11A`,
  incluindo a referência interna `LD HL,PRINT` corretamente reapontando pro endereço deslocado, com a
  constante `EQU` e o salto relativo permanecendo intactos, como esperado.

Com esta versão, toda a lista de opções do comando `A` do manual original do MegaAssembler
(`A [NUPOIRSDH/<offset>]`) está implementada, exceto `U` (não lista o programa).

### Empacotamento deste lançamento

- **O executável mudou de nome**: `editor\BadigEditor.exe` → **`editor\PaleoBasic.exe`** (o arquivo-fonte
  `editor\BadigEditor.pb` continua com o mesmo nome — mudança cosmética no artefato final, mesmo
  espírito da rebatização do projeto como "Paleobasic"). `build.ps1`/`build.sh` já compilam com o nome
  novo por padrão; qualquer atalho/script que apontava pro `.exe` antigo precisa ser atualizado.
- **Ícone e splash screen também renomeados**: `msxbasica.ico` → **`paleobasic.ico`** (embutido no `.exe`
  via `/ICON`, reextraído em runtime pra toda janela top-level) e `msxbasica.png` → **`paleobasic.png`**
  (arte de capa mostrada na splash screen de abertura). Verificado ao vivo: ícone aparece corretamente na
  barra de título, splash screen carrega e mostra a arte normalmente.
- O capítulo **Mamute Assembler** de `docs/MANUAL.md` foi reescrito do zero — cobria só `PAGE`/`DM`/`ZAP`
  antes, agora documenta o conjunto completo de comandos (`SCR`, `SH`, `MS`, `LOAD`/`SAVE`, `M`/`S`,
  `C`/`D`/`P`/`V`, `T`/`F`, `G`/`X`, `R`/`L`/`LP`, `EDIT` e todas as opções do `A`).
- Pacote de distribuição gerado via `build.ps1 -D` (pasta `distribute\`) e publicado como
  `paleobasic-v073343.zip`.

---

## 7.33.42 — "LABELS NA IMPRESSORA" (2026-08-13)

**Tema da versão**: opção `H` do comando `A` — imprime só as listas de labels (não o código) em PDF.

### Novidades

- **`A SH`/`A DH`** manda só a(s) lista(s) de labels (alfabética `S` e/ou por ordem de aparição `D`)
  pra um PDF separado do de `P`. `H` precisa vir acompanhada de `S` e/ou `D` — sozinha é rejeitada com
  mensagem explicando o motivo.
- Se `S` e `D` estiverem ativas junto com `H`, as duas listas vão pro mesmo PDF, separadas por uma
  linha em branco.

---

## 7.33.41 — "ORDEM DE APARICAO" (2026-08-13)

**Tema da versão**: opção `D` do comando `A` — lista de labels por ordem de definição no fonte, não
alfabética.

### Novidades

- **`A D`** é idêntica à `A S`, mas os símbolos aparecem na ordem em que foram definidos no fonte, não
  em ordem alfabética.

### Bastidores

- Exigiu um mecanismo novo no motor de montagem: `DefineSymbolSeg()` (`Z80Asm.pbi`) agora detecta a
  transição exata "símbolo ainda não conhecido → conhecido" e grava essa ordem — necessário porque uma
  referência pra frente (`LD HL,PRINT` antes de `PRINT:` ser definido) já cria a entrada do símbolo na
  tabela antes da definição de verdade acontecer.
- Validado com um caso onde a ordem de aparição realmente diverge da alfabética (`SALT` definido antes
  de `PRINT` no fonte, mas depois na ordem alfabética) — as duas listagens (`S` e `D`) mostraram ordens
  visivelmente diferentes, confirmando que não são coincidentemente iguais.

---

## 7.33.40 — "LISTA DE LABELS" (2026-08-13)

**Tema da versão**: opção `S` do comando `A` — lista alfabética simples de labels (sem endereços de
uso).

### Novidades

- **`A S`** anexa ao final da listagem uma lista alfabética simples dos símbolos (nome + valor/endereço
  de definição), sem os endereços de uso (isso é o `R`). Combina com `R` no mesmo bloco.

---

## 7.33.39 — "REFERENCIA CRUZADA" (2026-08-13)

**Tema da versão**: opção `R` do comando `A` — referência cruzada de símbolos, reproduzindo fielmente
um print real do MegaAssembler original.

### Novidades

- **`A R`** anexa ao final da listagem uma referência cruzada dos símbolos em ordem alfabética: nome,
  valor (constante `EQU` ou endereço de definição do rótulo) e todos os endereços onde foi usado (até 4
  por linha, com continuação se precisar).

### Bastidores

- Exigiu rastrear cada uso de símbolo durante a montagem (`EvalPostfixExpr()`, `Z80Asm.pbi`) — gravado
  só durante a passagem de emissão, pra não duplicar contagens.
- Validado contra um print de tela real do MegaAssembler original fornecido pelo usuário: saída
  idêntica, símbolo por símbolo, valor por valor, endereço por endereço.

---

## 7.33.38 — "OPCAO I" (2026-08-13)

**Tema da versão**: opção `I` do comando `A` — grava o código-objeto direto em disco, no formato real
de BLOAD do MSX.

### Novidades

- **`A I`** grava o código-objeto recém montado em disco (cabeçalho `FE` + endereço inicial/final/
  execução, formato real do BSAVE/BLOAD do MSX), reaproveitando a mesma janela do comando `SAVE` do
  monitor — tudo pré-preenchido (slot, endereços) e editável antes de gravar. Diferente de `O`, não
  precisa que os bytes já estejam na RAM simulada.

---

## 7.33.37 — "OPCAO P" (2026-08-13)

**Tema da versão**: opção `P` do comando `A` — listagem completa em PDF.

### Novidades

- **`A P`** manda a listagem completa (código incluído) pra um PDF, além de mostrá-la na tela — mesma
  infraestrutura já usada por `L`/`LP`/`P`/`V`/`LSEARCH`.

---

## 7.33.36 — "OPCAO N" (2026-08-13)

**Tema da versão**: opção `N` do comando `A` — listagem sem a coluna de número de linha.

### Novidades

- **`A N`** omite a coluna de número de linha da listagem — endereço/valor, bytes hexa e conteúdo
  continuam iguais. Combina com `O` e as demais opções no mesmo bloco.

---

## 7.33.35 — "PASSO-1 PASSO-2" (2026-08-13)

**Tema da versão**: listagem detalhada, coluna a coluna, do comando `A` — reproduzindo o formato
clássico do MegaAssembler original.

### Novidades

- `A` agora mostra `PASSO-1` e depois `PASSO-2` (mesma sequência do assembler original) antes de
  montar, e o resultado vira uma listagem coluna a coluna: número da linha, endereço (ou valor de
  `EQU`), até 4 bytes de código-objeto em hexa por linha (com continuação se a instrução gerar mais) e
  o conteúdo original da linha.
- A listagem usa a mesma paginação de tela cheia do `LIST` quando não cabe inteira.

### Bastidores

- A listagem é construída dentro do próprio `Z80Asm.pbi` durante a passagem de emissão, sem
  reimplementar nenhuma lógica de montagem.

---

## 7.33.34 — "O COMPILADOR" (2026-08-13)

**Tema da versão**: o comando `A` passa a montar código Z80 de verdade — o Mamute Assembler deixa de
ser só um monitor de memória.

### Novidades

- **`A`** monta o programa-fonte digitado no `EDIT`, reaproveitando o assembler Z80 nativo do projeto
  (compatível M80/Nestor80) — valida a sintaxe e mostra erros descritivos com o cursor pulando direto
  pra linha com problema.
- **`A O`** além de validar, escreve o código-objeto na RAM simulada, no endereço do `ORG`, resolvido
  pelo mapeamento de `PAGE` ativo.
- **`MAP`** mostra o endereço inicial/final da última montagem bem-sucedida.

### Bastidores

- Dois bugs reais corrigidos com o primeiro programa de teste do usuário: um número hexadecimal sem
  sufixo digitado no `EDIT` (aceito por lá) era rejeitado pelo assembler de verdade (que segue a
  convenção clássica decimal-por-padrão) — corrigido traduzindo os números na fronteira entre os dois.
  E um bug mais antigo, latente no próprio motor `Z80Asm.pbi`: uma linha como `"CHPUT: EQU 0A2H"`
  (label com dois-pontos + `EQU`) definia o símbolo duas vezes, colidindo consigo mesma — corrigido no
  motor, verificado sem regressão na suíte de testes existente e byte a byte contra o assembler `N80.exe`
  real.

---

## 7.33.33 — "TELA DE VERDADE" / "GERENCIAMENTO COMPLETO" (2026-08-13)

**Tema da versão**: o comando `EDIT` — um editor de linhas completo pro programa-fonte Z80, no estilo
do ZX-81/ZX Spectrum, com todos os comandos de gerenciamento do manual original do MegaAssembler.

### Novidades

- **`EDIT`** abre uma janela separada onde a listagem É a própria tela (sem log de comandos nem
  mensagem "OK") — um cursor `>` marca a linha atual, setas Cima/Baixo navegam, ENTER com o campo vazio
  puxa a linha do cursor pra editar, ENTER com o campo preenchido grava. A tela rola meia-tela sozinha
  quando enche digitando linhas novas.
- Sintaxe de linha `NN Label: instrução operando ;comentário`, aceitando mnemônicos Z80 reais e as
  pseudo-instruções `ORG`/`DEFB`/`DEFW`/`DEFM`/`DEFS`/`EQU`/`END`. Números sem sufixo são hexadecimal
  por padrão (diferente do manual original, que usa decimal) — sufixos `H`/`B`/`D` continuam
  disponíveis.
- **`LIST`** relista do início, paginando tela cheia por tela cheia com "Rolar mais uma tela? (S/N)".
- **`NEW`**, **`DELETE <lininic>[-[<linfin>]]`**, **`RENUM [<novali>[,<antigali>[,<incr>]]]`**,
  **`CHANGE '<string1>'[,'<string2>']`** — gerenciamento completo do programa-fonte.
- **`SAVE`**/**`LOAD`** gravam/leem o programa num arquivo `.mza` em ASCII simples (não o formato
  binário proprietário do MegaAssembler original).
- **`MERGE`** funde um arquivo no programa em memória sem apagá-lo, sobrepondo linhas de mesmo número.
- **`SEARCH '<string>'`**/**`SEARCH <string>`** (literal/livre) filtram a tela pras linhas encontradas;
  **`LSEARCH`** manda o resultado pra PDF; **`FIND`** é um apelido de `SEARCH`.
- **`QUIT`** fecha a janela sem apagar o programa da memória — reabrir `EDIT` continua de onde parou.

### Bastidores

- Indentação automática da listagem (label na coluna 0, instrução alinhada numa tab stop, comentário
  numa coluna própria mais à direita) — afeta só o desenho da tela, o texto guardado continua exatamente
  como digitado.
- Passou por duas reescritas na mesma sessão a partir de feedback direto do usuário, até chegar num
  pedido específico: "um editor exatamente idêntico ao do ZX-81... exceto as teclas tokenizadas".

---

## 7.33.32 — "TELA MAIOR" (2026-08-12)

**Tema da versão**: janela do Mamute Assembler maior e fonte padrão maior/mais legível, depois de
investigar um relato de "disassembly incompleto" que acabou não sendo bug nenhum.

### Novidades

- Janela do Mamute Assembler aumentada de 720×480 para 960×640 — mostra bem mais linhas de log de
  uma vez sem precisar rolar.
- Tamanho padrão da fonte do terminal aumentado de 14 para 16 (negrito já era o padrão).
- Fonte/tamanho/negrito continuam configuráveis em `Configurar → Mamute Assembler...`.

### Bastidores

- Investigação de um relato de bug ("`L 0,100` disassembla poucas instruções, diferente a cada
  execução") confirmou, com automação de UI real contra o ROM de verdade do usuário (repetida, e com
  um teste de estresse levando o log a mais de 160 mil caracteres sem qualquer perda), que a
  listagem estava correta e completa o tempo todo — o texto colado pelo usuário bateu exatamente com
  a listagem de referência. O "bug" era só a janela antiga não caber 115 linhas sem rolar, e a barra
  de rolagem não ter sido percebida.
- `WinW`/`WinH` (`MamuteAssemblerGui.pbi`) e `MamuteFontSize` (`MamuteSupport.pbi`, `Global` e o
  bloco de reset em `MamuteCfg_Load()`) ajustados — todos os gadgets da janela já eram parametrizados
  por `WinW`/`WinH`, então mudar as duas constantes redimensionou tudo automaticamente.
- Verificado com uma captura de tela real (`PrintWindow`) da janela redimensionada, confirmando fonte
  maior/em negrito e mais área de log visível.

---

## 7.33.31 — "DESMONTANDO O CODIGO" (2026-08-12)

**Tema da versão**: `L`/`LP`, um disassembler Z80 completo (base + `CB` + `ED` + `DD`/`FD` indexados,
incluindo formas não documentadas estáveis) para o Mamute Assembler.

### Novidades

- **`L [<endinic>[,<endfim>]]`** — disassembla a memória RAM/ROM (mapeamento `PAGE` ativo agora) direto
  no log do `MON>`. Com os dois endereços, decodifica até ultrapassar `<endfim>`; só `<endinic>`, 10
  instruções; sem nenhum, continua de onde o `L`/`LP` mais recente parou.
- **`LP [<endinic>[,<endfim>]]`** — mesma listagem do `L`, mas gera um PDF A4 (mesma infra do `P`/`V`)
  em vez de mandar pro log.
- Cada linha mostra endereço, bytes crus em hexa e mnemônico com operandos. Saltos relativos (`JR`/
  `DJNZ`) mostram o endereço de destino absoluto, não o deslocamento cru.
- Conjunto de instruções completo: toda a tabela documentada do Z80 mais as formas não documentadas
  mais estáveis (`IXH`/`IXL`/`IYH`/`IYL`, `CB` indexado com cópia-sombra, prefixos `DD`/`FD` encadeados).

### Bastidores

- `Mamute_DisasmOne()`/`Mamute_DisasmBuildLines()` (`editor/MamuteSupport.pbi`, novos, ~450 linhas) —
  tabela de opcodes construída do zero via a decomposição x/y/z/p/q clássica de decodificação do Z80
  (não havia tabela reaproveitável no assemblador `Z80Asm.pbi` deste projeto — ele codifica
  proceduralmente, sem tabela estática bytes→mnemônico).
- Substituição `IX`/`IY` (8 e 16 bits) implementada parametrizando as MESMAS tabelas de nome de
  registrador usadas pela decodificação normal — opcodes que não referenciam `H`/`L`/`(HL)`/`HL`
  produzem o mesmo texto nas 3 variantes automaticamente, sem precisar de uma lista separada de "quais
  opcodes o prefixo afeta".
- Prefixos `DD`/`FD` encadeados tratados com um laço simples: cada prefixo é consumido 1 byte por vez,
  só o último antes do opcode de verdade "vale" — mesmo comportamento do hardware real.
- Verificado com um harness de teste temporário (removido ao final da sessão): 151 casos pontuais
  corretos byte a byte (cobrindo cada ramo da tabela, matemática de salto relativo através de um
  prefixo desperdiçado, deslocamentos negativos, cópia-sombra não documentada, imunidade do `HALT`/
  `EX DE,HL` ao prefixo) mais uma varredura de completude confirmando que nenhum dos 512 opcodes
  base+`CB` fica sem decodificação — depois verificado de ponta a ponta na UI real.
- **Achado real de compilador/runtime, documentado em `CLAUDE.md`**: o padrão `*Ptr.String` para
  parâmetros de saída (devolver uma string por referência) travou com acesso inválido de verdade neste
  contexto específico (arquivo de ~30 mil linhas numa única unidade de compilação) — corrigido
  devolvendo o texto como retorno normal da função (`Procedure.s`) em vez de escrever por ponteiro de
  string. Ponteiros de saída pra tipos fixos (`Integer`/`Byte`/etc.) continuam funcionando normalmente.

---

## 7.33.30 — "REGISTRADORES EM ESPERA" (2026-08-12)

**Tema da versão**: `X` (registradores do Z80 simulado, funcional de verdade) mais `G` e `R` como
entradas reconhecidas mas explicitamente adiadas para uma fase futura — pedido direto do usuário.

### Novidades

- **`X [<reg>]`** — sem argumento, mostra os 7 pares de registrador (`AF`/`BC`/`DE`/`HL`/`IX`/`IY`/
  `SP`) de uma vez. Com argumento, entra num modo de edição sequencial a partir do registrador
  escolhido — aceita tanto um **par** (`AF`/`BC`/`DE`/`HL`/`IX`/`IY`/`SP`, editado como um valor
  único de 16 bits/4 dígitos hexa) quanto um **registrador de 1 byte isolado** (`A`/`F`/`B`/`C`/`D`/
  `E`/`H`/`L`, 2 dígitos hexa) — extensão pedida explicitamente pelo usuário sobre o manual original.
  Cada registrador da sequência é perguntado numa caixa de diálogo com o valor atual já preenchido:
  confirmar sem editar **mantém** o valor e passa pro próximo; apagar o campo (ou Cancelar) **para**
  a caminhada ali mesmo. Registradores duram só a sessão da janela.
- **`G <endinic>[,<brkpnt1>[,<brkpnt2>]]`** — reconhece e valida a sintaxe completa (endereço inicial
  obrigatório, até 2 breakpoints opcionais), mas **ainda não executa nada** — confirma no log que
  entendeu o comando. Execução real de programas (com registradores/breakpoints de verdade) fica
  para uma fase futura do projeto, por pedido explícito do usuário.
- **`R [<offset>]`** — confirma no log que o carregamento de um programa assemblado depende do
  assemblador Z80 embutido, que também fica para uma fase futura. Não valida nem usa o argumento.

### Bastidores

- Novos campos `Reg*` em `MamuteGui_State` (`MamuteAssemblerGui.pbi`) — `A`/`F`/`B`/`C`/`D`/`E`/`H`/
  `L` como bytes, `IX`/`IY`/`SP` como palavras de 16 bits, zero-inicializados (mesmo espírito volátil
  do `PAGE`/`DisplayMode`).
- `MamuteGui_RegPairValue()`/`SetRegPair()`/`RegByteValue()`/`SetRegByte()` (novos) — leitura/escrita
  dos registradores por nome, compartilhadas entre a exibição (`X` sem argumento) e a caminhada de
  edição (`X <reg>`).
- **Achado real de automação de teste, não um bug do app**: a primeira tentativa de automatizar as
  caixas de diálogo do `X` assumiu que o botão OK teria o ID de controle clássico `1`/`IDOK` (como
  funciona nos diálogos comuns do Windows usados pelo `SAVE`/`P`/`V`) — mas o `InputRequester()` do
  PureBasic gera seus próprios botões com IDs internos do framework, não `1`. O clique automatizado
  não acertou o botão de verdade, o diálogo nunca fechou, e o app inteiro ficou travado nesse diálogo
  modal (bloqueando até o teste seguinte, que reusou o mesmo diálogo sem perceber). Corrigido achando
  o botão pela classe `Button` + texto "OK" em vez de um ID assumido — mais robusto contra diálogos
  gerados internamente pelo framework em vez de diálogos comuns do sistema.
- Verificado de ponta a ponta com automação de UI real (incluindo as caixas de diálogo nativas, uma
  vez corrigida a detecção do botão OK): `G` testado com 1/2/3 argumentos e com endereços/breakpoints
  inválidos; `R` confirmado ignorando qualquer argumento; `X IX` setou `IX=ABCD` e parou em `IY`
  (deixando `IY`/`SP` intactos); `X BC` setou `BC=1234`/`DE=5678` e parou em `HL` sem alcançar `IX`
  — prova real de que parar num campo vazio realmente impede a caminhada de tocar nos registradores
  seguintes; `X A` (modo byte) setou `A=AA` e parou em `F`, confirmado no par combinado `AF=AA00`.

---

## 7.33.29 — "TRANSFERE E PREENCHE" (2026-08-12)

**Tema da versão**: `T` e `F`, os comandos de transferência e preenchimento de bloco de memória.

### Novidades

- **`T <endinic>,<endfim>,<enddest>`** — transfere (copia) o bloco de memória RAM/ROM entre `<endinic>`
  e `<endfim>` (inclusive, mapeamento `PAGE` ativo agora) para o bloco do mesmo tamanho iniciado em
  `<enddest>`. Origem e destino sobrepostos são tratados corretamente (copia de trás pra frente ou de
  frente pra trás conforme necessário, mesmo cuidado de um `memmove` de verdade).
- **`F <endinic>,<endfim>,<byte>`** — preenche esse mesmo tipo de bloco inteiro com um único byte
  repetido.
- Nem `T` nem `F` dão a volta pro `0000` (mesma regra do `D`/`P`/`V`) — `<endfim>` menor que
  `<endinic>`, ou um destino do `T` que passe de `FFFF`, são `?ERRO DE SINTAXE`.
- Escrita silenciosa em células que não sejam RAM nos dois comandos (`Mamute_WriteByte` já recusa,
  mesma regra do `DM`/`MS`).

### Bastidores

- `MamuteGui_CmdT()`/`MamuteGui_CmdF()` (`MamuteAssemblerGui.pbi`, novos) — parsing manual de 3 campos
  separados por vírgula (mesmo idioma do `MS`), sem depender de `MamuteGui_ParseDpvArgs()` (essa é
  específica pro par `<endinic>[,<endfim>]` opcional dos comandos `D`/`P`/`V`, formato diferente).
- `T` decide a direção da cópia comparando `<enddest>` com `<endinic>`: copia de trás pra frente
  (`Length-1` até `0`) quando o destino vem depois da origem, de frente pra trás caso contrário — evita
  corromper bytes de origem ainda não lidos quando os blocos se sobrepõem.
- Verificado de ponta a ponta com automação de UI real, usando endereços em `C000-FFFF` (confirmado RAM
  no config real do usuário pelos testes do `M`/`S` numa sessão anterior — `4000-7FFF` é ROM/BASIC
  nesse mesmo config, achado real ao tentar testar `F`/`T` ali primeiro e ver a escrita silenciosamente
  recusada, mesma "lacuna conhecida" já documentada no `docs/SPEC.md`): preenchimento simples
  confirmado byte a byte via `D`; cópia simples confirmada; teste de sobreposição real (`MS` gravando um
  texto reconhecível, depois um `T` com destino dentro do mesmo bloco de origem) confirmou o conteúdo
  final exatamente como esperado, provando que a lógica de direção realmente evita a corrupção que uma
  cópia ingênua causaria; os 4 casos de erro (endereço final menor que o inicial nos dois comandos, byte
  de 3 dígitos no `F`, destino do `T` estourando `FFFF`) todos rejeitados corretamente.

---

## 7.33.28 — "SAINDO NA IMPRESSORA" (2026-08-12)

**Tema da versão**: `D`/`P`/`V`, os comandos de dump de memória formatado que o `C` preparou terreno para
— mais uma VRAM simulada nova, pra dar sentido ao `V`.

### Novidades

- **`D <endinic>[,<endfim>]`** — despeja a memória RAM/ROM (mapeamento `PAGE` ativo agora) formatada
  conforme o modo escolhido em `C`, direto no log do `MON>`. Sem `<endfim>`, mostra só 16 bytes.
- **`P <endinic>[,<endfim>]`** — mesmo despejo do `D`, mas "na impressora": gera um **PDF A4** simples
  (fonte Courier, cabeçalho com o intervalo/modo, paginação automática a cada ~56 linhas) e abre "Salvar
  como" no final. Um driver de verdade pra impressora dot-matrix Epson FX-80 é um projeto separado do
  usuário pra uma sessão futura — o PDF é a solução provisória.
- **`V <endinic>[,<endfim>]`** — igual ao `P`, mas lê da **VRAM simulada** nova em vez da RAM/ROM.
- **VRAM simulada** (`Configurar → Mamute Assembler...`) — tamanho configurável entre **16KB** (MSX1,
  mesmo teto que o MegaAssembler original enxergava), **128KB** ou **192KB** (MSX2/2+, ampliação desta
  ferramenta sobre o original). Endereçamento **plano, sem banco/página** — a VRAM de um MSX real nunca
  fica mapeada no espaço de endereços do Z80 (é acessada pelas portas do VDP), então a restrição de 16
  bits que vale pra RAM/ROM não se aplica.
- Nem `D`/`P`/`V` dão a volta pro `0000` como o `SH`/`M` fazem — passar do teto do espaço de endereços
  (`FFFF` na RAM/ROM, o tamanho de VRAM configurado na VRAM) é `?ERRO DE SINTAXE`.

### Bastidores

- `Mamute_BuildDumpLines()` (`MamuteSupport.pbi`, novo) — monta as linhas formatadas compartilhadas por
  `D`/`P`/`V`, parametrizada por `IsVram` (escolhe entre `Mamute_ReadByte()`/`MamuteVRAM()`).
- `Mamute_SavePdfListing()` (`editor/MamutePdf.pbi`, novo arquivo) — gera os bytes de um PDF 1.4 à mão
  (sem lib externa, PureBasic não tem uma nativa): objetos Catalog/Pages/Page/Content-stream/Font,
  `MediaBox [0 0 595 842]`, tabela `xref` de 20 bytes por linha, tudo ASCII puro (conteúdo é só dígitos
  hexa/texto, sem precisar de compressão/stream binário).
- `MamuteVRAM()` (`MamuteSupport.pbi`) — array plano de até 192KB, sempre alocado no tamanho máximo
  (trivial em memória) mesmo que o usuário mude o tamanho configurado depois — evita `ReDim`/perda de
  dado.
- `Mamute_ParseVramAddr()`/`Mamute_HexPad()` (`MamuteSupport.pbi`, novos) — endereço de VRAM aceita até 5
  dígitos hexa (o teto de 192KB passa de `FFFF`), validado contra o tamanho configurado agora.
- `VLOAD`/`VSAVE` (ou uma extensão do `LOAD`/`SAVE` existente pra ler/gravar VRAM) ficam explicitamente
  fora de escopo desta versão — pedido direto do usuário; a VRAM simulada começa sempre zerada.
- Verificado de ponta a ponta com automação de UI real (sem simular teclado/mouse): `D` nos 3 modos com
  bytes reais da ROM carregada; `P`/`V` geraram PDFs cujos offsets do `xref` foram conferidos byte a
  byte contra o conteúdo real do arquivo; `V` testado também com uma listagem de 10 páginas confirmando
  a paginação automática; endereços fora do teto (RAM e VRAM) rejeitados com `?ERRO DE SINTAXE`.

---

## 7.33.27 — "PREPARANDO O VISOR" (2026-08-12)

**Tema da versão**: `C`, o comando que escolhe o modo de exibição para os futuros comandos `D`/`P`/`V` —
pequeno e sem janela, prepara terreno pra próxima leva.

### Novidades

- **`C <modo>`** — guarda qual dos 4 formatos de exibição os comandos `D`/`P`/`V` (dump de memória
  formatado, ainda não implementados) vão usar:
  - `0` — hexadecimal + ASCII, 4 bytes por linha.
  - `1` — igual ao `0`, mas 16 bytes por linha (pra telas/impressoras de 80 colunas).
  - `2` — só hexadecimal, 8 bytes por linha, com um checksum no final de cada linha = soma dos 8 bytes +
    o byte baixo do endereço inicial da linha (tudo módulo 256).
  - `3` — igual ao `2`, mas o checksum é só a soma dos bytes, sem somar o endereço.
- Sozinho não mostra nada na tela — só confirma o modo escolhido no log do `MON>`
  (`MODO 1: HEXA+ASCII, 16 BYTES/LINHA`).
- Estado dura só enquanto a janela do Mamute Assembler estiver aberta — não persiste em
  `mamute_settings.json`, mesmo espírito volátil do `PAGE`.

### Bastidores

- Novo campo `DisplayMode.b` em `MamuteGui_State` (`MamuteAssemblerGui.pbi`) — zero-inicializado, então o
  modo padrão já é `0` sem precisar de código extra.
- `Mamute_DisplayModeText()` (`MamuteSupport.pbi`, novo) — só uma tabela `Select`/`Case` mapeando modo →
  descrição, reaproveitável pelos futuros `D`/`P`/`V` quando formatarem a saída de verdade.
- **Achado de sintaxe, documentado em vez de contornado**: o exemplo do manual original usa `C1` colado
  (sem espaço) — não reconhecido aqui, porque `MamuteGui_Dispatch()` sempre separa verbo de argumentos
  pelo primeiro espaço digitado, igual todo outro comando do Mamute Assembler. Em vez de adicionar um caso
  especial só pra esse comando, a Ajuda documenta explicitamente que é preciso digitar `C 1` (com espaço).
- Verificado de ponta a ponta: `C 0`/`C 1`/`C 2`/`C 3` confirmados cada um com a descrição certa; `C 4`
  (fora da faixa `0-3`) e `C` (sem argumento) rejeitados com `?ERRO DE SINTAXE`; `C1` sem espaço
  confirmado caindo em `?COMANDO INVALIDO` (o verbo digitado literalmente vira `"C1"`, que não bate com
  nenhum `Case` do dispatcher) — comportamento esperado, não um bug.

---

## 7.33.26 — "TECLADO NUMERICO" (2026-08-12)

**Tema da versão**: `M` e `S`, edição rápida de memória no Mamute Assembler — mesma grade/navegação do
`DM`, mas hexa digitado tecla-a-tecla direto; `S` usa um teclado numérico totalmente configurável.

### Novidades

- **`M [<endereço>]`** — mesma grade de 128 bytes e mesma navegação do `DM` (setas, `PgUp`/`PgDn`, `TAB`,
  botões, `+`/`-` de deslocamento). Edição de byte diferente: digite dois dígitos hexa (`0-9`, `A-F`)
  direto, sem abrir campo de texto — o 1º dígito mostra `"3_"` esperando o 2º, que confirma o byte e
  avança o cursor sozinho. `RETURN` sempre sai da janela (como no manual original); `ESC` cancela um
  dígito pendente ou sai. Bloco de texto (ASCII) é somente leitura. Endereço omitido continua de onde a
  janela do `M` ficou da última vez.
- **`S [<endereço>]`** — idêntico ao `M`, mas usa um **teclado numérico configurável** (`Configurar →
  Mamute Assembler...`) em vez de `0-9`/`A-F` fixos. Padrão: `1,2,3,4,Q,W,E,R,A,S,D,F,Z,X,C,V` — mesmo
  layout clássico usado em jogos/emuladores (4 fileiras da esquerda do teclado QWERTY). Guarda seu
  próprio "último endereço", separado do `M`.
- **Nova seção em `Configurar → Mamute Assembler...`**: grade 4x4 rotulada `1,2,3,4,5,6,7,8,9,A,B,C,D,
  E,F,0`, um campo de 1 caractere por posição, pra escolher livremente qual tecla física representa cada
  dígito hexa do `S`.

### Bastidores

- **`editor/MamuteMGui.pbi`** (novo arquivo) — `MamuteM_Open(ParentWindow, StartAddr, StartOffset,
  UseCustomKeys)` é o código COMPARTILHADO entre `M` e `S`; `UseCustomKeys` só decide se a tabela de 16
  teclas vem fixa (`0-9`/`A-F`) ou de `MamuteSKeyMap()` (`MamuteSupport.pbi`, novo array configurável,
  indexado pelo VALOR do nibble 0-15). Devolve o endereço final da janela (não recebe/toca
  `G_Log`/`MamuteGui_State` diretamente — mesma razão de independência já usada por `MamuteScr_Open`/
  `MamuteSave_Open`: esse tipo só é declarado mais tarde no arquivo que inclui este antes).
- **Decisão deliberada de não reaproveitar o campo de texto em 2 estágios do `DM`** pra digitar hexa:
  discutido com o usuário antes de implementar — usar `AddKeyboardShortcut` pras 16 teclas (fixas ou
  configuráveis) evita ter que descobrir se um atalho de janela rouba ou não uma tecla de um campo de
  texto nativo do Windows focado (comportamento não testado neste projeto). Resolvido tornando o bloco de
  texto (ASCII) somente leitura em `M`/`S` - elimina a pergunta inteira, não só contorna.
- `Mamute_KeyCharToShortcut()` (`MamuteSupport.pbi`, novo) converte um caractere (`"Q"`, `"1"`...) na
  constante `#PB_Shortcut_*` certa - usado pelas 16 teclas do `S`.
- **Verificado de ponta a ponta com automação de UI e captura de tela real**, não só revisão de código:
  byte `3F` seguido de `A5` digitados tecla-a-tecla (via `PostMessage` nos IDs internos dos atalhos,
  mesma técnica message-based já usada no projeto) no `M`, confirmados na grade — inclusive o caractere
  `?` correto na coluna ASCII pro byte `3F` (`0x3F` = `'?'` em ASCII). Janela fechada e reaberta com `M`
  sem endereço - reabriu exatamente no mesmo endereço com o mesmo conteúdo, confirmando a "memória" de
  último endereço. `S` testado escrevendo outro byte pelo mesmo mecanismo compartilhado. Tela de
  configuração conferida por captura de tela real: grade 4x4 renderizada corretamente, com os rótulos e
  os valores padrão exatos pedidos (`1,2,3,4/Q,W,E,R/A,S,D,F/Z,X,C,V`).

---

## 7.33.25 — "GRAVANDO O CARTUCHO" (2026-08-12)

**Tema da versão**: `SAVE`, o comando de gravação de arquivos do Mamute Assembler — o inverso natural do
`LOAD` — mais um refinamento no próprio `LOAD` (nome sugerido no diálogo).

### Novidades

- **`LOAD <nome>`** — o nome digitado depois de `LOAD` (ex.: `LOAD alfabeto.alf`) não carrega nada
  sozinho, só pré-preenche o campo de nome na janela de escolher arquivo e acrescenta a extensão dele ao
  filtro padrão (`*.alf;*.bin;*.rom`, no exemplo). O arquivo carregado de verdade é sempre o confirmado
  na janela.
- **`SAVE [<nome>][,<endinic>,<endfim>[,<endexec>]]`** — abre uma janela própria (estilo normal da IDE,
  não o terminal preto/verde) pra revisar tudo antes de gravar. Nome e endereços digitados no comando só
  pré-preenchem os campos (endereço de execução vazio = igual ao inicial).
- **Campos da janela**: Arquivo (editável + botão "..." com `SaveFileRequester`); Slot (0-3), sugerido a
  partir do mapeamento `PAGE` ativo na página do endereço inicial; Endereço inicial/final/execução;
  Formato — `BIN` (cabeçalho real do BSAVE: `FE` + 3 endereços) ou `ROM` (formato próprio deste
  simulador: `AB` + os mesmos 3 endereços, sugerido pela extensão `.rom` mas trocável); checkbox "Salvar
  sem cabeçalho" (ignora o formato, grava só os bytes crus).
- Confirma no log do `MON>`: `SALVO "<arquivo>" - SLOT <slot> - <inicial>-<final> - TAMANHO <tamanho>`.

### Bastidores

- **`editor/MamuteSaveGui.pbi`** (novo arquivo) — `MamuteSave_Open()` devolve uma string de resultado em
  vez de tocar `G_Log`/`MamuteGui_State` diretamente (esse tipo só é declarado mais tarde em
  `MamuteAssemblerGui.pbi`, que inclui este arquivo antes) — mesma razão de independência já usada por
  `MamuteScr_Open`/`MamuteZap_Open`.
- **Lê DIRETO de `MamuteMem(Slot,...)`** pro range pedido, sem passar pelo `PAGE`/`Mamute_ReadByte()` —
  mesma filosofia do `LOAD`: o usuário escolhe explicitamente de qual slot físico ler.
- Cabeçalho e dados montados num único buffer (`Dim FullBuf.a(...)`) e gravados com uma `WriteData()` só
  — sem depender de `WriteByte()` (nunca confirmado como existente na API de arquivos do PureBasic usada
  neste projeto).
- **Verificado de ponta a ponta com automação completa da janela e inspeção byte a byte dos arquivos
  reais gerados**, não só revisão de código: string `XYZ1` gravada em RAM via `MS C000,'XYZ1`, depois
  `SAVE savetest1.bin,C000,C003` (endereços vindos do comando, Slot sugerido corretamente como `3` — a
  página de `C000` está mapeada nesse slot) — arquivo resultante conferido byte a byte mostrou exatamente
  `FE 00 C0 03 C0 00 C0 58 59 5A 31` (cabeçalho `FE`+`C000`+`C003`+`C000` little-endian + `"XYZ1"`
  literal). Depois `SAVE savetest2.rom` (só nome, sem endereços — Formato auto-detectado como `ROM` pela
  extensão, confirmado antes de gravar) com endereços preenchidos na janela — arquivo resultante mostrou
  `41 42 00 C0 03 C0 00 C0` + os 4 bytes do slot lido (`AB`+`C000`+`C003`+`C000`, mesma estrutura do
  `BIN` só com `AB` no lugar do `FE`).
- **Achado real de automação, não um bug**: o mesmo problema de corrida já visto ao abrir a janela
  principal (menu com poucos itens se consultado cedo demais) se repetiu ao enumerar os controles filhos
  da janela do Mamute Assembler e da janela do `SAVE` logo após encontrá-las pelo título — resolvido com
  uma pequena pausa (~500ms) antes de `EnumChildWindows` em cada uma, mesma lição já registrada, agora
  confirmada acontecer em mais de um lugar.

---

## 7.33.24 — "INSERINDO O CARTUCHO" (2026-08-12)

**Tema da versão**: `LOAD`, o comando de carregamento de arquivos do Mamute Assembler — reimaginado como
totalmente interativo (janela de escolher arquivo + escolha de slot), em vez do `LOAD <arquivo>,B` de
linha de comando do manual original.

### Novidades

- **`LOAD`** (sem argumentos) — abre uma janela normal de escolher arquivo do Windows. Cancelar cancela
  o comando inteiro, sem gravar nada.
- **Sempre pergunta o Slot (0-3)** para carregar, sugerindo como padrão o slot que tiver RAM configurada
  (`Configurar → Mamute Assembler...`) — qualquer slot pode ser escolhido.
- **`.rom`** (cartucho) — carrega a partir de `4000` (Página 1); se tiver mais de 16KB (até 32KB), ocupa
  também `8000` (Página 2). Mais que 32KB não é suportado (precisaria de troca de banco) —
  `?ROM MAIOR QUE 32KB NAO SUPORTADA`.
- **Binário com cabeçalho BLOAD real do MSX** (byte `FE` + endereços inicial/final/execução, 2 bytes
  cada, little-endian — formato real do BSAVE) — carrega automaticamente no endereço indicado pelo
  cabeçalho.
- **Binário sem cabeçalho** — pergunta o endereço inicial (hexa) antes de carregar.
- **`.cas` ainda não suportado** — `?ARQUIVOS .CAS NAO SUPORTADOS AINDA`, em vez de tentar interpretar
  errado.
- Resultado sempre no log: `CARREGADO NO SLOT <slot> EM <endereço> - TAMANHO <tamanho> - FIM <endereço
  final>`.

### Bastidores

- **Grava direto na memória física do slot escolhido** (`MamuteMem(Slot,...)`), não pelo `PAGE`/
  `Mamute_WriteByte()` — decisão deliberada: `LOAD` simula "inserir um cartucho/carregar dado naquele
  slot", independente de qual slot está mapeado ativo agora.
- Ajusta `MamuteCfgCell()` das páginas realmente tocadas (RAM pro binário, ROM pro `.rom`) - **só em
  memória**, nunca chama `MamuteCfg_Save()`. Fechar e reabrir a janela do Mamute Assembler volta pra
  configuração salva de antes, igual desligar/ligar um MSX de verdade tira o cartucho.
- `MamuteGui_CmdLoad()` (`editor/MamuteAssemblerGui.pbi`) — diferencia `.rom` de binário pela EXTENSÃO do
  arquivo (`GetExtensionPart`), não pelo conteúdo — mais previsível pro usuário do que tentar adivinhar
  pelo cabeçalho. Lê o arquivo inteiro pra um array `.a()` (mesmo tipo unsigned de `MamuteMem()`, sem
  problema de sinal).
- **Verificado de ponta a ponta com arquivos reais e automação completa dos diálogos**, não só revisão de
  código: 3 arquivos de teste (binário sem cabeçalho, binário com cabeçalho BLOAD real, ROM de 16KB com
  um padrão de bytes reconhecível `00,01,02...FF`), cada um carregado via a sequência completa
  `OpenFileRequester` (técnica clássica `GetDlgItem(hDlg,1148)`/`GetDlgItem(hDlg,1)`/`BM_CLICK`, já
  confirmada em sessões anteriores) → `InputRequester` do slot (descoberto por inspeção real dos
  controles: classe `InputRequester`, campo de edição id `10`, botão OK id `1000`) → `InputRequester` do
  endereço quando aplicável. Confirmado não só pela mensagem de log, mas mapeando o slot carregado via
  `PAGE` e conferindo com uma captura de tela real do `DM` que o padrão de bytes do arquivo apareceu
  exatamente no endereço `4000` esperado.

---

## 7.33.23 — "TINTA INVISIVEL" (2026-08-12)

**Tema da versão**: `MS`, o comando de escrita de texto do Mamute Assembler — grava uma string na
memória simulada, com o mesmo deslocamento "cifrador" opcional já usado por `DM`/`ZAP`/`SH`.

### Novidades

- **`MS <endereço>,[<deslocamento>],'<texto>`** — grava o texto, byte a byte, a partir de
  `<endereço>` (obrigatório, hexa). `<deslocamento>` (opcional, hexa com sinal, `-7F` a `80`, mesma
  faixa do `DM`/`ZAP`/`SH`) — `0` se omitido. Um apóstrofo antes do texto, sem precisar fechar com
  outro; qualquer vírgula dentro do texto não quebra o comando.
- Cada caractere grava como `(código do caractere - deslocamento) & FF` — a MESMA fórmula do bloco de
  texto do `DM`. Texto gravado com deslocamento diferente de zero fica "cifrado" nos bytes crus, só
  reaparecendo legível se lido (`DM`) ou procurado (`SH`) com esse mesmo deslocamento — útil pra simular
  o truque clássico de esconder diálogo/texto num jogo antigo.
- **Sem janela** — só confirma `GRAVADO EM <endereço>` no log do `MON>`. Escrita silenciosa em células
  que não sejam RAM (mesma regra do `DM`/`SCR`) — sem aviso separado de "recusado".

### Bastidores

- `MamuteGui_CmdMs()` (`editor/MamuteAssemblerGui.pbi`) — parser lida com o meio-termo opcional
  (`<deslocamento>`) olhando se o token logo após o endereço começa com apóstrofo (deslocamento ausente)
  ou não (precisa achar mais uma vírgula antes do apóstrofo). Reaproveita `Mamute_WriteByte()`,
  `Mamute_ParseHexAddr()`, `Mamute_ParseHexOffset()`, `Mamute_Hex4()` já existentes — nenhum código novo
  de baixo nível, só o comando em si.
- **Verificado de ponta a ponta com dados reais**, não só revisão de código (mesma técnica `/CONSOLE`
  dentro de `editor/` das sessões anteriores): `MS C000,'nome` + `SH C000,'nome` confirmou
  `DESLOC +00`; `MS C010,20,'nome` + `SH C010,'nome` confirmou `DESLOC +20` auto-detectado pelo `SH`,
  provando o round-trip completo da "cifra" por deslocamento; `MS 0000,'ZWQK` (endereço ROM, Slot
  0/Página 0 na config real do usuário) + `SH 0000,'ZWQK` retornou `NAO ENCONTRADO`, confirmando que a
  escrita em ROM foi mesmo recusada de verdade (o comando sempre mostra `GRAVADO EM...` independente do
  resultado real, então só a busca posterior confirma se a escrita realmente aconteceu); sintaxes
  inválidas (`MS C020` sem string, `MS ,20,'nome` sem endereço) confirmadas rejeitadas com
  `?ERRO DE SINTAXE`.

---

## 7.33.22 — "AGULHA NO PALHEIRO" (2026-08-12)

**Tema da versão**: `SH`, o comando de busca do Mamute Assembler — bytes exatos com curinga, ou texto
com detecção automática de deslocamento, direto no log do `MON>`, sem abrir janela nenhuma.

### Novidades

- **`SH [<endereço>],<byte>[,<byte>...]`** — busca uma sequência exata de bytes em hexa na memória
  simulada. Deixar um `<byte>` vazio entre vírgulas (`SH 4000,2A,,0C`) vira curinga — "esse byte pode ser
  qualquer um".
- **`SH [<endereço>],'<texto>`** — busca um texto (2+ caracteres, um apóstrofo antes, sem precisar
  fechar com outro) testando automaticamente TODOS os deslocamentos possíveis (`-7F` a `80`, mesma faixa
  do `DM`/`ZAP`) — acha tanto texto puro (deslocamento `+00`) quanto texto "cifrado" por um deslocamento
  fixo, truque comum em jogos antigos pra não deixar diálogo legível num editor de disco cru.
- **`<endereço>` omitido** continua a busca a partir do último endereço ACHADO + 1 — só funciona depois
  de uma busca bem-sucedida nesta mesma sessão da janela do Mamute Assembler.
- Busca varre a memória inteira (64KB) com volta ao início se necessário, uma passada completa no
  máximo.
- **Sem janela** — diferente do `DM`/`ZAP`/`SCR`, `SH` só mostra o resultado no próprio log do `MON>`:
  `ACHADO EM <endereço>` (bytes), `ACHADO EM <endereço> DESLOC <deslocamento>` (texto), ou
  `NAO ENCONTRADO`.

### Bastidores

- Busca por texto otimizada pra não ser O(64K × 256 deslocamentos × tamanho do texto): o deslocamento é
  calculado uma vez a partir do 1º caractere candidato (`Offset = Alvo[0] - RawByte[0]`, normalizado pro
  intervalo `-7F..80`) e só depois os caracteres restantes são conferidos com ESSE deslocamento —
  O(64K × tamanho do texto), rápido mesmo varrendo a memória inteira.
- Nenhuma janela nova, nenhum arquivo novo — tudo em `MamuteGui_CmdSh()`
  (`editor/MamuteAssemblerGui.pbi`), reaproveitando `Mamute_ReadByte()`/`Mamute_Hex4()`/`Mamute_Hex2()`/
  `Mamute_IsHexString()`/`Mamute_ParseHexAddr()` já existentes. Dois campos novos em `MamuteGui_State`
  (`HasLastSh`/`LastShAddr`) guardam onde a última busca achou algo, pro `<endereço>` opcional continuar
  dali.
- **Verificado de ponta a ponta com dados reais**, não só revisão de código: string `TESTE` escrita em
  RAM via `DM` (bloco de texto, avança sozinho pelos endereços), depois encontrada pelo `SH` com endereço
  exato E continuando a busca (`SH ,'TESTE` deu a volta completa nos 64KB e reencontrou a mesma
  ocorrência, exercitando o wraparound); busca por bytes com curinga (`SH C000,54,,53,54`, byte do meio
  divergindo do valor real) confirmada batendo; busca sem alvo plausível (`SH C000,FF,FF,FF`) encontrou
  de verdade uma ocorrência legítima em dados de ROM ao dar a volta pelos 64KB — confirma o wraparound
  funcionando contra dado real, não um caso simulado/forçado.

---

## 7.33.21 — "MEMORIA DO MONITOR" (2026-08-12)

**Tema da versão**: histórico de comandos no `MON>` do Mamute Assembler, navegável com as setas e
persistido no arquivo de projeto — mais uma correção no `ProjectDB` que beneficia qualquer configuração
salva no projeto padrão (implícito, sem projeto salvo), não só o Mamute.

### Novidades

- **Setas Cima/Baixo no campo `MON>`** navegam pelo histórico de comandos já digitados (Cima = mais
  recente, Baixo = volta pro presente/campo vazio) — cursor sempre posicionado no fim do texto recuperado.
- **Histórico persistido no arquivo de projeto atual** (`ProjectDB::SetInfoValue`/`GetInfoValue`, chave
  `mamute_mon_history`) — se nenhum projeto estiver aberto, salva silenciosamente no projeto padrão
  implícito (`noname.msxproject`), sem pedir nada ao usuário. Recarregado toda vez que a janela do Mamute
  Assembler abre. Comandos repetidos consecutivos não duplicam entrada; limite de 200 comandos guardados.

### Bastidores

- **Achado real no `ProjectDB` (não é bug novo desta versão — já afetava outras telas)**:
  `ProjectDB::EnsureOpen()`, usado pelo projeto padrão implícito, chamava `OpenAt(..., CreateFileFirst=
  #True)` incondicionalmente — e `CreateFile()` do PureBasic trunca um arquivo existente em vez de só
  criar quando ele falta. Resultado: o projeto padrão era apagado toda vez que o editor abria e algo
  tocava `ProjectDB` pela primeira vez naquela sessão, mesmo com dado salvo numa sessão anterior — isso
  já afetava os 3 booleans de override de "Configurar → Projeto..." antes desta versão, não só o
  histórico novo do Mamute. Corrigido em `EnsureOpen()`: só chama `CreateFile()` se o arquivo do projeto
  padrão ainda não existir (`FileSize(TempPath) < 0`); se já existir, abre e reaproveita o conteúdo
  (`RunSchema()` só faz `CREATE TABLE IF NOT EXISTS`, nunca apaga dado). `Arquivo → Novo projeto...`
  continua sempre começando vazio de verdade — usa um caminho de código separado (`CreateNew()`), não
  afetado por essa mudança.
- Lista do histórico codificada como uma única string separada por `Chr(10)` dentro de `project_info`,
  mesmo idioma já usado por `StoreAsmSubProject`/`FetchAsmSubProject` pras listas de arquivos `.asm`/`.lib`
  de um subprojeto — nenhuma tabela nova precisou ser criada.
- **Verificado de ponta a ponta com dois processos reais em sequência**, não só revisão de código: um
  processo digitou `PAGE ?` e `PAGE`, com Cima/Cima/Baixo/Baixo confirmados navegando na ordem certa;
  processo encerrado e um processo novo aberto do zero — a primeira tecla Cima já recuperou `PAGE`
  corretamente, confirmando que o histórico sobreviveu a um reinício completo do aplicativo (o cenário
  que estava quebrado antes da correção do `ProjectDB`).

---

## 7.33.20 — "OLHO NA ROM" (2026-08-12)

**Tema da versão**: **`SCR`**, o comando mais complexo do Mamute Assembler até agora — display gráfico
da memória numa tela fixa estilo SCREEN 2 do MSX, mais o pré-requisito que faltava pra ele fazer
sentido: carregar de verdade o conteúdo dos arquivos ROM/BASIC configurados.

### Novidades

- **`Mamute_LoadPhysicalMemory()`** (`editor/MamuteSupport.pbi`) — até esta versão, `MamuteMem()` ficava
  sempre em branco mesmo com ROM/BASIC configurados em `Configurar → Mamute Assembler...`; agora lê os
  arquivos de verdade pro bloco certo (respeitando o `FileOffset` da divisão BIOS+BASIC de 32KB), toda
  vez que a janela do Mamute Assembler abre.
- **`SCR <endinic>,<dx>,<dy>[,<modo>]`** — mostra uma **tela FIXA de 256x192 pixels** (32x24 caracteres
  8x8, a mesma resolução de um SCREEN 2/1 real do MSX) preenchida a partir de `endinic`. `<dx>`/`<dy>`
  não mudam o tamanho da tela — definem um "azulejo" de `dx`×`dy` caracteres que ladrilha a tela inteira;
  `<modo>` decide se os blocos de 8 bytes dentro de cada azulejo são lidos horizontal (`0`, padrão) ou
  verticalmente (`1`, a mesma ordem real de armazenamento de sprites do MSX).
- Uma **moldura de tamanho fixo — sempre 2x2 caracteres (16x16 pixels), sempre no canto superior
  esquerdo da tela** — é o cursor de edição. `TAB` liga/desliga seu contorno; `ENTER` amplia exatamente
  esses 16x16 pixels num painel à parte, ao lado da tela normal, pra edição fina pixel a pixel.
- Teclas remapeadas a pedido explícito do usuário em relação ao manual original do MegaAssembler: `ESC`
  encerra, `E` mostra/oculta o endereço atual. Fora de edição, setas esquerda/direita rolam o endereço
  base em ±1 byte e cima/baixo em ±1 azulejo inteiro (`dx`×`dy`×8 bytes) — é assim que se traz outro
  pedaço da memória pra dentro da moldura fixa. Em edição, setas movem o cursor de pixel dentro da
  moldura; `ESPAÇO` inverte o ponto sob o cursor; `I`/`L` invertem/apagam os 16x16 pixels da moldura
  inteira de uma vez; `ESC` em edição cancela e restaura um snapshot tirado ao entrar. Botão na tela pra
  cada ação, mesmo espírito do `DM`/`ZAP`.
- **Se a moldura cair sobre ROM/BASIC/Vazio** (não RAM) — pedido explícito do usuário, refinado ainda
  dentro desta versão: o painel de edição mostra o conteúdo real normalmente ("às vezes ampliamos pra
  ver algum detalhe da tela, não pra editar propriamente dito") e todas as teclas de edição respondem ao
  toque, mas nada é gravado de verdade (`Mamute_CanWriteAt()` já recusa a escrita, mesma regra do `DM` —
  o pixel só volta a mostrar o mesmo valor real no repaint seguinte), com um aviso amarelo "ROM - somente
  leitura (alterações não são gravadas)" abaixo da tela. Modificar ROM de verdade fica pra uma sessão
  futura.

### Bastidores

- **Primeira versão implementada estava com o modelo errado** — tratava `<dx>`×`<dy>` como o tamanho da
  própria tela (uma grade que crescia/encolhia com os parâmetros) e a "moldura 2x2" como 2x2 *pixels*
  ancorados num cursor livre, não 2x2 *caracteres* fixos. O usuário testou, apontou a diferença ("o
  original mostra uma tela gráfica 256x192... e um cursor 16x16 em azul") e anexou duas capturas de tela
  reais do MegaAssembler original rodando num emulador (`images/msxbasica-17.png`/`-18.png`), que
  resolveram a ambiguidade que o manual original tinha deixado em aberto. Modelo corrigido na mesma
  sessão, ainda dentro da `7.33.20` — ver acima a descrição já corrigida.
- **Achado real de PureBasic**: nomear um parâmetro de macro `DX`/`DY` colide (PureBasic é
  case-insensitive) com os campos `State\Dx`/`State\Dy` — a substituição textual da macro trocava o
  `Dx`/`Dy` DENTRO de `State\Dx`/`State\Dy` também, virando `State\-1 * State\0` (visto direto no
  `Macro.out` do compilador). Resolvido renomeando os parâmetros pra `MoveX`/`MoveY`.
- **Outro achado real**: `Campo = Not Campo` (atribuição direta do resultado de `Not` a um campo de
  estrutura) não compila sob `EnableExplicit` (“variables have to be declared: Not”) — resolvido
  envolvendo em `Bool()`: `Campo = Bool(Not Campo)`.
- **Verificado de ponta a ponta com dados reais**, não só por revisão de código: `SCR 1BBF,1,1` batendo
  visualmente com a captura de tela real do produto original (moldura no canto certo, tabela ASCII da
  ROM `cbios_main_msx1.rom` no topo, "ruído" de dados não-fonte preenchendo o resto da tela); `ENTER`
  sobre a configuração real do usuário (Slot 0/Página 0 = ROM) mostrou corretamente "ROM - somente
  leitura"; escrita testada num endereço RAM real (`SCR C000,1,1` + `ESPAÇO`) acendeu o pixel certo no
  painel de edição.
- **Duas pistas falsas no caminho, ambas descartadas com evidência, não suposição**: (1) a configuração
  física real do usuário tinha o Slot 0/Página 0 (posição da BIOS) apontando pro `cbios_logo_msx1.rom`
  (ROM só do logo de boot do C-BIOS, sem tabela de fontes) em vez do `cbios_main_msx1.rom` — o resultado
  em branco era correto para aquele arquivo específico, não um bug. (2) mesmo trocando pro arquivo
  certo, um segundo teste continuou em branco — a causa real era o executável de teste descartável ter
  sido compilado fora de `editor/` (`ProgramFilename()` não achava o `mamute_settings.json` real do
  usuário ali, caindo na configuração padrão vazia); recompilado dentro de `editor/`, os dados reais
  apareceram. Nenhuma das duas pistas era um bug no `SCR` ou no carregamento de ROM.

---

## 7.33.19 — "SETOR ZERO" (2026-08-11)

**Tema da versão**: **`ZAP`**, o segundo comando do Mamute Assembler que lê/escreve dados de verdade —
"muito parecido com o `DM`", pedido explícito do usuário, mas em vez da memória simulada do MSX, edita
**setores de uma imagem de disco (.dsk)** direto, sem passar pela estrutura FAT12.

### Novidades

- **`ZAP <setor inicial>[,<deslocamento>]`** — pede um arquivo `.dsk` (janela normal de escolher
  arquivo) e abre a mesma grade do `DM` (128 bytes, 16 linhas de 8, hexa+ASCII) a partir do setor
  informado (hexa — sector 0 = boot sector). `<deslocamento>` idêntico ao do `DM`. Prioridade pra
  disquetes de **720KB**, mas 360KB/180KB também funcionam — o ZAP não interpreta a estrutura FAT12,
  só lê/escreve bytes crus por posição, igual um editor de setor de verdade da época.
- Mesma navegação do `DM` (mouse/teclado/setas/`TAB`/`PgUp`/`PgDn`/`+`/`-`) — a diferença visível é o
  rótulo de cada linha (deslocamento dentro do setor, `000`-`1F8`) e as linhas de status (`Setor:`/
  `Byte:` em vez de `Endereço:`).
- **Diferença chave em relação ao `DM`**: editar um byte só muda a memória — grava no arquivo `.dsk`
  de verdade só quando você aperta **`Ctrl+S`** ou clica o botão amarelo **"SALVAR SETOR"** (pedido
  explícito do usuário: "escolha uma tecla para salvar o setor no disco"). Só o setor sob o cursor é
  gravado (cirúrgico, não o disco inteiro). O título da janela ganha um `*` enquanto há alterações não
  salvas; fechar nesse estado pede confirmação antes de descartar.

### Bastidores

- `editor/MamuteZapGui.pbi` (novo arquivo) — adaptação quase literal de `MamuteDumpGui.pbi`: mesma
  técnica de desenho/hit-test/edição em 2 estágios, só trocando a "fonte de dados" (`MamuteMem()` via
  slot/página → um buffer `Global Dim MamuteZapDisk.a()` carregado do arquivo escolhido) e adicionando
  o mecanismo de salvar. Sem conceito de "só RAM é editável" aqui — qualquer byte do disco pode ser
  editado (diferente do `DM`, onde ROM/BASIC são somente-leitura).
- `MamuteZap_SaveSector()` grava exatamente 512 bytes no offset do setor via `FileSeek`+`WriteData` —
  não reescreve o disco inteiro a cada edição.
- **Achado real de automação de UI, corrigindo uma suposição anterior**: numa sessão passada (divisão
  de arquivo BIOS+BASIC de 32KB), descartei automatizar o `OpenFileRequester` nativo do Windows por
  achar o Common Item Dialog (Vista+) sem IDs de controle simples. Testando o `ZAP` de verdade, o
  diálogo **respondeu normalmente** ao clássico `GetDlgItem(hDlg, 1148)` (campo de nome de arquivo) +
  `GetDlgItem(hDlg, 1)` (botão OK) + `BM_CLICK` — a suposição anterior era prematura, não confirmada
  meticulosamente antes de descartar a técnica. Guardado pra próxima vez que precisar automatizar um
  seletor de arquivo nesta IDE.
- **Verificado de ponta a ponta, de verdade** (não só por revisão de código desta vez): criado um disco
  de teste real via `BadigEditor.exe --diskmanipulator create` (720KB), aberto no `ZAP` via automação
  completa do diálogo de arquivo (técnica acima), cursor movido, um byte editado pra `5A` via o campo
  de edição, `Ctrl+S` disparado — e o arquivo `.dsk` real no disco **lido de volta de forma
  independente** (fora do app) confirmou o byte gravado no offset certo. Título da janela perdeu o `*`
  após salvar, confirmando o flag de alterações pendentes também funciona.

---

## 7.33.18 — "MEMORIA VIVA" (2026-08-11)

**Tema da versão**: o primeiro comando do Mamute Assembler que realmente lê e escreve na memória
simulada — **`DM`** (Despejo de Memória), pedido em detalhe pelo usuário. Até aqui `PAGE` só arrumava
o mapeamento; `DM` é quem de fato mostra e edita os 256KB simulados por trás dele.

### Novidades

- **`DM <endereço>[,<deslocamento>]`** — abre uma janela nova mostrando 128 bytes (16 linhas de 8) em
  hexa + ASCII lado a lado, a partir do endereço informado (hexadecimal — **agora o padrão de entrada
  em qualquer comando do Mamute Assembler**, pedido explícito do usuário). `<deslocamento>` opcional
  (também hexa, com sinal, `-7F` a `80`) "criptografa/descriptografa" só a interpretação ASCII exibida
  (byte cru + deslocamento, módulo 256) — o bloco hexa sempre mostra o byte cru.
- Cursor navegável por **mouse** (clique direto numa célula, ou nas 4 setas pequenas na tela) e por
  **teclado** (setas, ou `TAB` pra alternar entre o bloco hexa e o bloco texto). Duas setas maiores
  (`<<`/`>>`, ou `PgUp`/`PgDn`) pulam ±128 bytes no endereço base. Botões `+`/`-` ajustam o deslocamento.
- **`RETURN`** abre um campo de edição pro bloco ativo; **`RETURN`** de novo confirma. No bloco hexa,
  digite 1-2 dígitos e vira o byte cru sob o cursor. No bloco texto, digite um texto — cada caractere
  vira um byte (revertendo o deslocamento), escritos a partir do cursor, que avança sozinho. **`ESC`**
  cancela a edição em andamento, ou fecha a janela do DM se não havia edição.
- Escrita só tem efeito em células mapeadas como **RAM** agora (`PAGE`) — ROM/BASIC/Vazio continuam
  somente-leitura, igual hardware real.

### Bastidores

- `MamuteSupport.pbi` ganhou o elo que faltava entre endereço de CPU e a memória simulada:
  `Mamute_ResolveAddress()` (endereço → Slot/Página/Offset via `MamutePageMap()`, o mapeamento ativo do
  `PAGE`), `Mamute_ReadByte()`/`Mamute_WriteByte()` (esta última recusa silenciosamente se a célula
  mapeada não for RAM), mais parsers hexadecimais (`Mamute_ParseHexAddr`/`Mamute_ParseHexOffset`, a
  última já validando a faixa `-7F`/`80`).
- `editor/MamuteDumpGui.pbi` (novo arquivo): grade desenhada num `CanvasGadget` próprio, técnica de
  desenho/hit-test-por-clique adaptada de `HexEditorGui.pbi` (8 bytes/linha em vez de 16, sem scroll —
  os 128 bytes cabem inteiros de uma vez). Cursor via `Box()` cheio + texto em preto sobre verde
  ("video reverso"), não um `Box()` vazado como no Editor Hexa. Navegação por teclado (ausente no Editor
  Hexa) via `AddKeyboardShortcut()` no nível da janela — mesmo mecanismo já comprovado pro Enter do
  prompt `MON>`, só que com mais teclas (setas/PgUp/PgDn/Tab/Return/Esc/+/-). Edição em 2 estágios
  (Return abre um `StringGadget` normalmente oculto pré-preenchido com o valor atual, Return de novo
  confirma) em vez de digitação direta no canvas — evita depender da API de teclado do `CanvasGadget`
  (incerta) e reaproveita a mesma entrada de texto nativa já usada em todo o resto do projeto.
- Reaproveita a fonte configurável em `Configurar → Mamute Assembler...` (não fixa outra fonte à toa).
- **Achado real de PureBasic**: uma `Macro` expandida em mais de um ponto do mesmo `Procedure` não pode
  ter um `Protected` próprio dentro dela (cada expansão gera outra declaração do MESMO nome, que o
  compilador rejeita) — `MamuteDump_DoOffset` (chamada de 4 lugares: 2 botões + 2 atalhos de teclado)
  precisou ter sua variável (`NewOff`) içada pra fora, declarada uma vez só no `Procedure` pai.
- **Verificado de ponta a ponta**, sem simulação de teclado real: build `/CONSOLE` descartável, `DM
  8000` digitado via `WM_SETTEXT` no prompt, depois `PostMessage(WM_COMMAND)` nos IDs dos atalhos de
  teclado (mover cursor, `TAB`, paginar, ajustar deslocamento, abrir/confirmar edição) — confirmado por
  captura de tela em cada passo: cursor se move certo, paginação soma/subtrai 128 certo, deslocamento
  atualiza o rótulo, e o teste decisivo — editar o byte sob o cursor pra `42` com deslocamento `+05`
  mostrou `42` no hexa e **`G`** no texto (0x42+5=0x47='G'), confirmando a "criptografia" ASCII
  funcionando e a escrita batendo com a configuração de RAM real do usuário (endereço testado caía numa
  célula RAM de verdade). Cliques do mouse nos botões/grade não foram automatizados (usam a mesma lógica
  interna dos atalhos de teclado já testados, risco considerado baixo).

---

## 7.33.17 — "TERMINAL PRE-HISTORICO" (2026-08-11)

**Tema da versão**: `Configurar → Mamute Assembler...` agora reconhece arquivos de BIOS+BASIC
combinados de 32KB - comum em ROMs reais de MSX - e divide automaticamente entre as duas páginas certas.

### Novidades

- Ao escolher um arquivo de **32KB** pra uma célula **ROM na Página 0** (a posição convencional da
  BIOS), a tela pergunta se é BIOS+BASIC combinados. Respondendo **Sim**: a Página 0 (deste mesmo slot)
  fica com os primeiros 16KB do arquivo (BIOS) e a Página 1 fica com os últimos 16KB (BASIC, tipo
  ajustado automaticamente) — o mesmo arquivo repetido nos dois pontos, cada um lendo a metade certa.
  Respondendo **Não**, ou escolhendo um arquivo de outro tamanho, funciona como antes (só a célula
  selecionada recebe o arquivo). O usuário continua livre pra trocar o arquivo da Página 1 na mão depois,
  mesmo após o "Sim" preencher automaticamente.
- A coluna Arquivo da lista mostra **"(últimos 16KB)"** ao lado do caminho quando a célula usa a
  segunda metade de um arquivo compartilhado, pra deixar claro de onde vem cada bloco.

### Bastidores

- `MamuteMemCell` (`MamuteSupport.pbi`) ganhou o campo `FileOffset` — deslocamento em bytes dentro do
  arquivo de onde começam os 16KB desta célula (0 normalmente, 16384 pra metade final de um arquivo
  combinado), persistido no `mamute_settings.json` junto com Tipo/Arquivo. Prepara o terreno pro
  carregamento de arquivo de verdade (ainda pendente) já saber ler o pedaço certo de cada arquivo.
- Verificado: `build.ps1` compilou limpo; a tela reaberta com a configuração real já salva pelo usuário
  não regrediu visualmente. O fluxo completo (escolher um arquivo de 32KB de verdade → confirmar no
  diálogo → ver as duas linhas preenchidas) **não foi automatizado** nesta sessão — o seletor de
  arquivo nativo do Windows (tema Vista+/Common Item Dialog) não expõe IDs de controle simples como os
  diálogos antigos, tornando a automação por mensagem pouco confiável; ficou verificado por revisão de
  código (mesmo padrão já comprovado de atualização de `WorkCells()`/`MamuteSettings_RefreshRow()` usado
  pelas outras edições da tela).

---

## 7.33.16 — "TERMINAL PRE-HISTORICO" (2026-08-11)

**Tema da versão**: pequeno ajuste de legibilidade — a fonte fixa do Mamute Assembler (Consolas 14pt
negrito) virou configurável em `Configurar → Mamute Assembler...`.

### Novidades

- **Configurar → Mamute Assembler...** ganhou uma seção "Fonte do terminal": combo de fonte (mesma
  enumeração de fontes monoespaçadas já usada em `Configurar → Editor...`, `EditorCfg_EnumMonospaceFonts()`),
  campo de tamanho e checkbox "Negrito". Persistido no mesmo `mamute_settings.json`.

### Bastidores

- `MamuteGui_EnsureFont()` deixou de carregar uma fonte fixa uma única vez — agora recarrega a partir de
  `MamuteFontName`/`MamuteFontSize`/`MamuteFontBold` (`MamuteSupport.pbi`) toda vez que a janela do
  monitor abre, liberando a fonte anterior antes (`FreeFont()`) pra não vazar um `HFONT` a cada abertura.
  Trocar a fonte em `Configurar → Mamute Assembler...` só tem efeito na próxima vez que o monitor abrir.
- Verificado com build `/CONSOLE` descartável + captura de tela: combo populado com fontes reais do
  sistema, valores mostrados batendo com a configuração já salva pelo usuário (incluindo a configuração
  de slots real que ele já tinha feito — ROM/BASIC no Slot 0, RAM no Slot 3 — confirmando de quebra que
  o `PAGE` "estado de boot" calcula certo contra dados reais, não só contra a config vazia testada antes).

---

## 7.33.15 — "TERMINAL PRE-HISTORICO" (2026-08-11)

**Tema da versão**: uma ferramenta nova, pedida do zero pelo usuário e construída em duas partes na
mesma sessão — **Mamute Assembler** (`Executar → Mamute Assembler...`), uma janela "monitor" inspirada
nos montadores de linha de comando dos computadores de 8 bits dos anos 80 (referência direta: o
**MegaAssembler** do próprio usuário). Primeiro só a casca (prompt + um comando); depois, uma simulação
de verdade do **sistema de slots do MSX** por baixo dela.

### Novidades

- **Executar → Mamute Assembler...** — janela "terminal" (fundo preto, texto monoespaçado verde e
  **negrito**, fora do tema claro do resto da IDE de propósito) com um prompt `MON>`.
- **`BA` / `QUIT`** — encerra a janela (não diferencia maiúsculas/minúsculas), equivalente a fechar pelo X.
- **`PAGE`** — simula o mapeamento de slots do MSX de verdade: 4 slots (0-3), cada um com 4 páginas de
  16KB (`0000-3FFF`/`4000-7FFF`/`8000-BFFF`/`C000-FFFF`, os mesmos endereços do hardware real).
  `PAGE` sozinho coloca as 4 páginas no slot marcado como RAM; `PAGE ?` mostra o mapeamento ativo sem
  mudar nada; `PAGE X,Y,Z,W` troca o slot comutado em cada uma das 4 páginas de uma vez.
- **Configurar → Mamute Assembler...** — configura o que existe fisicamente em cada um dos 16 blocos de
  memória (Vazio/RAM/ROM/BASIC + arquivo pra ROM/BASIC, ex.: uma BIOS real) — lista de 16 linhas
  (slot × página), editando tipo/arquivo da linha selecionada. Persistido em `mamute_settings.json`.
- **Ajuda → Mamute Assembler...** — manual da ferramenta, mesmo layout de árvore + busca + conteúdo das
  outras janelas de Ajuda, com um tópico por comando já portado (`BA`/`QUIT` e `PAGE`).

### Bastidores

- `editor/MamuteAssemblerGui.pbi`: `EditorGadget` somente-leitura como scrollback + `StringGadget` de
  entrada, Enter submete via `AddKeyboardShortcut` — mesmo idioma já comprovado em
  `OpenMSXConsoleGui.pbi`. `MamuteGui_Dispatch()` isola os comandos num `Select` só, ponto de extensão
  único pras próximas sessões — cresceu de "só o verbo" pra "verbo + argumentos crus" pra acomodar `PAGE`.
- Achado real: `App_StyleChildCallback` (`BadigEditor.pb`) força a fonte Segoe UI em todo controle
  nativo de qualquer janela no primeiro repaint dela, sem opção de desligar por janela — a fonte
  monoespaçada (Consolas, agora 14pt negrito) é reaplicada de novo logo antes do loop de eventos pra
  garantir que vence essa corrida.
- `editor/MamuteSupport.pbi` (novo): modelo de memória (`MamuteMem()`, 4×4×16KB, `Dim` zera sozinho) +
  configuração física por célula (`MamuteCfgCell()`) + mapeamento ativo (`MamutePageMap()`) - conceitos
  deliberadamente separados, igual o registrador de slot primário de um MSX real vs. o que fisicamente
  está ligado em cada slot. `Mamute_ResetPageMapToDefault()` calcula o "estado de boot" a partir da
  configuração (ROM/BASIC ganham de RAM se colidirem na mesma página; página sem nada configurado cai no
  slot 0).
- **Achado de sintaxe do PureBasic**: `NewMap` não pode ser usado como nome de variável comum (mesmo
  para um array `Dim`) — é a mesma palavra reservada do comando `NewMap` (declarar `Map`) e o compilador
  tenta interpretar como tal, com uma mensagem de erro enganosa ("A map name needs to start with a
  character"). Renomeado pra `ParsedSlots`.
- Conteúdo de `Ajuda → Mamute Assembler...` é escrito à mão (`MamuteHelp_Add()`), ao contrário do
  `Ajuda → asMSX...` (convertido de um manual externo) — o Mamute Assembler é uma ferramenta nova desta
  IDE, sem documento de origem pra converter.
- Verificado com build `/CONSOLE` descartável + captura real de tela de todas as janelas. O comando
  `PAGE` foi testado de ponta a ponta **sem simulação de teclado real** (a diretriz do projeto evita
  isso): texto injetado direto no `StringGadget` via `WM_SETTEXT` (achado por classe `Edit`/altura entre
  os filhos da janela) + `PostMessage(WM_COMMAND)` no ID do atalho Enter - confirmou `PAGE 2,2,2,2`
  aplicando corretamente, `PAGE 9,9,9,9` rejeitado (`?ERRO DE SINTAXE`, fora de 0-3) e `XYZ` rejeitado
  (`?COMANDO INVALIDO`). A tela `Configurar → Mamute Assembler...` foi verificada só visualmente (16
  linhas/colunas corretas) - a seleção de linha da lista não foi automatizada de propósito
  (`LVM_SETITEMSTATE` via `SendMessage` é um dos casos que a diretriz do projeto marca como podendo
  travar/crashar o processo alvo).

---

## 7.33.13 — "TRIPLA MONTAGEM" (2026-08-11)

**Tema da versão**: terceiro assembler Z80 suportado pela IDE — **asMSX**
([github.com/Fubukimaru/asMSX](https://github.com/Fubukimaru/asMSX)), ao lado do assembler nativo
(`Z80Asm.pbi`) e do N80/Nestor80 externo. Pedido explícito do usuário, em duas partes na mesma sessão:
primeiro configuração + download + Ajuda + template de arquivo novo (mesmo padrão já usado pro N80/
MSXBas2Rom), depois um botão de verdade pra montar chamando o executável.

### Novidades

- **Configurar → asMSX...** — caminho do executável (editável + "..." pra apontar pra uma instalação já
  existente) e botão "Baixar versão mais recente" (release oficial do GitHub, executável avulso por SO/
  arquitetura, sem precisar descompactar zip nenhum). Mais as opções de linha de comando usadas ao
  montar: sintaxe Zilog padrão (`-z`), modo silencioso (`-s`), modo verboso (`-vv`) e caminho/prefixo de
  saída (`-o`).
- **Ajuda → asMSX...** — o manual oficial (`asmsx.md`) navegável/pesquisável, mesmo padrão de árvore +
  busca + conteúdo das outras janelas de Ajuda, com título/negrito/código/blocos de código formatados.
- **Arquivo → Novo asMSX...** — cria um `.asm` já com cabeçalho de comentário e as diretivas `.BASIC`/
  `.ORG` mais pertinentes pra um programa MSX típico carregável via `BLOAD"...",R`, mais uma nota sobre a
  diferença de sintaxe mais visível do asMSX (colchetes `[ ]` em vez de parênteses pra endereçamento
  indireto).
- **Executar → Montar Fonte asMSX...** — monta a aba `.asm` ativa chamando o executável de verdade
  (salva num arquivo real primeiro, já que o asMSX só assembla arquivo em disco), mostrando a saída do
  programa ao final. Ao contrário do MSXBas2Rom, o tipo do arquivo gerado (`.rom`/`.bin`/`.com`/etc.) vem
  de diretivas dentro do próprio fonte, não de uma opção da IDE.
- **Configurar → Projeto...** ganhou uma 4ª aba, "asMSX" — configuração específica de um projeto (caminho
  + opções), mesmo padrão já usado pro Basic Dignified/N80/MSXBas2Rom.

### Bastidores

- Diferente do N80 (3 programas, precisa varrer o histórico de releases) e do MSXBas2Rom (asset `.zip`),
  o asMSX publica **um único executável avulso por SO/arquitetura** em `releases/latest` — novo helper
  `ExtTool_DownloadFile()` (`ExternalToolDownload.pbi`), mais simples que `ExtTool_DownloadAndExtractZip()`,
  com `chmod +x` explícito fora do Windows (o asset baixado não é um zip, então não há permissão nenhuma
  pra preservar).
- O manual do asMSX já é Markdown real e limpo, sem nenhum link interno — ao contrário do Livro Vermelho/
  MSX2 Technical Handbook (módulo 30), não precisou de nenhuma infraestrutura de âncora/link: a janela de
  Ajuda reaproveita o renderizador genérico (`GenMdHelp_RenderMarkdown()`) direto, sem parser próprio.
  Conteúdo baked em `AsmsxHelpData.pbi` em tempo de compilação (script descartável `convert_asmsx.py`),
  não baixado em tempo de execução — a cópia local do repositório do asMSX é só referência de build,
  gitignored, igual `badig/`/`nestor80/`.
- `AssembleAsmsxFromActiveTab()` não distingue se a aba `.asm` ativa nasceu de "Novo Assembly" ou "Novo
  asMSX..." — `Docs()\Mode` não carrega essa informação, e não precisa: o asMSX só vê texto de assembly,
  tanto faz de qual dos dois menus a aba veio.
- Verificado com um build `/CONSOLE` descartável + `PostMessage(WM_COMMAND)` pelos IDs de menu + captura
  real de tela (nenhuma janela foi considerada pronta só por compilar) — inclusive o caminho de erro
  ("configure o executável primeiro"). A 4ª aba de `Configurar → Projeto...` reaproveita infraestrutura
  já usada pelas outras 3 sem alteração, não verificada visualmente nesta sessão (exige projeto salvo).

---

## 7.33.11 — "ACERVO VIVO" (2026-08-10)

**Tema da versão**: o menu Ajuda ganhou uma base de conhecimento MSX inteira — sete janelas novas,
~3300 tópicos, extraídos automaticamente dos 3 arquivos CHM do emulador RuMSX encontrados no
repositório (`help/*.CHM`) mais duas referências externas clássicas ("The MSX Red Book" e o MSX2
Technical Handbook), com links internos e figuras originais **clicáveis de verdade** nas duas últimas.

### Novidades

- **Ajuda → Manuais MSX...** — MSX-DOS 2, Z80/R800, Turbo-Basic Compiler, FM-PAC e a transcrição
  original de 1997 do MSX2 Technical Handbook, extraídos de `help/MANUALS.CHM`.
- **Ajuda → MSX-Basic/DOS/CP-M (RuMSX)...** — 359 comandos de `help/SOFTWARE.CHM`; segunda fonte de
  referência MSX-BASIC em paralelo com "Ajuda → MSX BASIC..." (livro brasileiro).
- **Ajuda → BIOS MSX: Chamadas/Hardware/Documentação (RuMSX)...** — três janelas, `help/MSXBIOS.CHM`;
  597 rotinas de BIOS individuais, uma por endereço/nome.
- **Ajuda → Livro Vermelho...** — "The MSX Red Book" (1985) completo, 973 tópicos, com as ~2911
  referências cruzadas do livro clicáveis de verdade (hotspot nativo do Scintilla) e as 53 figuras
  originais num popup.
- **Ajuda → MSX2 Technical Handbook...** — edição Markdown de Konamiman, 1356 tópicos, mesmos links e
  84 figuras clicáveis do Livro Vermelho.

### Bastidores

- Dois estilos de renderizador por tipo de conteúdo: monoespaçado/sem quebra automática pra texto
  pré-formatado (tabela ASCII, diagrama de bits); proporcional com negrito/código/link pra prosa.
- Cada `*HelpData.pbi` monta o corpo linha a linha (`Begin()`/`L()`/`Commit()`) em vez de uma
  expressão gigante `"l1" + #CRLF$ + "l2" + ...` — `pbcompiler.exe` tem um limite de "continuation
  lines" que os documentos maiores estouravam.
- Achado de compilador: bytes de controle crus (`Chr(1)` etc.) dentro de um literal de string
  quebram o `pbcompiler.exe` ("Literal string not terminated") mesmo com a string bem formada —
  sentinelas de link/código trocadas por ASCII imprimível (`"[[["`/`"|||"`/`"]]]"`/`"@@@"`).
- 3 bugs reais corrigidos durante testes ao vivo (nenhuma janela considerada pronta sem abrir de
  verdade): heurística de endereço confundindo rótulo de bit (`b7`) com endereço de rotina;
  indentação de item de lista aninhado do Livro Vermelho tratada como bloco de código; título
  duplicado na tela nas janelas monoespaçadas.
- Decisão de direitos autorais sobre o conteúdo reproduzido (documentos antigos amplamente
  disponíveis + conteúdo do próprio RuMSX) avaliada explicitamente com o usuário antes de
  implementar — detalhe completo em `docs/SPEC.md`, módulo 30.
- Versão do PureBasic usada no projeto atualizada na documentação para **6.41**.

---

## 7.33.10 — "ADEUS ESCURIDÃO" (2026-08-10)

**Tema da versão**: usuário pediu pra atacar o visual datado da IDE sem entrar numa reforma grande
(reescrita de UI, framework novo, etc.) — o pior ponto era os temas escuros, onde os controles nativos
que os botões tematizados não alcançam (combo/checkbox/lista/scrollbar) ficavam com contraste ruim
contra fundo escuro. Três mudanças pequenas e de baixo risco, todas reaproveitando infraestrutura que
já existia, em vez de uma reforma de interface.

### Novidades

- **Só temas claros**: os 5 temas escuros (Grafite/Azul Profundo/Rosé/Carmesim/Floresta) foram
  removidos. Dois temas claros novos — **Neblina** (azulado, frio) e **Linho** (lilás) — entraram ao
  lado dos 2 originais (Neve/Bege), mantendo 4 opções em **Configurar → Editor...**. Neve é o novo
  padrão.
- **Ícones de botão ligados por padrão**: uma Nerd Font só-de-ícones
  (`editor/fonts/SymbolsNerdFontMono-Regular.ttf`, licença SIL OFL) passou a ser empacotada junto do
  executável e carregada automaticamente na inicialização — os 311 botões tematizados da IDE que já
  sabiam mostrar ícone (infraestrutura da v7.31.3) deixam de depender de o usuário achar e configurar
  manualmente uma fonte. O combo **Fonte de ícones** ganhou a opção **"(Padrão - ícones embutidos)"**;
  ainda dá pra desligar (**"(Nenhuma - usa texto)"**) ou trocar por outra Nerd Font instalada.
- **Manifesto `/XP` no build**: `build.ps1` agora compila com a flag `/XP` do `pbcompiler.exe`
  (dependência do `comctl32` v6) — os controles nativos não-tematizáveis citados acima passam a usar o
  visual moderno do Windows em vez do estilo antigo sem tema, em qualquer tema da IDE.

### Bastidores

- `editor_settings.json` de instalações anteriores migra sozinho: cada tema escuro removido mapeia
  pro claro de "família" mais parecida (`Navy`→`Mist`, `Rose`→`Linen`, `Crimson`/`Forest`→`Paper`,
  `Graphite`/legado→`Snow`) — ninguém reabre a IDE num tema que não existe mais.
  `EditorCfg_ThemeIsDark()` foi mantida (sempre retornando `#False`) em vez de excluída, já que 2
  arquivos ainda a chamam para decidir quando acionar as APIs de modo escuro nativo do Windows — sem
  tema escuro nenhum, esse código agora fica permanentemente inerte, o que é o comportamento correto.
- Novo campo `IconsEnabled` (booleano) na struct de configurações, separado de `IconFontName` — sem
  ele não dava pra distinguir "sem preferência salva" (usa a fonte embutida) de "usuário desligou de
  propósito", já que `IconFontName` vazio passou a significar "usa o padrão" em vez de "sem ícone".
  `EditorCfg_LoadCustomFonts()` foi fatorada em `EditorCfg_LoadFontsFromFolder()`, chamada duas vezes
  (pasta de fontes empacotada + pasta customizada do usuário) em vez de duplicar a varredura de
  diretório.
- **Investigado e descartado nesta rodada**: reescrever a apresentação em HTML/CSS/JS via
  `WebViewGadget()` nativo do PureBasic 6.10+ (`BindWebViewCallback()`/`WebViewExecuteScript()` pra
  IPC), ou separar o "motor" da IDE numa DLL consumida por uma GUI em outra linguagem (Go, Tauri,
  Electron). Tecnicamente viável e sem dependência de runtime além do WebView2 já presente no Windows
  11, mas um esforço grande (~40 arquivos `.pbi` de diálogo virariam HTML) pro ganho puramente visual
  perseguido aqui — descartado a favor das 3 mudanças acima.

---

## 7.33.9 — "CARTUCHO DE VERDADE" (2026-08-10)

**Tema da versão**: o `msxbas2rom` (compilador de terceiro que gera ROM de verdade a partir de
MSX-BASIC) deixou de ser só um executável baixado — agora faz parte do fluxo de trabalho de ponta a
ponta da IDE, e o projeto inteiro (com todos os fontes) ficou portátil entre máquinas.

### Novidades

- **Basic Dignified entende o dialeto do MSXBAS2ROM**: programas escritos com labels/`DEFINE`/`FUNC`/
  `RET` (em vez de BASIC clássico numerado) agora protegem o vocabulário exclusivo do compilador
  (`FILE`/`TEXT`, sub-comandos de `CMD`/`SET`/`GET`, `HEAP()`/`TILE()`/`TURBO()`...) contra o
  encurtamento automático de variáveis — antes, usar essas palavras como identificador corrompia o
  programa silenciosamente.
- **Executar → Compilar ROM (MSXBas2Rom)...**: gera o `.bas` e chama o `msxbas2rom.exe` de verdade,
  produzindo um `.rom` — antes só existia o downloader do executável, nenhum caminho de fato o usava.
- **Configurar → MSXBas2Rom...** ganhou uma tela completa de opções de compilação (modo ROM simples/
  MegaROM em 5 variantes, silencioso/debug, caminhos de entrada/saída, geração de símbolos de
  depuração, números de linha no binário, projeto VSCode) — espelhando 1:1 as opções reais do
  compilador.
- **Configurar → Projeto...**: Basic Dignified, N80 e MSXBas2Rom agora podem usar uma configuração
  própria de cada projeto em vez da global da máquina.
- **Projeto `.msxproject` portátil**: os fontes BASIC/Assembly são resincronizados automaticamente com
  o disco ao salvar o projeto e restaurados sozinhos ao abrir num local novo — leva só o arquivo de
  projeto de um PC pro outro e o código-fonte vai junto.
- **Ajuda → MSXBas2Rom...**: passou a incluir os exemplos oficiais do compilador (pasta `demo/`) e os
  10 jogos completos de `amaurycarvalho/msxbasic`, navegáveis com destaque de código de verdade, além
  da documentação da wiki oficial já baixada automaticamente. Destaque de sintaxe do dialeto ganhou uma
  cor própria, em vez de reaproveitar as cores do MSX-BASIC clássico.

### Bastidores

- O motor Dignified (`DignifiedPreprocessor.pbi`) ganhou um **modo**, não um segundo parser — evita
  duplicar ~2500 linhas testadas de labels/loops/`INCLUDE`/remtags que teriam que evoluir em paralelo.
- As 3 telas de configuração (Basic Dignified/N80/MSXBas2Rom) não mudaram de conteúdo pra virar
  "por projeto" — só ganharam um caminho de arquivo alternativo, reaproveitado tanto pela tela global
  quanto pela nova tela de projeto.

---

## 7.33.1 — "PENTE FINO" (2026-08-09)

**Tema da versão**: usuário pediu uma revisão geral do programa — bugs, unidade dos módulos,
performance e integração. Sete auditorias paralelas (uma por área do código: pipeline/tokenizer,
toolchain Z80, shell principal, editores gráficos, editores de tela texto, áudio/tracker, settings/
integrações externas) levantaram uma lista de achados; esta versão fecha os que valiam a pena corrigir
nesta rodada.

### Novidades

- **Helper de janela compartilhado** (`OpenModelessChildWindow`/`CloseModelessChildWindow`,
  `BadigEditor.pb`) — a mesma sequência de abrir/fechar diálogo (cor de fundo, ícone, desabilitar
  janela principal) que se repetia em ~30 arquivos virou duas chamadas, migrado em 35 arquivos.
- **Modo escuro nativo do Windows, de verdade** — barra de título, campos de texto/lista e agora
  também rótulos (`TextGadget`) seguem o tema escolhido nos 5 temas escuros (Graphite/Navy/Rose/
  Crimson/Forest); antes disso o mecanismo existia mas nunca acionava, ver "Bastidores".

### Bugs corrigidos nesta versão

- Fechar uma aba **não-ativa** (pelo próprio "x") trocava o documento visível pra aba errada.
- Vazamento de handles GDI (ícones de toolbar nunca liberados) em `CharsetEditorGui.pbi`,
  `GraphosScreenGui.pbi` e `AquarelaCharsetEditorGui.pbi`.
- `ProjectDB::SaveAs` podia abandonar o projeto do usuário silenciosamente se copiar o arquivo desse
  certo mas reabrir o banco no novo local falhasse.
- `MSXDisk::ExtractFile` reportava sucesso numa extração de disco truncada.
- Download de zip parcial (ZIP incompleto por queda de rede) não era apagado em `BadigSettings.pbi`/
  `FontDownloader.pbi`.
- Vazamento de buffer em `Z80Lib::CreateOrAddLibrary` quando uma entrada `.REL` posterior falhava a
  validação.
- Thread do pipe de comando do openMSX nunca fechada (`OpenMSXBridge.pbi`).
- Loop labels aninhados sem limite no pré-processador Dignified podiam corromper heap silenciosamente
  em vez de falhar limpo (`Dig_LoopStack`, `DignifiedPreprocessor.pbi`).
- **O achado maior**: 8 pontos comparando `EditorCfg\Theme = "Dark"` literalmente — valor legado que a
  própria migração pros 7 temas (`7.31.2`) já tornava inatingível — deixavam o modo escuro nativo do
  Windows sempre desligado, em qualquer tema.

### Documentação nova

- `CLAUDE.md` ganhou uma nota técnica sobre o bug do tema morto e a técnica `WM_CTLCOLORSTATIC`.
- `docs/SPEC.md`: nova entrada em "Próximos passos em aberto" com o resumo completo, incluindo o que
  foi adiado de propósito (unificação Screen0/Screen1, dedup do `ProjectDB`, dirty-rect do Graphos,
  rede síncrona na UI thread).

### Bastidores

- **Por que o modo escuro nunca funcionava**: o sistema de 7 temas substituiu um modelo binário antigo
  "Dark"/"Light" — `EditorCfg_Load()` já migra qualquer valor legado assim que carrega, mas 8 lugares
  em `BadigEditor.pb`/`SeeTrackerEditorGui.pbi` continuavam comparando contra o literal `"Dark"` que a
  própria migração tornava impossível de ocorrer. Corrigido com um helper novo,
  `EditorCfg_ThemeIsDark()`, em vez da comparação direta.
- **O bug dos rótulos que o próprio código já tinha marcado como "abandonado"**: uma tentativa anterior
  de colorir `TextGadget` via `SetGadgetColor()` + `GetDlgCtrlID_(hWnd)` (dentro do callback de
  `EnumChildWindows_`) não funcionava porque `GetDlgCtrlID_` não devolve o número do gadget do
  PureBasic nesse contexto. A correção não precisa do número do gadget: tratar `#WM_CTLCOLORSTATIC` no
  mesmo subclass de janela que já tratava `#WM_CTLCOLOREDIT`/`#WM_CTLCOLORLISTBOX` resolve no nível de
  mensagem Win32, cobrindo todo rótulo de todo diálogo automaticamente.
- **Verificado com screenshot real, não só leitura de código** — mesmo cuidado do achado de `7.31.4`:
  como não existe automação de GUI pronta pra este app nativo Win32, foi escrito um driver PowerShell
  descartável (P/Invoke: `EnumWindows`/`GetMenu`/`PostMessage`/`PrintWindow`) que abre o `.exe` de
  verdade, navega o menu real, abre um diálogo e captura a imagem — confirmado contra o tema `Rose` já
  salvo nas configurações reais do usuário.
- **Um "bug" que não era bug**: a auditoria original apontou `Z80SubProj_ReadTextFile`
  (`Z80SubProject.pbi`) como O(n²) por concatenar string linha a linha. Implementar o "fix" e testar
  byte a byte contra o original revelou que `ReadString(FileNum, #PB_File_IgnoreEOL)` **sem** parâmetro
  `Length` já lê o arquivo inteiro numa chamada só — o loop só roda uma vez, já era O(n). Revertido, com
  uma nota no código pra não repetir o engano.

---

## 7.31.4 — "ADEUS WINDOWS 3.1" (2026-08-08)

**Tema da versão**: o piloto no Editor Hexa (`7.31.3`) agradou — usuário pediu pra replicar o
mesmo formato (botões tematizados + ícones Nerd Font opcionais) em **todos** os diálogos e
módulos da IDE. 293 botões em 33 arquivos convertidos numa sessão só.

### Novidades

- **Todo diálogo da IDE agora segue o tema** — telas de Configurar, editores visuais (Sprite,
  Alfabetos, Som, SEE Tracker, Telas, Música, DRAW Screen 2), gerenciador de disco, console do
  openMSX, todas as telas de Ajuda: fundo da janela + todos os botões (293 ao todo) seguem a
  paleta do tema escolhido, em vez de chrome branco/cinza nativo do Windows.
- **Mais de 140 botões com ícone Nerd Font** quando uma fonte de ícones está configurada — Fechar,
  Salvar, Salvar como, Copiar, Tocar, Parar, Ejetar, Inserir, Limpar, Adicionar, Remover, Conectar/
  Desconectar, Voltar, Reset, Montar (Build), Linkar, Importar, Mudo e mais, cada um com tooltip
  mostrando o nome ao passar o mouse. Ações bem específicas de um módulo (ex.: "Gerar código PLAY",
  "Injetar no cursor", "Transferir programa atual") ficam de propósito só com texto — um ícone
  genérico ali confundiria mais do que ajudaria; o mesmo vale pros botões de estado dinâmico do
  console do openMSX ("VSync: ?", "Power: ?" etc.) e pros de uma letra só dos editores de
  som/música/tracker.
- **Infraestrutura generalizada**: o que nasceu especificamente no Editor Hexa (`HexEd_*`,
  `7.31.3`) virou `editor/ThemedButtons.pbi` — módulo compartilhado com a `Macro ThemedButton()` e
  as constantes `#Icon_*`, usado por todos os 33 arquivos. `HexEditorGui.pbi` foi migrado pra usar
  o módulo compartilhado também, sem duplicar código.

### Bugs corrigidos nesta versão

- Nenhum — rollout de um padrão já validado no piloto anterior, sem correção de regressão
  conhecida.

### Documentação nova

- `docs/MANUAL.md`: seção **Botões com ícones** reescrita pra refletir o escopo novo (todos os
  diálogos, não só o Editor Hexa); `CLAUDE.md` ganhou uma nota de arquitetura sobre a ordem de
  declaração `Global`/`Structure` exigida por `EnableExplicit` + inclusão textual — pegadinha real
  encontrada ao mover `ThemedButtons.pbi` pra cedo o bastante na cadeia de `XIncludeFile`.

### Bastidores

- **Achado real de arquitetura**: quase todos os 33 arquivos de diálogo são incluídos bem no topo
  de `BadigEditor.pb` (antes de `Global Color_*`/`Structure EditorSettings` existirem) — igual ao
  motivo que já forçava `WordStarKeys.pbi` (removido em `7.31.0`)/`MdViewerGui.pbi`/
  `EditorSearch.pbi` a ficarem no fim do arquivo. A correção não foi mover os 33 arquivos (mudaria
  a ordem de dezenas de `Declare` existentes) e sim mover as poucas linhas de `Structure`/`Global`
  de que `ThemedButtons.pbi` precisa pro topo do arquivo, antes do primeiro `XIncludeFile` —
  mesmo idioma que os `Declare` de procedure já usados ali, só que pra dado em vez de código.
- **Como a conversão foi feita em escala sem virar bagunça**: nenhuma das ~400 edições (267
  botões + 40 janelas + 127 ícones + 104 tooltips) foi digitada uma por uma — três scripts Python
  pequenos e descartáveis (conversão mecânica `ButtonGadget`→`ThemedButton` com parsing de parênteses
  balanceados, não regex ingênuo; inserção de `SetWindowColor` após o guard `If Not Win`; upgrade de
  ícone só pra rótulos exatos de uma lista curada) fizeram o trabalho repetitivo, com
  recompilação depois de cada rodada pra pegar erro cedo. Foram escritos no scratchpad da sessão,
  não fazem parte do repositório.
- **Por que só ~140 dos 293 botões ganharam ícone**: a lista de conceitos com ícone verificado
  (contra o `glyphnames.json` oficial, mesmo cuidado do piloto) ficou deliberadamente pequena e
  só com ações universais — o resto continua em texto, o que é a escolha certa pra ação
  específica de um módulo, não uma lacuna a preencher depois.

---

## 7.31.3 — "NERD DE VERDADE" (2026-08-08)

**Tema da versão**: o usuário achou que os diálogos ainda pareciam "Windows 3.1" mesmo com os 7
temas novos — "aquele mar de botões cinza que estragam a aparência". Piloto no **Editor Hexa**:
botões deixam de ser controle nativo do Windows (que ignora `Color_*`) e viram imagens desenhadas
na hora, na cor do tema — com a opção de trocar o texto por ícone de verdade de uma Nerd Font,
não um desenho genérico à mão.

### Novidades

- **Editor Hexa (`F7`) com botões tematizados**: os 16 botões da janela (Abrir arquivo, Salvar,
  Marcar início/fim, Preencher..., Excluir bloco... etc., mais os 3 da Galeria de templates) agora
  são desenhados na cor do tema (fundo + borda a partir de `Color_TabInactive`, texto em
  `Color_TextActive`) em vez de chrome cinza nativo do Windows. As setas da barra de rolagem
  customizada também deixaram de ser quadradinhos brancos fixos.
- **Fonte da interface reaproveitada**: os botões tematizados usam a mesma fonte já escolhida em
  **Configurar → Editor...** (`EditorCfg\FontName`) em vez de "Segoe UI" fixo — qualquer `.ttf`
  colocado na pasta de fontes customizadas (ou baixado pelo botão **Baixar fontes (Nerd
  Fonts)...**, que já existia) já deixa a interface mais bonita, sem precisar instalar nada no
  Windows (mesmo mecanismo `AddFontResourceEx` privado ao processo que já existia).
- **Ícones de verdade, não desenhados à mão**: novo combo **Fonte de ícones** em **Configurar →
  Editor...** — escolhendo uma Nerd Font ali, os botões do Editor Hexa trocam o texto por um
  glifo de ícone real (pasta aberta, disquete, lixeira, cadeado etc.), com o nome continuando
  disponível via tooltip ao passar o mouse. Os 15 codepoints usados foram conferidos ao vivo
  contra o `glyphnames.json` oficial do projeto Nerd Fonts (v3.5.0) antes de entrar no código —
  não chutados de memória. Sem fonte de ícones escolhida (padrão), os botões continuam com texto
  normalmente.

### Bugs corrigidos nesta versão

- Nenhum — recurso novo, sem correção de regressão conhecida.

### Documentação nova

- `docs/MANUAL.md` ganhou a seção **Botões com ícones** e a menção à nova opção **Fonte de
  ícones** em **Configurar → Editor...**.

### Bastidores

- **Por que não confiar no primeiro resultado da busca web pra codepoints**: uma primeira consulta
  (resumida por IA a partir do `glyphnames.json`) devolveu `fa-plus_square = U+F055`; conferindo
  o JSON bruto direto (`curl` + parse Python), o valor real é `U+F0FE`. Motivo pra sempre verificar
  codepoint exato contra a fonte primária antes de gravar no código, em vez de confiar num resumo
  de segunda mão.
- **Por que fonte de ícones é uma opção separada da fonte de código**: nem toda fonte bonita pro
  código é uma Nerd Font (a maioria não é), e forçar os botões a tentar usar qualquer fonte
  escolhida arriscaria mostrar o quadradinho de "glifo ausente" em vez de um ícone — combo próprio,
  com "(Nenhuma - usa texto)" como padrão seguro, deixa a decisão explícita com o usuário.
- **O que NÃO entrou nesta rodada**: o mesmo tratamento (botões tematizados + ícones opcionais)
  vale só pro Editor Hexa por enquanto — as ~10 outras janelas de diálogo (Configurar, SEE
  Tracker, editores visuais) continuam com botão nativo. Replicar o padrão (macro
  `HexEd_Button`/`HexEd_CreateButtonImage`, generalizada) fica pra uma próxima rodada, se o
  resultado deste piloto agradar.

---

## 7.31.2 — "CAMALEÃO" (2026-08-08)

**Tema da versão**: os dois temas originais (Escuro/Claro) viraram sete. O usuário achou os dois
atuais feios de verdade e pediu variações mais atraentes — azul escuro, rosa, vermelho, verde,
bege. As paletas foram desenhadas e aprovadas num mockup HTML fora do PureBasic antes de virar
código de verdade (iterar cor em CSS é muito mais rápido que recompilar o app a cada ajuste).

### Novidades

- **7 temas** em **Configurar → Editor...**: **Grafite** e **Neve** (revisão dos dois atuais —
  mais equilibrados, sem preto/branco puro) e cinco novos — **Azul Profundo** (clima Night Owl/
  Nord), **Rosé** (Rosé Pine), **Carmesim** (oxblood/vinho), **Floresta** (Everforest) e **Bege**
  (Solarized Light). Cada um define as ~24 cores nomeadas da área de edição, abas, régua e
  destaque de sintaxe (`ApplyTheme()`, `BadigEditor.pb`) num pacote coerente só.
- `EditorCfg\Theme` deixou de ser um booleano Dark/Light e virou um dos 7 IDs (`Graphite`/`Snow`/
  `Navy`/`Rose`/`Crimson`/`Forest`/`Paper`) — `editor_settings.json` de instalações antigas com
  `"Dark"`/`"Light"` migra sozinho pra `Graphite`/`Snow` no primeiro carregamento, sem resetar a
  preferência do usuário.

### Bugs corrigidos nesta versão

- Nenhum — troca de mecanismo de tema, sem correção de regressão conhecida.

### Documentação nova

- `docs/MANUAL.md` ganhou a seção **Temas** (tabela com as 7 opções e o que muda/não muda de
  verdade em cada uma).

### Bastidores

- **O que NÃO entrou nesta rodada**: os 7 temas valem só pra área do editor + Editor Hexa (os
  únicos dois já ligados ao `ApplyTheme()`). As demais janelas (SEE Tracker, editores de
  Alfabeto/Sprite/Som/Telas, disco, todas as telas de Configurar) usam cores próprias fixas e
  controles nativos do Windows (botões/combos não são temáveis de jeito nenhum, é chrome do SO) —
  auditado ao vivo no código antes de prometer algo: `SeeTrackerEditorGui.pbi` tem 22 botões
  nativos contra só 4 áreas desenhadas à mão, `CharsetEditorGui.pbi` é parecido. Estender tema pra
  essas janelas é um projeto à parte, arquivo por arquivo — cada cor hardcoded precisa ser
  separada em "chrome" (segue o tema) vs. "conteúdo" (ex.: a paleta MSX real mostrada no editor de
  alfabeto/sprite não pode virar rosa só porque o tema é Rosé, senão a ferramenta mentiria sobre a
  cor de verdade do hardware). Fica como próximo passo, uma janela de cada vez, se o usuário
  quiser seguir.
- **Por que migrar `"Dark"`/`"Light"` em vez de só aceitar os dois como sinônimos permanentes**:
  mais simples normalizar uma vez no carregamento (`EditorCfg_Load()`) do que espalhar `Case
  "Dark", "Graphite"` em todo lugar que olha `EditorCfg\Theme` — `ApplyTheme()` só precisa
  conhecer os 7 IDs canônicos.

---

## 7.31.1 — "ATALHO DE TUDO" (2026-08-08)

**Tema da versão**: continuação da mesma sessão de `7.31.0` — depois de tirar o modo WordStar/JOE,
o usuário pediu atalhos de teclado pro resto da IDE (novo projeto, caractere especial, openMSX,
editor hexa, editores gráficos/sprites/som/tracker...) pra não ficar tão preso navegando menu.

### Novidades

- **22 atalhos novos** cobrindo praticamente toda a IDE, seguindo convenções de editor moderno onde
  fazia sentido e reaproveitando teclas já livres onde não havia convenção óbvia:
  - **Projeto**: `Ctrl+Alt+N` novo projeto, `Ctrl+Alt+O` abrir projeto.
  - **Inserir/Configurar**: `Ctrl+Alt+I` caractere especial, `Ctrl+Alt+E` Configurar → Editor...
  - **Executar**: `Shift+F5` Nestor Basic, `F6` renumerar, `Ctrl+Shift+F5` montar relocável,
    `Ctrl+Alt+F5` linkar, `F7` Editor Hexa, `F8` console openMSX, `F9`/`Shift+F9` ver MD/TXT.
  - **Criar (editores visuais)**: `Ctrl+Shift+D` disco, `Ctrl+Shift+P` sprite, `Ctrl+Shift+A`
    alfabeto Graphos III, `Ctrl+Shift+G` som PSG, `Ctrl+Shift+T` SEE Tracker, `Ctrl+Shift+M`
    música, `Ctrl+Shift+2`/`0`/`1` Draw Screen 2/Screen 0/Screen 1.
  - **Ajuda**: `F1` abre `Ajuda → Editor...` — convenção universal de "ajuda", além do menu.
- **Menu Editar novo** (adicionado já em `7.31.0`) segue documentado e sem mudanças aqui.
- **`Ajuda → Editor...`** (`F1`) ganhou as seções novas (Executar, Criar, Inserir/Configurar/Ajuda)
  na referência de atalhos, e a janela cresceu (`680×760`) pra caber o conteúdo sem espremer.

### Bugs corrigidos nesta versão

- Nenhum.

### Documentação nova

- `docs/MANUAL.md`: seções **Executar**, **Criar (editores visuais)** e **Outros atalhos** novas
  dentro de "O editor de texto"; nota de atalho adicionada em cada seção de editor visual
  individual (sprites, alfabetos, som, SEE Tracker, música, Screen 0/1/2) e nos menus Novo
  projeto/Abrir projeto, Caractere Especial e Configurar → Editor.

### Bastidores

- **Por que nem todo item de "Criar" ganhou tecla**: Alfabeto Aquarela, Graphos III Screen 2,
  Screen 1+2, Biblioteca Z80 e Assembly Sub Project são variantes menos usadas dos editores que já
  ganharam atalho — precisariam de um terceiro ou quarto modificador pra não colidir com nada, o que
  deixaria de ser um atalho rápido pra virar mais um exercício de memorização. Ficaram só no menu.
- **Por que `Ctrl+Alt+` para projeto/inserir/configurar em vez de mnemônicos diretos**: `Ctrl+N`/
  `Ctrl+O`/`Ctrl+S` já estavam ocupados pelas ações de arquivo (mais comuns) desde `7.31.0`; `Ctrl+Alt+`
  ficou reservado como o "segundo andar" dessas mesmas letras para as ações de projeto equivalentes,
  em vez de inventar letras sem relação.

---

## 7.31.0 — "APOSENTADORIA" (2026-08-08)

**Tema da versão**: aposentadoria do teclado estilo WordStar/JOE. O usuário nunca tinha se apegado
tanto ao modo assim no dia a dia (usa Helix/JetBrains/VSCode/Sublime/010 Editor no resto do tempo) e
pediu pra voltar ao padrão Scintilla/Windows — setas, `Ctrl+C/V/X/Z/Y`, `Home`/`End` etc. — sem nenhum
modo de teclado próprio por cima.

### Novidades

- **Teclado do editor agora é o padrão Scintilla/Windows**, sem nenhuma interceptação por cima — o
  antigo modo WordStar/JOE (`editor/WordStarKeys.pbi`: subclass de HWND, comandos de duas teclas
  `Ctrl+K x`/`Ctrl+Q x`, bloco marcado com destaque persistente) foi removido por completo.
- **Buscar/Substituir/Ir para linha** ganharam atalhos padrão — `Ctrl+F` (buscar), `F3` (buscar
  próxima), `Ctrl+H` (substituir, tudo de uma vez ou confirmando ocorrência por ocorrência) e `Ctrl+G`
  (ir para linha) — também no novo menu **Editar**. A lógica de busca já existia (portátil, só fala
  com o Scintilla) e foi só desacoplada do antigo mecanismo de teclas duplas.
- **Atalhos de arquivo voltaram ao convencional**: `Ctrl+N` novo, `Ctrl+S` salva (antes `Ctrl+S` movia
  o cursor e salvar era `Ctrl+K D`), `Ctrl+W` fecha aba.
- **`Ajuda → Editor...`** troca a antiga tela cheia (`Ctrl+K H`, ocupava o lugar do editor, fechava
  com qualquer tecla) por uma janela normal com a referência completa dos atalhos, no mesmo estilo
  visual das outras telas de Ajuda.
- **Bloco marcado com destaque persistente foi removido** — seleção normal (mouse ou `Shift`+setas) +
  `Ctrl+C`/`Ctrl+X`/`Ctrl+V` cobre o mesmo caso de uso com o padrão que todo editor moderno já usa.
  Reformatar parágrafo (`Ctrl+B` no modo antigo) e salvar bloco marcado direto num arquivo (`Ctrl+K W`)
  não têm substituto — não estavam em uso real e ficaram de fora desta rodada.

### Bugs corrigidos nesta versão

- Nenhum — troca de mecanismo de teclado, sem correção de regressão conhecida.

### Documentação nova

- `docs/MANUAL.md`: seção "O editor de texto" reescrita (atalhos padrão, Buscar/Substituir/Ir para
  linha, `Ajuda → Editor...`); `CLAUDE.md` e `README.md` perderam as referências ao arquivo removido.

### Bastidores

- **Por que remover em vez de só desligar por padrão**: o usuário deixou claro que quer esquecer o
  WordStar/JOE de vez, não só desativar — então o código morto (subclass Win32, tela de ajuda em tela
  cheia, bloco marcado) saiu do repositório, não ficou guardado atrás de uma flag.
- **Por que Buscar/Substituir/Ir para linha sobreviveram**: essas três eram a única funcionalidade real
  do modo antigo sem equivalente automático no Scintilla puro (diferente de copiar/colar/desfazer, que
  já vêm de graça do keymap padrão) — descartá-las teria sido uma regressão de verdade, não só uma
  mudança de tecla.

---

## 7.29.5 — "PALPITEIRO" (2026-08-08)

**Tema da versão**: o editor aprendeu a "dar palpite" — auto completar de verdade, tanto em BASIC/
Basic Dignified quanto em Assembly, mais um jeito de salvar tudo de uma vez sem precisar passar aba por
aba.

### Novidades

- **Auto completar em abas `.dmx`/`.bas`** — sugere palavras-chave clássicas do MSX-BASIC, instruções
  do Basic Dignified, comandos MSXBAS2ROM (quando aplicável) e variáveis já usadas no documento
  (coletadas ao vivo do texto, sem precisar de `DECLARE`), assim que a palavra digitada atinge um
  mínimo configurável de letras. Nova tela **`Configurar → Basic Options...`** (habilitar, mínimo de
  letras, caixa das sugestões).
- **Os 87 wrappers `.NB_*` do NestorBASIC** entraram na lista de sugestões — fonte única com
  `Ajuda → NestorBASIC...`, nunca diverge dela. Basta digitar a partir da letra depois do `.`
  (`.NB_Rea` já sugere).
- **Auto completar em abas Assembly (`.asm`)** — mnemônicos, registradores/condições e diretivas do
  Z80 (incluindo as com ponto do dialeto N80), mais rótulos já definidos no documento, pela mesma
  regra clássica MACRO-80/Z80 que o destaque de sintaxe já usa. Nova tela própria
  **`Configurar → Assembly...`**, independente da tela de BASIC (cada modo guarda sua própria caixa).
- **Caixa das sugestões configurável** — "Como digitado" (`pri` sugere `print`, `PRI` sugere `PRINT`),
  sempre maiúsculas ou sempre minúsculas. Variáveis, rótulos e nomes `.NB_*` sempre mantêm a grafia
  original do documento, nunca reformatados.
- **Navegação 100% nativa do Scintilla** — Enter/Tab aceitam a opção destacada, setas navegam, Esc
  cancela, digitar mais estreita a lista sozinha. Nenhuma tecla nova foi interceptada; sem conflito com
  o teclado WordStar/JOE (que só usa combinações com Ctrl).
- **Arquivo → Salvar Tudo** (`Ctrl+Alt+S`) — salva todas as abas abertas (na ordem, pedindo "Salvar
  como..." só pras que ainda não têm nome, sem travar as demais se uma for cancelada) e o projeto atual
  numa ação só. Só grava o projeto se ele já tiver arquivo permanente ou se o projeto temporário tiver
  conteúdo de verdade — não força um diálogo "Salvar projeto como..." vazio à toa.

### Bugs corrigidos nesta versão

- Nenhum — versão inteira de recursos novos, sem correção de regressão conhecida.

### Documentação nova

- `docs/MANUAL.md` ganhou a seção **Auto completar** (nova, com tabela de navegação e o que é sugerido
  em cada modo) e a entrada de **Salvar Tudo** na seção Arquivo; `docs/SPEC.md` ganhou os módulos **25**
  (Auto completar) e **1b** (Salvar Tudo); `README.md` atualizado (versão, feature list, changelog).

### Bastidores

- **Por que um campo de configuração em vez de detectar a caixa predominante do documento**: o usuário
  perguntou diretamente se dava pra "ver estatisticamente" se a maioria dos comandos já digitados
  estava em maiúsculo ou minúsculo. A alternativa de detecção estatística foi descartada — precisaria
  reescanear o documento inteiro a cada sugestão (custo), e o resultado dependeria do histórico inteiro
  do arquivo em vez da última coisa digitada (menos previsível). "Como digitado" resolve o caso comum
  sem nenhum dos dois problemas.
- **Por que os mapas de palavra-chave do Z80 não estavam acessíveis de fora do módulo**: `Z80Asm.pbi`
  usa `DeclareModule`/`Module` de verdade (não só prefixo de nome, ver módulo 2 do `SPEC.md`) — os
  `Global NewMap KwMnemonic()` etc. são declarados dentro do `Module`, não do `DeclareModule`, então
  ficam privados por escopo do PureBasic. Resolvido com 4 novos procedimentos exportados
  (`MnemonicList()`/`RegisterList()`/`DirectiveList()`/`OperatorWordList()`) que devolvem o vocabulário
  como string espaço-separada — mesmo formato que `FillKeywordMap()` já consome do lado de fora,
  nenhuma abstração nova precisou ser inventada.
- **Por que o "." do `.NB_*`/rótulos relativos não precisou de tratamento especial**: o conjunto de
  "caracteres de palavra" que o Scintilla usa pra decidir onde uma palavra começa não inclui `.` — a
  fronteira de palavra já para exatamente depois do ponto sozinha, então guardar os nomes sem o `.` no
  mapa de candidatos e deixar o Scintilla substituir só a partir dali já produz o resultado certo, sem
  nenhum código extra pra detectar/preservar o `.` manualmente.
- Codinome **"PALPITEIRO"** — gíria brasileira pra quem "dá palpite" sem ser convidado, exatamente o
  que um motor de auto completar faz por natureza (torcendo pra acertar na maioria das vezes).

### Ainda pendente

- `CollectDocumentVariables()`/`CollectZ80Labels()` são varreduras leves (não um tokenizador completo)
  — não distinguem com precisão texto dentro de comentário/string do resto do código. Na prática, pouco
  ruído real (nomes de variável/rótulo plausíveis raramente aparecem por acaso dentro de comentários ou
  literais de string), mas é uma limitação conhecida, não testada exaustivamente contra casos extremos.
- Sem harness de teste automatizado dedicado (`editor/tools/*Cli.pb`) para essa frente — validado só
  por compilação limpa e smoke test de abertura do `.exe`; teste de interação real (digitar, ver o
  popup, navegar, aceitar uma sugestão) não foi automatizado neste ambiente (sem GUI automation nativa
  Win32 disponível, só a de browser) — recomendado testar manualmente antes de confiar às cegas.

---

## 7.27.3 — "TORRE DE CONTROLE" (2026-08-08)

**Tema da versão**: o controle remoto do openMSX deixou de ser um console de comando avulso e virou um
painel de bordo completo — 6 abas cobrindo praticamente tudo que o Catapult original oferecia (e
algumas coisas que ele não oferece mais). **Executar → BASIC** (F5) também parou de abrir uma janela
nova do openMSX a cada execução: agora reaproveita a instância já aberta, trocando só o disco e dando
reset, como trocar o disquete de um MSX de verdade.

### Novidades

- **`Configurar → openMSX...`** (`editor/OpenMsxSettingsGui.pbi`, novo arquivo) — tela própria só com
  os campos do emulador (executável, máquina, extensão), lendo/gravando exatamente os mesmos campos
  que a aba "Emulador" de `Configurar → Basic Dignified...` já usava (mesma struct `BadigCfg`, mesmo
  `badig_settings.json`) — as duas telas nunca divergem, por construção, não por sincronização.
- **`Executar → BASIC` (F5) reaproveita a instância aberta do openMSX** em vez de abrir uma nova a cada
  run (`OMSX_LoadDisk()`, `editor/OpenMSXBridge.pbi`) — só troca o disco da unidade A e reinicia.
- **`Executar → openMSX...` virou um painel de 6 abas** (`editor/OpenMSXConsoleGui.pbi`):
  - **Console** — mídia (disco/cartucho/cassete, inserir/ejetar), botão "Transferir programa atual"
    (mesmo caminho do F5), log de comandos, campo de comando livre.
  - **Outros comandos** — velocidade (barra + 100% + Turbo segurando o mouse, acelera ao máximo e
    volta a 100% ao soltar), Power/Reset/Pause, interruptor de firmware residente, conectores das
    portas Joystick 1/2 (Nada/Mouse/Teclado como joystick P1/P2/Paddle), Ren Sha Turbo.
  - **Vídeo** — renderer, escala (2/3/4), VSync, Modo TV (dropdown com as 5 opções reais do openMSX —
    simple/ScaleNx/hq/RGBtriplet/TV, como no Catapult), deinterlace/limitar sprites/tela cheia/
    desabilitar sprites, fonte de vídeo (MSX/GFX9000/Video9000), efeitos estilo CRT (scanline/blur/
    glow/gamma/noise — barra + valor + reset pro padrão de fábrica), screenshot (nome base + diretório
    opcional + numeração sequencial automática), LEDs visuais (Power/Caps/Kana/Pause/Turbo/FDD) +
    botão STOP (tecla física do teclado MSX) + FPS ao vivo.
  - **Volume** — mixer do openMSX com **descoberta dinâmica de dispositivo de som**: como o nome real
    de cada chip varia por cartucho/ROM conectado (confirmado ao vivo: coisas como
    `"Konami SCC+ Cartridge with expanded RAM (1)"`, não um nome fixo tipo "SCC+"), a lista aparece
    sozinha conforme o openMSX avisa que algo mudou, ou você adiciona manualmente digitando o nome.
    Volume + Balance (substitui o antigo esquema Mute/Left/Right/? do Catapult, removido do openMSX
    atual em favor de um balanço contínuo -100..100). MIDI in (arquivo `.mid`) e MIDI out (log em
    arquivo), conectores também descobertos dinamicamente.
  - **Input Text** — área grande dedicada pra colar/digitar texto + botões **Type**/**Clear** (mesmo
    mecanismo do Catapult: digita no MSX como se fosse teclado de verdade).
  - **Status Info** — log passivo de tudo que o openMSX reporta (mudou por comando nosso ou não),
    separado do log interativo da aba Console.

### Bugs corrigidos nesta versão

- LEDs Caps/Kana/Turbo/FDD nunca atualizavam — o nome real do setting é `led_caps`/`led_kana`/
  `led_turbo`/`led_fdd` (prefixo `led_`), não o nome simples usado na primeira tentativa. Só achado
  testando ao vivo contra um openMSX de verdade.
- Documentação "resumida" do openMSX errava os valores padrão de vários efeitos de vídeo (dizia
  scanline=0/blur=0/gamma=1.0); os valores reais, conferidos direto no código-fonte
  (`RenderSettings.cc`), são scanline=20/blur=50/gamma=1.1 — usados agora nos botões "Reset".

### Documentação nova

- `docs/RELEASE_NOTES.md` (este arquivo).
- `docs/MANUAL.md`, seção "Controle remoto do openMSX" reescrita do zero pra descrever as 6 abas e o
  novo comportamento do F5 (a nota antiga dizia explicitamente que F5 e o console eram sessões
  separadas — não é mais verdade).
- `README.md` atualizado com a nova tela de configuração e o painel de controle expandido.

### Bastidores

- **Nomes de dispositivo de som e conector MIDI não são fixos** — variam por ROM/cartucho/quantidade
  de instâncias (ex. `"Sunrise MoonSound (1) FM"`, `"Generic MSX-Audio-MIDI-in"`). Confirmado ao vivo
  antes de implementar a aba Volume, o que mudou o design de "sliders fixos por nome" pra "lista
  dinâmica descoberta em runtime" — evita uma aba que simplesmente não funciona assim que o usuário
  troca de cartucho.
- Consulta de FPS (`openmsx_info fps`) e a lista de conectores (`plug` sem argumentos) usam o mesmo
  protocolo "fire and forget" de sempre (`OpenMSXBridge.pbi`), com uma correlação simples de "a próxima
  resposta que chegar é a desta consulta" — não há id de correlação real no protocolo do openMSX,
  então isso assume que nada mais está sendo mandado bem no meio (mesma suposição que o resto da ponte
  já fazia implicitamente).
- Durante a investigação ao vivo, o openMSX caiu duas vezes ao empilhar extensões de som conflitantes
  manualmente (`ext moonsound` + `ext audio` juntos, fora do fluxo normal) — não parece ligado ao
  código novo (testes subsequentes, mais conservadores, rodaram sem problema), mas fica registrado
  caso apareça de novo em uso normal.

### Ainda pendente

- **Balance** de um dispositivo adicionado manualmente na aba Volume só aparece com valor real depois
  de mudado pelo menos uma vez — o botão "Adicionar" só consulta Volume ativamente.
- Fluxo de conectar/desconectar MIDI in/out não foi testado ao vivo de ponta a ponta (evitado depois
  das quedas do openMSX durante a investigação de nomes).
- Não existe (ou não foi encontrado) um comando do openMSX que liste todos os dispositivos de som de
  uma vez — a descoberta depende de mudança de estado ou de adição manual, nunca de enumeração
  completa automática.
- Máquinas com mais de uma instância MSX simultânea (visto ao vivo: uma configuração de teste chegou a
  subir "machine1" e "machine2" ao mesmo tempo) não são distinguidas — o rastreio de estado é "cego a
  máquina", mistura updates de qualquer instância que exista.

---

## 7.25.0 — "HEXORCIST" (2026-08-07)

**Tema da versão**: o Editor Hexa (`Executar → Editor Hexa...`) aprendeu a reconhecer sete formatos de
arquivo novos — da era MSX/CP-M — além dos três nativos desta IDE que já reconhecia. Praticamente
qualquer disquete antigo de MSX que passar por aqui agora sai com nome e sobrenome em vez de cair em
"binário desconhecido/dados crus".

### Novidades

- **Executável MSX-DOS (`.COM`)** — reconhecido por extensão (código Z80 cru, sem cabeçalho, convenção
  CP/M, carrega e executa sempre em `0100h`).
- **Texto ASCII puro vs. BASIC MSX clássico (linhas numeradas)** — o antigo rótulo genérico "BASIC
  clássico ou fonte" virou dois rótulos diferentes, decidido pelo primeiro caractere visível do arquivo.
- **Planilha SuperCalc 2 MSX (`.CAL`)** — assinatura, título e onde a seção de dados começa. Validado
  contra 6 planilhas `.CAL` reais; o layout célula a célula ainda não foi decifrado (ver
  `docs/reference/supercalc2-cal-format.md` para o que falta e como continuar).
- **Banco de dados dBase II (`.DBF`)** — formato **totalmente decifrado**: cabeçalho, descritores de
  campo e os próprios registros de dados, validados registro a registro contra um `.DBF` real (ver
  `docs/reference/dbase2-dbf-format.md`).
- **Os 4 formatos nativos do Graphos III**, validados em lote contra praticamente todo o acervo real
  deste repositório (~4100 arquivos entre `graphos/` e `graphos-IV/`, não uma amostra pequena):
  - **Alfabeto (`.ALF`)** — 759/781 (97%)
  - **Layout (`.LAY`)** — 234/234 (100%) — decodifica o RLE+ofuscação de verdade, não só olha o cabeçalho
  - **Tela (`.SCR`)** — 86/86 (100%)
  - **Banco de shapes (`.SHP`)** — 2920/3028 (96%) — o ganho mais significativo: esse formato não tinha
    **nenhum** reconhecimento antes (não tem cabeçalho BLOAD/BSAVE)

### Bugs corrigidos nesta versão

- Decodificador do `.LAY` parava cedo demais quando sobrava padding no fim do stream comprimido
  (confiava no tamanho declarado pelo cabeçalho em vez de parar assim que os 6144 bytes esperados fossem
  decodificados).

### Documentação nova

- `docs/reference/supercalc2-cal-format.md` — notas de engenharia reversa do formato `.CAL`.
- `docs/reference/dbase2-dbf-format.md` — spec completa do formato `.DBF` (dBase II).
- `docs/MANUAL.md` e `README.md` atualizados com a lista completa de formatos reconhecidos pelo Editor
  Hexa.
- `docs/SPEC.md`, módulo 17, ganhou uma tabela única consolidando todos os formatos reconhecidos hoje e
  o nível de confiança de cada validação, em vez de só parágrafos cronológicos.

### Bastidores

- `sc2/` (projeto Go pessoal do usuário que ajudou a decifrar o `.CAL`, mais os discos originais do
  SuperCalc 2 MSX) entrou no `.gitignore` — contém software de terceiros, mesmo tratamento já dado a
  `see/`.
- O par binário/texto `EXEMPLO.CAL`/`EXEMPLO.SDI`, achado dentro de um disco original do SuperCalc 2, foi
  o que destravou o estudo do `.CAL` sem precisar rodar o `SDI.COM` original num emulador.
- `PESSOAL.DBF`, achado no mesmo lote de arquivos, foi decifrado por completo cruzando os bytes contra o
  próprio conteúdo legível do arquivo (nomes/cargos/salários reais).

### Ainda pendente

- **WordStar** e **MSX-Word** — sem arquivo de amostra real suficiente pra validar um reconhecimento
  seguro ainda (WordStar em particular não tem cabeçalho fixo, só liga o 8º bit no fim de cada palavra —
  arriscado demais adivinhar sem arquivo real).

---

## 7.7.1 — "BFG9200" (2026-07-29)

Editor Hexa genérico (`editor/HexEditorGui.pbi`) lançado: abre qualquer arquivo do disco, grade
offset/hex/ASCII, edição byte a byte, reconhecimento automático dos três formatos nativos desta IDE
(binário MSX BLOAD/BSAVE, MSX-BASIC tokenizado, boot sector FAT12 de imagem `.dsk`), galeria de
templates persistida em JSON (semeada com os três formatos nativos do Graphos III — Alfabeto/Layout/
Tela) e operações de bloco (preencher/inserir/sobrepor/excluir). Codinome: BFG9000 (a arma mais brutal
de Doom) cruzado com `9200h`, o endereço de VRAM que assinava os três formatos do Graphos III na galeria
de templates dessa versão. Ver `docs/SPEC.md`, módulo 17, para o detalhe completo.
