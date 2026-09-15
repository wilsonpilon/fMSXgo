# Projeto: IDE MSX BASIC + Z80 Assembly (PureBasic)

> Transcrição reconstruída da conversa de planejamento sobre o projeto. Contexto: o usuário já tem um editor de MSX BASIC em PureBasic (com licença vitalícia) e quer expandi-lo para uma IDE completa, integrando assembler Z80, editores visuais e controle do emulador openMSX.

---

## 1. Viabilidade inicial: compilador Z80 + editor integrado

**Pergunta:** Até que ponto é viável criar um compilador Z80 assembly, integrado com editor de texto com destaque de sintaxe, reaproveitando compiladores open source existentes para não começar do zero? (Só viabilidade, sem começar a desenvolver ainda.)

**Resposta:**

Totalmente viável, dividido em duas partes: assembler e editor.

**Assembler Z80** — duas rotas:
- **Reaproveitar existente**: sjasmplus, z80asm (do z88dk) e Pasmo são open source, maduros, cobrem bem o dialeto Z80 usado em MSX. Chamado como subprocess via `os/exec` (na época cogitado em Go), captura stdout/stderr, parseia erros.
- **Escrever o próprio**: um assembler Z80 de dois passes (resolver labels, depois gerar código) é projeto de porte médio. Dado o histórico do usuário com parsing de baixo nível (emulador FX-80, hex editor), está ao alcance. Vantagem: controle total sobre mensagens de erro, integração com editor (sublinhar erro na linha exata), formatos de saída customizados (.dsk direto).

**Editor com syntax highlighting** — depende da interface:
- **TUI**: possível com `tview`, mas highlighting decente é mais trabalhoso.
- **Desktop GUI**: com Wails + Svelte, dá pra embutir CodeMirror ou Monaco Editor (motor do VSCode) via JS, com modo de linguagem customizado para Z80 assembly — highlighting profissional, autocomplete de mnemônicos, squiggly underlines para erros.

**Estimativa**: MVP funcional (editor com highlighting + assembler via subprocess do sjasmplus) é questão de dias. Assembler próprio em Go, integrado nativamente, é um projeto de semanas.

---

## 2. Decisão: Desktop com Fyne, sem subprocess

**Pergunta:** Desktop, com Fyne. Prefiro usar apenas como referência e não ficar chamando via subprocesso.

**Resposta:**

Isso muda o jogo em duas frentes: o assembler fica mais robusto tecnicamente (mais trabalho), e o editor tem uma limitação real.

**Assembler próprio (Go, usando outros como referência)** — totalmente viável, arquitetura clássica de dois passes:
1. **Passe 1**: tokeniza, identifica labels/símbolos, calcula endereços (sem resolver referências futuras)
2. **Passe 2**: gera código de máquina, resolvendo labels já conhecidos

Estudar o código-fonte do sjasmplus ou z88dk (ambos abertos) para entender tabela de opcodes, tratamento de diretivas (ORG, DB, DW, EQU etc.) e casos especiais de instruções Z80 (modos de endereçamento, prefixos DD/FD para IX/IY) — reaproveitar conhecimento sem reaproveitar código, evitando problema de licença.

**Editor em Fyne — ponto de atenção**: Fyne não tem componente de code editor com syntax highlighting nativo e maduro como CodeMirror/Monaco. Opções realistas:
- `widget.RichText` / `widget.TextGrid`: texto colorido segmento por segmento, mas o highlighting é montado na mão (tokenizar linha, mapear cor por tipo de token, re-renderizar a cada edição)
- Pacotes de terceiros da comunidade Fyne para "code editor" são bem menos maduros/mantidos que libs web

Highlighting em Fyne é fazível, mas o usuário escreveria o próprio tokenizer e motor de renderização incremental — um projeto dentro do projeto.

**Viabilidade geral**: sim, tudo em Go/Fyne sem subprocess e sem código de terceiros embutido é viável, porém mais trabalho que a rota Wails+Monaco.

---

## 3. Pivô: E se fosse em PureBasic?

**Pergunta:** E se fizermos em PureBasic?

**Resposta:**

**Editor com syntax highlighting**: PureBasic tem o `EditorGadget`, baseado no Scintilla (mesmo motor do Notepad++ e SciTE). Vantagem grande: Scintilla já tem suporte nativo a lexers customizados e syntax highlighting embutido — muito mais maduro que a situação do Fyne. Dá para definir um lexer para Z80 assembly (mnemônicos, registradores, diretivas, comentários, literais) usando as funções de estilo do `EditorGadget`, sem escrever motor de renderização do zero. Nível de conforto equivalente a CodeMirror/Monaco, porém nativo.

**Assembler**: não muda muito em relação a Go — escrito de dois passes em PureBasic, usando sjasmplus/z88dk como referência de arquitetura e tabela de opcodes. PureBasic lida bem com manipulação de bytes, arquivos binários e strings.

**Trade-offs**:
- PureBasic é licença comercial paga (diferente de Go) — custo real se ainda não tiver a licença.
- Ecossistema de bibliotecas bem menor que Go — mais dependência das libs nativas do PureBasic.
- Em compensação: editor com highlighting decente "de fábrica" via Scintilla, sem trabalho extra do Fyne.
- Deploy simples (executável nativo Windows/Linux/Mac sem runtime externo), combinando com o espírito retro dos outros projetos do usuário.

---

## 4. Confirmação da licença e integração com editor MSX BASIC existente

**Contexto do usuário:** Já tem licença vitalícia do PureBasic e já está fazendo um editor de MSX BASIC em PureBasic. Ideia: integrar tudo em uma coisa só — editor de MSX BASIC + assembly Z80. Exemplo de fluxo: gerar um programa em MSX BASIC que também tem uma parte em Z80, gerar um `.bin` ou listagem hexadecimal, e no MSX BASIC usar `BLOAD` ou a rotina clássica de carregar código hexa em tempo de execução.

**Resposta:**

Fecha muito bem — é o workflow clássico de desenvolvimento MSX (BASIC para lógica/UI, Z80 para performance). Como a base do editor MSX BASIC em PureBasic já existe, a integração é extensão natural, não projeto do zero.

**Como encaixaria tecnicamente**:
- **Editor unificado**: `EditorGadget`/Scintilla suporta múltiplos lexers. Dá para ter um modo que reconhece blocos de assembly dentro do mesmo arquivo (ex.: delimitados por marcador tipo `' ASM` ... `' ENDASM`), trocando o highlighting dinamicamente dentro do mesmo documento, ou usar abas separadas (.BAS e .ASM) que se referenciam.

---

## 5. Editor gráfico (sprite/char, DRAW/LINE/CIRCLE)

*(Nota: parte da explicação detalhada sobre o editor de sprite/char não foi recuperada nesta reconstrução; o trecho abaixo retoma a partir da conclusão sobre o editor de LINE/CIRCLE/DRAW.)*

**Resposta (trecho recuperado):**

**Viabilidade**: alta — o editor combinado (LINE/CIRCLE/PSET + DRAW) fica mais simples de implementar que o DRAW puro sozinho, porque LINE/CIRCLE/PSET são comandos de coordenada absoluta, sem estado de "posição/ângulo atual" para gerenciar.

**Saída**: lista de comandos BASIC prontos (`LINE...`, `CIRCLE...`, `PSET...`, `DRAW...`) intercalados na ordem que o usuário desenhou, para injetar como bloco/include no editor principal.

**Integração com o resto do projeto**: os editores geram `DATA`/`POKE` prontos para MSX-BASIC, ou bytes hexa direto num bloco `#asm`/binário, se preferir carregar via rotina Z80. Não são apêndices soltos — alimentam diretamente o mesmo pipeline de saída (BASIC ou ASM).

**Resumo de viabilidade do projeto todo até este ponto**: dado que já existem o editor base e a licença PureBasic, os módulos ficam em ordem crescente de esforço: sprite/char editor (mais simples, componente visual reaproveitável) → assembler Z80 (médio-alto, com referências claras) → reescrita do Basic Dignified (depende do escopo real do original).

---

## 6. Editores de som: SOUND (PSG), Tracker e MML (PLAY)

**Pergunta:** Dá para incluir um editor de sons para o comando `SOUND` (gerar tom, pitch, volume, envelope)? Um tracker? Um editor de MML de música do MSX sob o comando `PLAY`?

**Resposta:**

Sim, dá para incluir os três — progressão natural de complexidade parecida com a do sprite/char editor.

**Editor visual para `SOUND` (PSG — AY-3-8910)**:
- O chip de som do MSX (PSG, mesmo do AY-3-8910/YM2149) tem 3 canais de tom + 1 de ruído + envelope de volume por hardware.
- O comando `SOUND` do BASIC escreve direto nos registradores do PSG (canal, tom fino/grosso, volume, mixer, envelope). Editor visual: sliders/campos para tom (frequência → período do registrador), volume (0-15 ou "usar envelope"), forma de envelope (~10 formatos de hardware: sawtooth, triangle, etc.), período de envelope.
- Saída natural: sequência de `SOUND n, valor` prontas, ou bytes de registrador crus para rotina Z80 que escreve direto na porta do PSG (mais rápido que várias chamadas `SOUND`).
- Viabilidade: alta, é um editor de "parâmetros de hardware", sem grande desafio de algoritmo.

**Tracker**:
- Escopo maior. Um tracker de verdade envolve: sequenciador de padrões, editor de padrão (grade linhas x canais com nota/volume/efeito), motor de playback (tempo real ou geração de trilha para tocar via Z80/interrupção no MSX), definição de "instrumentos" (no PSG seria basicamente envelope + volume ao longo do tempo, já que não há sample/wavetable como em trackers MOD).

*(A explicação sobre o editor de MML/PLAY não foi recuperada integralmente nesta reconstrução.)*

---

## 7. Extensão NestorBASIC (nbasic)

**Contexto do usuário:** Quer marcar/apelidar as funções como comandos do BASIC ou extras do nbasic (NestorBASIC).

**Resposta:**

Confirmado como NestorBASIC (nbasic). Faz sentido incluir. Estrutura: erros retornam pelo comando `USR`, há um array de inteiros `P` que precisa ser definido separadamente, junto com um array de strings próprio para funções de arquivo e processamento de string. Todas as funções do NestorMan, InterNestor Suite e InterNestor Lite passam por um único `USR` com array de parâmetros inteiros — totalmente compatível com o Turbo-BASIC, seguindo o padrão "uma função, várias posições de array".

**Como isso se encaixaria no pré-processador**: extensão natural do que o Basic Dignified já faz (resolver símbolos/labels antes de gerar o `.bas` final). Tabela de definições, por exemplo:

```
#nbasic_func LOAD_SECTOR = 23      ' número da função NestorBASIC
#nbasic_param DRIVE = P(1)
#nbasic_param SECTOR = P(2)
#nbasic_param BUFFER_SEG = P(3)
```

O usuário escreveria `NB_CALL LOAD_SECTOR` em vez de montar o array na mão e chamar `A=USR(0)`. O pré-processador expande isso para `P(1)=...:P(2)=...:P(3)=...:A=USR(0)` na hora de gerar o `.bas` final — mesma mecânica de substituição simbólica do Basic Dignified.

**Marcação visual no editor**: usar o syntax highlighting do Scintilla, com classe de "estilo" separada para chamadas NestorBASIC (cor diferente de comando BASIC nativo) — deixa claro visualmente quando algo é `PRINT`/`FOR` (BASIC puro) vs função "apelidada" do NestorBASIC. Ajuda a evitar confusão de portabilidade (o usuário vê que aquele trecho depende de `nbasic.bin` carregado).

**Ponto de atenção**: a definição desses arrays (`DIM P(15)`, `DIM F$(...)`) tem que respeitar regras de posição, principalmente dentro de blocos turbo (ex.: redefinir array `F` dentro de bloco turbo deve ser feito na primeira linha do bloco). O pré-processador precisa conhecer essas regras para gerar código válido automaticamente, não só fazer substituição de texto ingênua.

**Viabilidade**: alta. É basicamente uma tabela de aliases (função → número, parâmetro → posição no array) com geração de código, reaproveitando a mesma infraestrutura de símbolos do Basic Dignified reescrito. O trabalho real está em mapear com precisão a lista de funções e parâmetros do NestorBASIC.

---

## 8. msxbas2rom — dialeto extra e geração de ROM

**Pergunta:** Além do Basic Dignified Suite, existe o msxbas2rom, que é um compilador MSX BASIC com muitos recursos extras — permite usar tracker externa, editor de telas externo, e tem comandos do MSX Turbo BASIC. Dá para incluir esse dialeto no editor, ampliando o pré-processamento do Basic Dignified Suite, com os editores internos próprios, gerando um source ASCII para enviar a esse compilador e gerar uma ROM para o MSX?

**Resposta:**

Totalmente viável. O msxbas2rom é um CLI open source, feito para rodar em terminal e se integrar facilmente com qualquer ambiente de desenvolvimento — compilador experimental multiplataforma inspirado no Basic-kun, com todo o processo de compilação e geração de código feito do zero (não depende de engine proprietária embutida).

**Pipeline em camadas**:
1. **Editor** (módulos já discutidos: sprite, char, som, tracker, draw/line/circle) continua gerando os blocos de conteúdo.
2. **Basic Dignified** (reescrito) continua resolvendo labels, numeração, includes.
3. **Novo passo**: em vez de (ou além de) gerar `.BAS` clássico para interpretador, gerar `.bas` no dialeto aceito pelo msxbas2rom, que suporta superset com recursos turbo/extras — comandos de sprite estendidos (`SET/GET SPRITE COLOR/PATTERN`) e suporte a recursos externos como MSX Tile Forge para carregamento de mapas.
4. Chamar o `msxbas2rom` (único ponto onde faria sentido manter subprocess, por ser compilador C++ separado) para gerar a ROM final.

**Ponto de atenção importante**: conferir a lista de comandos suportados/incompatíveis do msxbas2rom antes de mapear 1:1 os editores gráficos para esse dialeto — historicamente esse tipo de compilador (Basic-kun/Turbo original) tem lista de comandos que não compilam bem (ex.: `DRAW` e `PLAY` não podiam ser compilados dentro do bloco turbo no original). O msxbas2rom é reescrito do zero e pode ter cobertura diferente, mas os módulos de DRAW e MML/PLAY podem precisar gerar saída alternativa (rotina Z80 equivalente) quando o alvo for ROM via msxbas2rom, em vez do comando BASIC direto.

**Resumo de viabilidade**: sim, dá para ampliar o pré-processador para reconhecer esse dialeto como "alvo de compilação" (dois back-ends: interpretador clássico vs ROM via msxbas2rom), com os editores internos alimentando ambos, precisando de uma camada de "tradução por alvo" para comandos que um aceita e outro não.

---

## 9. Saída tokenizada (.bas tokenizado)

**Pergunta:** Ainda vou pensar nisso [msxbas2rom], só se valer a pena, ou pelo menos manter como duas saídas diferentes. Além disso, quero que o programa, se for MSX BASIC puro (sem extensões msxbas2rom), gere o arquivo `.bas` já tokenizado, facilitando a carga — o código em ASCII pode demorar para carregar.

**Resposta:**

Faz sentido e é viável — um dos módulos mais "mecânicos" tecnicamente, porque o formato tokenizado do MSX-BASIC é bem documentado (mesmo formato usado pelo próprio `SAVE` sem `,A`).

**Como funciona a tokenização**:
- Arquivo `.bas` tokenizado tem estrutura por linha: marcador de encadeamento (ponteiro para próxima linha), número da linha (2 bytes), bytes tokenizados do conteúdo, terminador `0x00`, repetindo até o fim, com `0x00 0x00 0x00` marcando fim do programa. Primeiro byte do arquivo costuma ser `0xFF` indicando "tokenizado".
- Cada palavra-chave (`PRINT`, `FOR`, `GOTO`, etc.) vira 1 ou 2 bytes (tokens de 1 byte para maioria, tokens estendidos com prefixo `0xFF` para funções/comandos menos comuns).

---

## 10. Controle do openMSX via socket

**Pergunta:** O openMSX permite ser controlado por named sockets. Existe um programa em Python que controla ele, e outro em Go também. Dá para, da nossa IDE, controlar algumas coisas do openMSX? Por exemplo: já mandar o programa para ele, mandar texto para o input, e quando houver erro, voltar para a IDE e parar na linha que deu erro?

**Resposta:**

Dá para fazer tudo isso — o openMSX foi desenhado exatamente com esse propósito em mente. Após conectar, o openMSX espera comandos em XML no canal (pipe ou socket) e devolve saída em XML, com mensagens `<command>texto</command>` recebendo respostas `<reply result="ok/nok">`. O motivo de existir é justamente permitir que launchers e debuggers externos controlem uma sessão rodando.

Como já existem clientes prontos em Python e Go, o trabalho aqui é principalmente de "protocolo", não de reinventar a comunicação.

**1. Enviar o programa para o openMSX** — duas rotas:
- **Via disco virtual**: comando `diskmanipulator`, uma coleção de comandos para manipular arquivos dentro de uma imagem de disco — dá para escrever o `.bas`/`.dsk` gerado pelo IDE direto na imagem montada, sem digitar nada na tela.
- **Via digitação simulada**: comandos de baixo nível para pressionar/soltar teclas na matriz de teclado do MSX (`keymatrixup`/`keymatrixdown`), permitindo simular teclas — útil para digitar `RUN"ARQUIVO"` automaticamente após montar o disco.

**2. Mandar texto para o input do programa rodando** — mesma mecânica do item 1 (`keymatrixup`/`keymatrixdown`), simulando teclas MSX uma a uma. Funciona tanto para interação em tempo de execução (`INPUT` do BASIC) quanto para comandos do próprio interpretador.

**3. Detectar erro e voltar para a IDE na linha certa — ponto mais delicado**:
- Viável, mas com nuance importante: erros do MSX-BASIC são tratados internamente pelo interpretador (não é exceção de sistema que o openMSX vê "de fora").
- O hardware/BIOS expõe um hook de erro (endereço fixo de sistema) que intercepta qualquer erro de sintaxe/execução antes do tratamento padrão, dando acesso ao código do erro e à posição no texto do programa.
- Combinando isso com os recursos de debug do openMSX (interface de debugger via comando `debug`, condições de breakpoint que disparam callback Tcl, leitura direta de memória/registradores), o fluxo seria:
  1. Instalar pequena rotina de hook de erro (via poke, no início do programa carregado)
  2. Configurar condição de debug/breakpoint no endereço desse hook
  3. Quando disparar, ler da memória a linha atual e o código de erro
  4. Repassar isso de volta para o IDE (via socket) para destacar a linha correspondente no editor

**Nível de esforço**: itens 1 e 2 são baixo esforço (comandos prontos do protocolo). Item 3 é o mais trabalhoso — não porque o openMSX não suporte (suporta bem via debug/Tcl), mas porque exige escrever a rotina de hook e mapear com precisão onde o interpretador guarda "linha atual em execução" (pode variar entre BIOS/versões de BASIC).

---

## 11. Fechamento da sessão de planejamento

Resumo do escopo definido até aqui:

- **IDE completa em PureBasic** com editor MSX BASIC + Z80 assembly (highlighting via Scintilla/EditorGadget)
- **Basic Dignified reescrito** nativo (resolução de labels, numeração, includes)
- **Editores visuais**: sprite/char, som (SOUND/PSG), tracker, MML (PLAY), draw/line/circle
- **Três saídas diferentes**: ASCII, tokenizado, ROM via msxbas2rom
- **Extensões NestorBASIC** com sistema de aliases
- **Controle do openMSX** para rodar e debugar direto do IDE (envio de programa, input simulado, detecção de erro com retorno à linha no editor)

---

## 12. Log de implementação (Claude Code)

> Diferente das seções 1–11 (transcrição reconstruída do chat de planejamento original no claude.ai,
> antes de qualquer código existir), esta seção é um log cronológico do que foi efetivamente
> implementado depois, via Claude Code, sessão a sessão. Ver `docs/SPEC.md` para o detalhe técnico de
> cada módulo e `README.md` para o changelog resumido — aqui fica só um resumo curto por sessão,
> como continuação natural da transcrição de planejamento acima.

**2026-07-18** — Editor de sprites e sistema de projeto:

- **Editor de sprites** (menu **Criar → Sprite...**, módulo 4 do `SPEC.md`): grade 8×8/16×16, palheta
  fixa de 16 cores do MSX1, modos MSX1 (sprite inteiro com uma cor) e MSX2 (uma cor por linha,
  aplicada automaticamente). Ferramentas com ícone próprio (desenhadas em memória, sem depender de
  arquivo externo): lápis, borracha, pincel 2×2, balde de preenchimento, reta, retângulo e elipse —
  as três últimas com prévia ao vivo da forma, marcador piscando no primeiro ponto, e cancelamento por
  Esc ou botão direito do mouse. Rotacionar (com quebra) e deslocar (sem quebra) nas quatro direções,
  inverter, limpar.
- **Sistema de projeto** (módulo 13 do `SPEC.md`): cada projeto MSX vira um arquivo `.msxproject`
  (SQLite puro, driver estático do PureBasic — sem DLL extra para distribuir). Sem nenhum parâmetro na
  linha de comando, a IDE já abre um projeto implícito `noname.msxproject` num arquivo temporário;
  **Arquivo → Novo projeto...**/**Abrir projeto...** trocam de projeto (oferecendo salvar o atual
  primeiro, se tiver conteúdo não salvo); ao sair, pergunta onde salvar em definitivo se o projeto
  implícito ainda tiver conteúdo registrado. Por enquanto só a tabela de Sprites está de fato ligada a
  um editor — os demais tipos de conteúdo do projeto (Basic, Assembly, telas, sons, músicas, listagens
  LM, documentos) ganham tabela quando tiverem editor próprio.
- O editor de sprites usa o sistema de projeto: cada sprite tem número sequencial e uma tag (até 16
  caracteres), grava no projeto atual via **Registrar**, **Novo** cria o próximo sprite da sequência,
  botões de navegação vão para o primeiro/anterior/próximo/último sprite já registrado, e
  **Copiar**/**Colar** duplicam um sprite para outro número.
- Validação de dados feita por um novo harness de console (`editor/tools/ProjectDBTestCli.pb`) — a
  automação de clique no canvas do editor de sprites se mostrou não confiável neste ambiente (máquina
  de uso interativo real do usuário, não um ambiente de teste isolado), então o harness ficou como
  principal forma de garantir que os dados batem (criar, salvar, listar, recarregar byte a byte,
  sobrescrever sem duplicar, promover para arquivo permanente, reabrir do zero).
- Nome padrão de aba sem título mudou de `"Sem titulo N"` para `"nonameN"`. Versão embutida no
  executável atualizada de `5.3.1` para `5.5.3`.

---

## Notas para continuar com Claude Code / CLI

- Este documento foi reconstruído a partir do histórico de conversas do Claude.ai (busca por trechos relevantes), então pode haver pequenas lacunas de conteúdo (marcadas no texto onde identificadas). Nada foi inventado — apenas reorganizado cronologicamente.
- Nenhuma linha de código foi escrita ainda nesta fase (seções 1–11); tudo era levantamento de viabilidade e arquitetura. A seção 12 em diante é o log real de implementação via Claude Code, continuado sessão a sessão.
- Linguagem principal do projeto: **PureBasic** (licença vitalícia já disponível).
- Ferramentas/dependências externas mencionadas: sjasmplus, z88dk (referência de opcodes Z80, não como dependência de runtime), msxbas2rom (CLI externo, chamado via subprocess), openMSX (controle via socket/named pipe com protocolo XML).
