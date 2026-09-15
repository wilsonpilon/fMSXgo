# Mamute Assembler

Referência do monitor `MON>` do Mamute Assembler - o mesmo texto de ajuda escrito originalmente para
o Mamute Assembler no paleobasic (a IDE PureBasic que serviu de inspiração/fonte deste projeto), adaptado
apenas na formatação para o visualizador de ajuda do msxIDE. Como o msxIDE é uma TUI (não uma GUI com
janelas/mouse/diálogos do Windows), alguns comandos aqui descritos com janela própria, grade de edição
ao vivo ou teclado numérico remapeável foram implementados de forma **simplificada, mas funcional**,
dentro do terminal `MON>` - a saída real de cada comando (mensagens `?ERRO DE SINTAXE`, `ACHADO EM`,
`GRAVADO EM`, etc.) é o que efetivamente roda no msxIDE hoje; o texto abaixo permanece como a
documentação original, sem cortes. A **impressora virtual** (`## Impressora Virtual`, logo abaixo) já
gera PDF de verdade, sem simplificação nenhuma.

## Introdução

O **Mamute Assembler** (`Mamute -> Abrir Mamute Assembler`) é uma janela estilo "monitor" - inspirada
nos montadores de linha de comando dos computadores de 8 bits dos anos 80 (o **MegaAssembler** original
foi a inspiração direta) - em vez de uma tela cheia de campos e botões, um prompt `MON>` aceita comandos
digitados, um de cada vez.

Fundo preto, texto monoespaçado verde: visual deliberadamente diferente do resto da IDE - pra lembrar um
terminal de verdade daquela época, não um diálogo moderno.

**Não é o Editor Hexa nem os assemblers já existentes** (Basic Dignified, asMSX) - é uma ferramenta à
parte, com seu próprio pequeno conjunto de comandos, dividido em **duas famílias** (ver as seções
`## Comandos do MegaAssembler` e `## Comandos do SUPER-X` logo abaixo, cada comando com sua própria
subseção):

- **MegaAssembler** - o assembler de linha de comando original que inspirou este terminal `MON>`:
  **BA / QUIT**, **PAGE**, **DM**, **ZAP**, **SCR**, **SH**, **MS**, **LOAD**, **SAVE**, **M**, **S**,
  **C**, **D**, **P**, **V**, **T**, **F**, **G**, **X**, **R**, **L**, **LP**, **EDIT**, **CLS** (**G** e
  **R** ainda só validam a sintaxe e confirmam no log - a execução de programas e o carregamento de
  assemblados ficam pra uma fase futura).
- **SUPER-X** - um segundo monitor/debugger clássico de MSX sendo incorporado aos poucos, comando por
  comando, todos com o prefixo `X`: **XCL** (calculadora), **XD**/**XF** (despejo de memória com
  endereçamento estendido + seletor de formato), **XA** (listagem ASCII), **XI** (listagem
  disassemblada) - já implementados, o resto do roteiro está na seção `## Comandos do SUPER-X`.

**Os endereços/setores digitados em qualquer comando são sempre em hexadecimal** - o padrão de entrada do
Mamute Assembler inteiro.

O Mamute Assembler simula o **sistema de slots do MSX de verdade**: 4 slots (0-3), cada um com 4 páginas
de 16KB (`Página 0` = `0000-3FFF`, `Página 1` = `4000-7FFF`, `Página 2` = `8000-BFFF`, `Página 3` =
`C000-FFFF`) - 16 blocos de memória ao todo. `Configurar -> Mamute (Memória)` define o que existe
FISICAMENTE em cada um desses 16 blocos (Vazio/RAM/ROM/BIOS/BASIC/EXTBIOS, e um arquivo pra carregar
quando for ROM/BIOS/BASIC/EXTBIOS). Blocos RAM começam sempre em branco; blocos ROM/BIOS/BASIC/EXTBIOS
com arquivo configurado são lidos de verdade toda vez que o terminal abre - se o arquivo for menor que
16KB, o resto do bloco fica em branco.

A mesma tela de configuração também define o **tamanho da VRAM simulada** (16KB/32KB/64KB/128KB/192KB,
usada pelo comando `V`) - endereço plano, sem banco/página, já que a VRAM de um MSX de verdade nunca
fica mapeada no espaço de endereços do Z80 (é acessada pelas portas do VDP).

`Configurar -> Impressora` define o **papel da impressora virtual** (A4 ou contínuo/zebrado) usado por
`P`/`V`/`LP` e por qualquer comando prefixado com `?` - ver `## Impressora Virtual` logo abaixo.

## Impressora Virtual

O Mamute Assembler tem uma impressora virtual de verdade: qualquer listagem (dump de memória,
disassembly, calculadora, etc.) pode virar um **arquivo PDF real** em vez de só aparecer no log da
tela - um diálogo pede o nome do arquivo, o PDF é gerado na hora, e (se `Configurar -> Impressora ->
Abrir PDF automatico` estiver ligado, o padrão) já abre sozinho no visualizador de PDF padrão do
Windows.

**Duas formas de imprimir:**

- **Comandos dedicados** `P`, `V`, `LP` (e, dentro do `EDIT`, `LSEARCH`/`A P`/`A H`) - sempre perguntam o
  nome do arquivo `.pdf` e gravam, nunca mostram nada na tela.
- **Prefixo `?`** na frente de QUALQUER outro comando do Mamute que não dependa de mais interação depois
  de rodar (das duas famílias, MegaAssembler e SUPER-X) - em vez de mostrar o resultado no log, pede o
  nome do `.pdf` e imprime aquele resultado. Exemplo: `?D 4000,4010` imprime o mesmo despejo que `D
  4000,4010` mostraria na tela. Comandos que suportam `?`: `PAGE`, `DM`, `ZAP`, `SCR`, `SH`, `MS`, `C`,
  `D`, `T`, `F`, `G`, `R`, `L`, `X` (só sem argumento - com argumento entra no modo de edição de
  registrador, que é interativo), `XCL`, `XD`, `XA` e `XI`. Comandos que **não** suportam (mostram `?IMPRESSAO
  NAO APLICAVEL A ESTE COMANDO`): `BA`/`QUIT`, `CLS`, `LOAD`, `SAVE`, `M`/`S` sem argumento (abrem uma
  grade viva), `EDIT`, `HELP`, `X` com argumento, e `P`/`V`/`LP` (já são comandos de impressão, prefixar
  com `?` não faz sentido). Convenção herdada do manual original do SUPER-X (`?D0 100` = "mostra na tela
  E na impressora"), mas estendida aqui pra qualquer comando não-interativo das duas famílias, não só os
  portados do SUPER-X.

**`Configurar -> Impressora`:**

- **Papel** - `A4` (210x297mm, margem de 1cm nos 4 lados) ou `Continuo` (formulário CPD picotado,
  9.5x11 polegadas de carro estreito, **sempre 66 linhas por formulário** - limite físico do papel, não
  muda com a fonte escolhida).
- **Fonte** - `Normal` (10 caracteres por polegada) ou `Condensada` (17 caracteres por polegada, quase o
  dobro de colunas por linha) - mesma nomenclatura de densidade de uma impressora matricial de verdade.
  No papel A4 a fonte também define o espaçamento entre linhas; no papel contínuo o espaçamento vertical
  é sempre fixo (pra manter as 66 linhas/formulário), só a largura de cada caractere muda.
- **Zebrado** - `Verde` ou `Azul`, a cor das faixas alternadas **linha a linha** (1 colorida, 1 em
  branco) no papel contínuo, igual ao formulário original - não aparece no A4. A faixa cobre o
  **formulário inteiro** (todas as 65 linhas de conteúdo), não só as linhas que têm texto de verdade -
  igual o papel picotado real, que já vem impresso assim de fábrica.
- **Abrir PDF automatico** - liga/desliga abrir o PDF gerado sozinho no visualizador padrão do Windows
  (ligado por padrão).

O papel contínuo também desenha os furos redondos clássicos nas duas margens laterais, espaçados a cada
meio polegada (o passo real de papel picotado com tração lateral), e uma **linha picotada tracejada**
simulando a dobra/rasgo entre formulários contíguos a cada 66 linhas (uma página do PDF já é um
formulário inteiro, então a marca fica na borda inferior de cada página).

## Comandos do MegaAssembler

Os comandos abaixo vêm do **MegaAssembler** original, o montador de linha de comando de 8 bits que
inspirou diretamente este terminal `MON>` - resolvem sempre pelo mapeamento `PAGE` ativo agora (nunca
por um sufixo de slot/sub-slot/VRAM explícito, esse esquema é exclusivo dos comandos do `## Comandos do
SUPER-X`, mais abaixo).

### BA / QUIT

Encerra a janela do Mamute Assembler - equivalente a fechar pelo X da janela. Sem argumentos, funciona
em qualquer um dos dois nomes (não diferencia maiúsculas de minúsculas).

**Sintaxe:**

```
MON>BA
```

ou

```
MON>QUIT
```

Qualquer outra entrada não reconhecida ainda mostra `?COMANDO INVALIDO`.

### PAGE

Mostra ou troca o **mapeamento ativo agora mesmo**: pra cada uma das 4 páginas que o Z80 enxerga (0-3),
qual dos 4 slots físicos (`Configurar -> Mamute (Memória)`) está comutado ali - exatamente como o
registrador de slot primário de um MSX de verdade. Isso é diferente da configuração física: um slot pode
ter RAM/ROM/BIOS/BASIC configurados nele, mas só o slot MAPEADO numa página é o que os próximos comandos
que mostram/inserem dados vão realmente enxergar naquele endereço.

**`PAGE`** (sem argumentos) - coloca as 4 páginas no slot marcado como RAM (o primeiro slot, varrendo 0
a 3, que tiver RAM configurada em alguma página). Mostra `?SEM RAM CONFIGURADA` se nenhum slot tiver RAM
ainda.

**`PAGE ?`** - só mostra o mapeamento ativo, sem mudar nada:

```
MON>PAGE ?
PAGE0(0000-3FFF) SLOT 0
PAGE1(4000-7FFF) SLOT 0
PAGE2(8000-BFFF) SLOT 3
PAGE3(C000-FFFF) SLOT 3
```

**`PAGE X[,Y][,Z][,K]`** - troca o mapeamento: `X` é o slot da página 0, `Y` da página 1, `Z` da página
2, `K` da página 3 (cada um de 0 a 3). **No msxIDE, ao contrário do manual original do MegaAssembler,
cada posição é opcional** - deixar um campo em branco (vírgula dupla, ou faltando no final) deixa aquela
página como está, sem precisar informar as 4 de uma vez. Exemplos:

```
MON>PAGE 2,2,2,2
```

coloca as 4 páginas no slot 2;

```
MON>PAGE 1
```

muda só a página 0 pro slot 1, deixando as demais como estavam;

```
MON>PAGE ,,2
```

muda só a página 2 pro slot 2, deixando as demais como estavam. Depois de aplicar, o novo mapeamento é
mostrado na hora (igual `PAGE ?`), pra confirmar visualmente o que mudou. Argumento fora de 0-3 mostra
`?ARGUMENTO INVALIDO`.

### DM

**Despejo de Memória** - o primeiro comando que realmente lê a memória simulada. Mostra 128 bytes (16
linhas de 8 bytes) a partir do endereço informado, em hexa e ASCII lado a lado.

**Sintaxe:**

```
MON>DM <endereco>[,<deslocamento>]
```

`<endereco>` (obrigatório) - onde começa o despejo, em hexa (0000-FFFF). `<deslocamento>` (opcional,
também hexa, com sinal `+`/`-` opcional na frente) - de `-7F` a `80` - "criptografa/descriptografa" só a
INTERPRETAÇÃO ASCII exibida: cada byte mostrado como texto é o valor cru mais o deslocamento (módulo
256) - o bloco hexa sempre mostra o byte cru da memória, sem nenhuma alteração. Exemplo:

```
MON>DM 4000,-20
```

**Layout de cada linha:** endereço na primeira coluna, 8 bytes em hexa nas colunas seguintes, os 8
caracteres correspondentes como um bloco no final. Caractere que não dá pra imprimir vira `.`. Abaixo da
grade, duas linhas de status: `Endereco:` (o endereço base atual) e `Desloc.:` (o deslocamento ativo).

**Nesta versão do msxIDE**, o `DM` é um despejo somente-leitura direto no scrollback do terminal (a
grade navegável/editável ao vivo do original fica pra uma fase futura) - pra gravar um byte, use
`M <endereco> <byte>` (ver o tópico `M`).

Escrita **só tem efeito em células mapeadas como RAM agora** (`PAGE`/`Configurar -> Mamute (Memória)`) -
ROM, BIOS, BASIC e Vazio são somente-leitura, igual hardware real (não há o que escrever fisicamente
ali).

### ZAP

**Editor de Setores de disco** - muito parecido com o `DM`, mas em vez de mostrar a memória simulada do
MSX, abre uma **imagem de disco (.dsk)** e mostra os bytes crus dela, setor a setor (512 bytes/setor).
O ZAP não interpreta a estrutura FAT12 (boot sector, FAT, diretório) - só lê bytes crus por posição,
igual um editor de setor de verdade da época.

**Sintaxe:**

```
MON>ZAP <setor inicial>[,<deslocamento>]
```

`<setor inicial>` (obrigatório, hexa) - o setor onde a grade começa (setor 0 = boot sector).
`<deslocamento>` (opcional, hexa com sinal, `-7F` a `80`) - idêntico ao do `DM`: "criptografa/
descriptografa" só a interpretação ASCII exibida, nunca o byte cru.

**Ao rodar, primeiro pede um arquivo .dsk.** Cancelar a escolha cancela o comando inteiro, sem abrir
nada.

**Layout** idêntico ao `DM` - a diferença é o rótulo de cada linha, que mostra o deslocamento DENTRO DO
SETOR atual (`000` a `1F8`), e as linhas de status mostram `Setor:` + `Byte:` (endereço absoluto dentro
do arquivo) em vez de `Endereco:`.

**Nesta versão do msxIDE**, o `ZAP` é um despejo somente-leitura do setor escolhido - a edição/gravação
de setor de volta no `.dsk` fica pra uma fase futura.

### SCR

**Display gráfico da memória** - mostra uma tela FIXA de 256x192 pixels (32x24 caracteres 8x8, a mesma
resolução de um SCREEN 2/1 real do MSX) preenchida com a memória a partir de um endereço, cada caractere
formado por 8 bytes/8 pixels (1 bit = 1 pixel), exatamente como a Pattern Generator Table do SCREEN 1/2
ou a Sprite Pattern Table de um MSX real - útil pra visualizar fontes de caracteres e sprites direto na
memória simulada.

**Sintaxe:**

```
MON>SCR <endinic>,<dx>,<dy>[,<modo>]
```

Todos os números são hexa. `<endinic>` (obrigatório) - endereço do primeiro caractere. A TELA em si é
sempre 256x192 - `<dx>`/`<dy>` (obrigatórios, >=1) NÃO mudam esse tamanho, eles definem o "azulejo"
(bloco de `dx`x`dy` caracteres) usado pra ladrilhar a tela inteira, da esquerda pra direita e de cima
pra baixo. `<modo>` (opcional, `0` ou `1`, default `0`) - ordem em que os blocos de 8 bytes são lidos
DENTRO de cada azulejo:
- **`0` (horizontal)** - linha por linha dentro do azulejo.
- **`1` (vertical)** - coluna por coluna dentro do azulejo, a mesma ordem real de armazenamento de
  sprites do MSX (por isso o manual original chama esse modo de "formato sprite").

Exemplo pra ver a tabela de caracteres ASCII de uma ROM de fonte carregada em `Configurar -> Mamute
(Memória)` (endereço 1BBF é onde a maioria das BIOS de MSX guarda o início da Pattern Generator Table;
`<dx>`=`<dy>`=`1` ladrilha a tela toda com 1 caractere por azulejo):

```
MON>SCR 1BBF,1,1
```

**Nesta versão do msxIDE**, o `SCR` mostra uma visualização reduzida em ASCII (`#`/`.`) de UM único
azulejo `dx`x`dy`, não a tela 256x192 completa ladrilhada - a navegação por setas, a moldura de edição
2x2 caracteres e o modo de edição pixel a pixel do original ficam pra uma fase futura.

### SH

**Busca de bytes ou texto na memória** - procura uma sequência de bytes exatos (com curingas opcionais)
ou um texto (testando automaticamente todos os deslocamentos possíveis). Mostra o resultado direto no
log do `MON>`.

**Sintaxe (modo bytes):**

```
MON>SH [<endereco>],<byte>[,<byte>...]
```

`<endereco>` (hexa) - onde começar a busca. Se for omitido (a vírgula continua ali, só o número antes
dela que falta - ex.: `SH ,2A,40`), a busca continua do endereço onde a ÚLTIMA busca deste comando achou
algo, mais 1 - só funciona depois de um `SH` que já tenha achado algo nesta mesma sessão da janela do
Mamute Assembler.

Cada `<byte>` é 1-2 dígitos hexa. **Deixar um `<byte>` vazio (vírgula dupla) vira curinga** - "esse byte
pode ser qualquer um". Exemplos:

```
MON>SH 4000,2A,40,0C
```

procura a sequência exata `2A 40 0C` a partir de `4000`;

```
MON>SH 4000,2A,,0C
```

procura 3 bytes onde o 1o é `2A`, o 2o pode ser qualquer coisa, e o 3o é `0C`.

**Sintaxe (modo texto):**

```
MON>SH [<endereco>],'<texto>
```

Um apóstrofo seguido do texto (sem precisar fechar com outro apóstrofo), 2+ caracteres. Diferente do
modo bytes, a busca de texto testa TODOS os deslocamentos possíveis (`-7F` a `80`, mesma faixa do
`DM`/`ZAP`) em cada posição candidata - acha tanto o texto puro (deslocamento `+00`) quanto texto
"cifrado" por um deslocamento fixo (truque comum em jogos antigos pra não deixar diálogo legível num
editor de disco cru). Exemplo:

```
MON>SH 3F41,'teste
```

**Resultado:** `ACHADO EM <endereco>` (modo bytes) ou `ACHADO EM <endereco> DESLOC <deslocamento>` (modo
texto, com sinal `+`/`-`), ou `NAO ENCONTRADO` se a busca varrer os 65536 endereços (com volta ao
início) sem achar nada.

### MS

**Grava uma string na memória** - escreve o texto digitado, byte a byte, a partir de um endereço, com um
deslocamento opcional. Confirma no log do `MON>`.

**Sintaxe:**

```
MON>MS <endereco>,[<deslocamento>],'<texto>
```

`<endereco>` (obrigatório, hexa) - onde começa a gravação. `<deslocamento>` (opcional, hexa com sinal
`+`/`-`, `-7F` a `80`, mesma faixa do `DM`/`ZAP`/`SH`) - `0` se omitido. Um apóstrofo seguido do texto
(sem precisar fechar com outro apóstrofo) - qualquer vírgula dentro do texto NÃO quebra o comando, tudo
depois do apóstrofo vira parte do texto.

Cada caractere é gravado como `(codigo do caractere - deslocamento) & FF` - a MESMA fórmula usada pelo
bloco de texto do `DM` ao editar. Isso significa que o texto gravado com um deslocamento diferente de
zero fica "cifrado" nos bytes crus - só volta a aparecer legível se depois for lido (`DM`) ou procurado
(`SH`) com esse MESMO deslocamento. Exemplo:

```
MON>MS 9A15,20,'nome
```

grava a string `nome` a partir do endereço `9A15` com deslocamento `+20` - `DM 9A15,20` (ou `SH ,'nome`
após ajustar o deslocamento) mostraria `nome` de volta.

Escrita **só tem efeito em células mapeadas como RAM agora** (`PAGE`) - mesma regra do `DM`, ROM/BIOS/
BASIC/Vazio são somente-leitura (recusa silenciosa, sem aviso separado).

### LOAD

**Carrega um arquivo na memória simulada** - totalmente interativo: não se digita nome de arquivo no
comando. Basta digitar `LOAD` sozinho:

```
MON>LOAD
```

Um nome de arquivo pode ser digitado depois do `LOAD` (`MON>LOAD alfabeto.rom`) - ele só pré-preenche o
campo de nome na janela de escolher arquivo. O arquivo que de fato vai ser carregado é sempre o que for
confirmado na janela. Cancelar a escolha cancela o comando inteiro, sem gravar nada.

Em seguida, **sempre** é perguntado em qual **Slot (0-3)** carregar - o slot que tiver RAM configurada
(`Configurar -> Mamute (Memória)`) é sugerido como padrão, mas qualquer slot pode ser escolhido.

**O que acontece depois depende da extensão do arquivo:**
- **`.ROM`** (cartucho) - carregado a partir do endereço `4000` (Página 1). Se tiver mais de 16KB (até
  32KB), ocupa também a Página 2 (`8000`). Arquivos com mais de 32KB não são suportados (precisariam de
  troca de banco, que este simulador não faz) - `?ROM MAIOR QUE 32KB NAO SUPORTADA`.
- **Binário com cabeçalho BSAVE** (qualquer outra extensão, ex.: `.bin`) - se o arquivo começar com o
  cabeçalho real do BSAVE do MSX (byte `FE` seguido de endereço inicial/final/execução, 2 bytes cada),
  carrega automaticamente no endereço indicado pelo cabeçalho.
- **Binário sem cabeçalho** - se não começar com `FE`, pergunta o **endereço inicial** (hexa) antes de
  carregar.

**`.CAS` ainda não é suportado** - mostra `?ARQUIVOS .CAS NAO SUPORTADOS AINDA` e cancela, em vez de
tentar interpretar errado.

Ao final, o resultado é mostrado no log: `CARREGADO NO SLOT <slot> EM <endereco> - TAMANHO <tamanho> -
FIM <endereco final>`.

**Diferente do `DM`/`MS`**: `LOAD` grava DIRETO na memória física do slot escolhido, independente do que
o `PAGE` tem mapeado ativo agora (simula "inserir um cartucho/carregar dado naquele slot", não escrever
pela CPU). Também ajusta a configuração física das páginas tocadas (RAM pro binário, ROM pro `.rom`) -
mas só em memória, nunca grava na configuração salva; fechar e reabrir a janela do Mamute Assembler volta
pra configuração salva de antes, igual desligar e ligar um MSX de verdade tira o cartucho.

### SAVE

**Grava um bloco de memória num arquivo** - o inverso do `LOAD`.

**Sintaxe:**

```
MON>SAVE [<nome>][,<endinic>,<endfim>[,<endexec>]]
```

Tudo opcional - `MON>SAVE` sozinho pergunta tudo interativamente. `<nome>` sugere o nome do arquivo. Se
`<endinic>`/`<endfim>` forem informados (sempre os dois juntos, `<endexec>` opcional separado - vazio
assume igual ao inicial), pré-preenchem o intervalo a gravar. Exemplo:

```
MON>SAVE rom.bin,4000,7FFF
```

**Passos:**
- **Arquivo** - nome/caminho de saída.
- **Slot (0-3)** - de qual slot físico ler os bytes. Sugerido a partir do que o `PAGE` tem mapeado ATIVO
  agora na página do endereço inicial - sempre editável pra qualquer slot.
- **Endereço inicial / final** - o bloco a gravar (inclusive nos dois extremos), obrigatórios na hora de
  salvar.
- **Endereço de execução** - vai no cabeçalho; deixar vazio usa o mesmo valor do inicial.
- **Formato** - `BIN` (cabeçalho real do BSAVE do MSX: byte `FE` + inicial + final + execução, 2 bytes
  cada) ou `ROM` (mesma ideia, mas com `AB` no lugar do `FE` - formato próprio deste simulador, NÃO é o
  cabeçalho real de 16 bytes de um cartucho MSX de verdade). Escolhido automaticamente como `ROM` se o
  nome do arquivo terminar em `.rom` (ou `BIN` caso contrário).

Ao gravar com sucesso, confirma no log do `MON>`: `SALVO "<arquivo>" - SLOT <slot> - <inicial>-<final> -
TAMANHO <tamanho>`.

**Igual o `LOAD`**: lê DIRETO da memória física do slot escolhido, sem passar pelo `PAGE` - o slot lido
é sempre exatamente o escolhido, não o que estiver mapeado ativo no momento.

### M

**Edição rápida de memória** - mesma grade de 128 bytes (16 linhas de 8, hexa+ASCII) do `DM` - a
diferença é como um byte é editado.

**Sintaxe:**

```
MON>M [<endereco>]
```

`<endereco>` opcional (hexa) - se não for informado, reabre exatamente onde ficou da última vez (só
funciona depois que o `M` já abriu pelo menos uma vez nesta sessão).

**Nesta versão do msxIDE**, `M <endereco> <byte>` grava um byte direto e confirma `GRAVADO <byte> EM
<endereco>` (a grade viva com auto-avanço do original, digitando dois dígitos hexa direto sobre a
célula, fica pra uma fase futura); `M [<endereco>]` sozinho mostra a mesma grade de 128 bytes do `DM`
(somente-leitura).

Escrita **só tem efeito em células mapeadas como RAM agora** (`PAGE`) - mesma regra do `DM`.

### S

**Igual ao `M`** (mesma grade, mesmo jeito de editar) - a ÚNICA diferença no manual original é QUAIS
teclas do teclado representam cada dígito hexa (um teclado numérico reduzido configurável, por padrão o
bloco `1234/QWER/ASDF/ZXCV` mapeado pra `0-F`, pensado pra digitar hexa rápido num teclado sem numpad
dedicado).

**Sintaxe:**

```
MON>S [<endereco>]
```

`<endereco>` opcional, mesma regra do `M` - mas o `S` guarda seu próprio "último endereço", separado do
`M`.

**Nesta versão do msxIDE**, como o terminal já aceita dígitos hexa (`0-9`/`A-F`) direto do teclado, `S` é
simplesmente um **alias completo de `M`** (mesmo formato de grade, mesmo `S <endereco> <byte>` pra
gravar) - o remapeamento de teclado numérico do manual original não se aplica a um terminal de texto.

### C

**Escolhe o modo de exibição** que os comandos `D`, `P` e `V` (dump de memória formatado) vão usar.
Sozinho não mostra nada além da confirmação - só guarda a escolha pra esses três comandos consultarem.

**Sintaxe:**

```
MON>C <modo>
```

`<modo>` de `0` a `3`:
- **`0`** - hexadecimal + ASCII, 4 bytes por linha.
- **`1`** - igual ao `0`, mas 16 bytes por linha (pra telas/impressoras de 80 colunas).
- **`2`** - só hexadecimal, 8 bytes por linha, com um checksum no final de cada linha = soma dos 8
  bytes + o byte baixo do endereço inicial da linha (tudo módulo 256).
- **`3`** - igual ao `2`, mas o checksum é só a soma dos bytes, sem somar o endereço.

Exemplo:

```
MON>C 1
MODO 1: HEXA+ASCII, 16 BYTES/LINHA
```

*Nota: precisa de espaço entre `C` e o número (`C 1`) - o `C1` colado do manual original do
MegaAssembler não é reconhecido, porque todo comando aqui separa o verbo dos argumentos pelo primeiro
espaço digitado.*

O modo escolhido dura só enquanto a janela do Mamute Assembler estiver aberta - fechar e reabrir volta
pro modo `0`.

### D

**Despejo formatado de memória, direto no log do `MON>`** - mesma memória RAM/ROM que o `DM` enxerga
(resolve pelo mapeamento `PAGE` ativo agora), formatado conforme o modo escolhido em `C` (padrão: modo
`0`).

**Sintaxe:**

```
MON>D <endinic>[,<endfim>]
```

Sem `<endfim>`, mostra só 16 bytes a partir de `<endinic>`. Com os dois, mostra o intervalo inteiro
(inclusive) - `<endfim>` não pode ser menor que `<endinic>`, e nenhum dos dois passa de `FFFF` (sem dar
a volta pro `0000` como o `SH`/`M` fazem).

Exemplo:

```
MON>D 4000,400F
```

### P

**Igual ao `D`**, mas ao invés de mandar o despejo pro log, gera um **PDF de verdade** na impressora
virtual (`## Impressora Virtual`, acima) - papel/fonte/zebrado conforme `Configurar -> Impressora`.

**Sintaxe:**

```
MON>P <endinic>[,<endfim>]
```

Mesmas regras de `<endinic>`/`<endfim>` do `D` (lê a mesma RAM/ROM mapeada agora). Cancelar a janela de
salvar não gera arquivo nenhum - só mostra `CANCELADO`.

### V

**Igual ao `P`**, mas lê da **VRAM simulada** em vez da RAM/ROM - endereço plano, sem `PAGE` nem banco
algum (a VRAM de verdade de um MSX nunca fica mapeada no espaço de endereços do Z80; é acessada pelas
portas do VDP, então esta ferramenta simula ela num bloco de memória à parte, `Configurar -> Mamute
(Memória)` -> tamanho de VRAM: **16KB**/**32KB** (MSX1), **64KB**/**128KB** (MSX2) ou **192KB**
(MSX2+/turboR).

**Sintaxe:**

```
MON>V <endinic>[,<endfim>]
```

`<endinic>`/`<endfim>` aqui podem ter até 5 dígitos hexa (a VRAM máxima configurável, 192KB, passa de
`FFFF`) e são validados contra o tamanho de VRAM configurado agora - passar do teto é `?ERRO DE SINTAXE`,
sem dar a volta.

*Nota: ainda não existe nenhum comando que ESCREVA na VRAM simulada nesta versão - por enquanto ela
começa sempre zerada.*

### T

**Transfere (copia) um bloco de memória** RAM/ROM (mesma memória mapeada agora pelo `PAGE`) de um
intervalo de endereços pra outro.

**Sintaxe:**

```
MON>T <endinic>,<endfim>,<enddest>
```

Copia o bloco de `<endinic>` a `<endfim>` (inclusive) pro bloco do mesmo tamanho iniciado em
`<enddest>`. Exemplo:

```
MON>T 4000,7FFF,8000
```

copia o bloco de `4000` a `7FFF` para `8000` em diante.

Se origem e destino se sobrepõem, a cópia é feita na ordem certa pra não corromper dado ainda não lido
(de trás pra frente quando o destino vem depois da origem, de frente pra trás caso contrário) - mesmo
cuidado de um `memmove` de verdade.

`<endfim>` não pode ser menor que `<endinic>`, e o bloco copiado não pode passar de `FFFF` no destino
(sem dar a volta pro `0000`) - qualquer um dos dois casos é `?ERRO DE SINTAXE`. Escrita silenciosa em
células do destino que não sejam RAM (mesma regra do `DM`/`MS`).

### F

**Preenche um bloco de memória** RAM/ROM (mesma memória mapeada agora pelo `PAGE`) inteiro com um único
byte repetido.

**Sintaxe:**

```
MON>F <endinic>,<endfim>,<byte>
```

Exemplo:

```
MON>F 8000,C000,FF
```

preenche o bloco de `8000` a `C000` (inclusive) com `FF` em todo byte.

`<endfim>` não pode ser menor que `<endinic>`. Escrita silenciosa em células que não sejam RAM (mesma
regra do `DM`/`MS`/`T`).

### G

**Ainda NAO executa nada** - por enquanto só reconhece e valida a sintaxe do comando, confirmando no log
que o Mamute Assembler entendeu o pedido. A execução de verdade de programas na memória simulada (com
breakpoints, registradores etc.) fica pra uma fase futura deste projeto.

**Sintaxe:**

```
MON>G <endinic>[,<brkpnt1>[,<brkpnt2>]]
```

`<endinic>` (obrigatório) e até dois endereços de breakpoint opcionais - todos validados como endereço
hexa de 4 dígitos, mesma sintaxe planejada pro comando de verdade quando existir (iniciaria a execução
em `<endinic>`, carregando os registradores com o que o `X` guardou, parando ao atingir
`<brkpnt1>`/`<brkpnt2>`).

### X

**Mostra ou edita os registradores do Z80 simulado.** Sem argumento, mostra os 7 pares de registrador de
uma vez. Com argumento, entra num modo de edição sequencial - aceita tanto um PAR de registrador (`AF`,
`BC`, `DE`, `HL`, `IX`, `IY`, `SP` - editado como um valor único de 16 bits/4 dígitos hexa) quanto um
registrador de UM BYTE isolado (`A`, `F`, `B`, `C`, `D`, `E`, `H`, `L` - 2 dígitos hexa).

**Sintaxe:**

```
MON>X [<reg>]
```

Exemplos:

```
MON>X
AF=0000 BC=0000 DE=0000 HL=0000
IX=0000 IY=0000 SP=0000
```

```
MON>X BC
```

muda o prompt do terminal pra mostrar o valor atual de `BC` e pede o novo valor - confirmar com **ENTER
sem digitar nada mantém** o valor (e passa pro próximo registrador da sequência: `DE`, `HL`, `IX`, `IY`,
`SP`); digitar um valor hexa válido grava e também avança pro próximo.

```
MON>X A
```

mesma ideia, mas caminhando pelos BYTES isolados: `A`, `F`, `B`, `C`, `D`, `E`, `H`, `L`.

*Nota: o manual original do MegaAssembler só tem os registradores de 1 byte (`A`-`L`) mais `X`/`Y`/`S`
como abreviação de `IX`/`IY`/`SP` - os nomes de par diretos (`AF`/`BC`/`DE`/`HL`) editáveis como um valor
só de 16 bits são uma extensão desta ferramenta.*

Os registradores duram só enquanto a janela do Mamute Assembler estiver aberta - fechar e reabrir zera
todos de novo (mesmo espírito volátil do `PAGE`/`C`). Quando o comando `G` (execução de programas) for
implementado de verdade, vai carregar o Z80 simulado com estes valores.

### R

**Ainda NAO faz nada além de confirmar no log** que o carregamento de um programa assemblado depende do
assemblador Z80 embutido nesta ferramenta - que também fica pra uma fase futura. Nenhum argumento é
validado por enquanto.

**Sintaxe:**

```
MON>R [<offset>]
```

### L

**Disassembla a memória RAM/ROM** (mesma memória mapeada agora pelo `PAGE`) direto no log do `MON>` - um
disassembler Z80 de verdade, com o conjunto de instruções documentado inteiro mais as formas não
documentadas mais estáveis/conhecidas (`IXH`/`IXL`/`IYH`/`IYL`, formas indexadas do `CB`).

**Sintaxe:**

```
MON>L [<endinic>[,<endfim>]]
```

- **Os dois endereços** - disassembla de `<endinic>` até ultrapassar `<endfim>` (a instrução que começa
  dentro do intervalo entra inteira, mesmo que os últimos bytes dela passem um pouco de `<endfim>`).
- **Só `<endinic>`** - disassembla exatamente 10 instruções a partir dali.
- **Nenhum endereço** - continua de onde o `L`/`LP` mais recente parou, também 10 instruções.

Cada linha mostra o endereço, os bytes crus em hexa (1 a 4 bytes, conforme o tamanho da instrução) e o
mnemônico com os operandos - saltos relativos (`JR`/`DJNZ`) já mostram o **endereço de destino
absoluto**, não o deslocamento cru.

Exemplo:

```
MON>L 4000,4010
4000  E5           PUSH HL
4001  CD 39 54     CALL 5439
4004  44           LD B,H
```

### LP

**Igual ao `L`**, mas ao invés de mandar a listagem pro log, gera um **PDF de verdade** na impressora
virtual (`## Impressora Virtual`, acima) - mesma ideia do `P`/`V`.

**Sintaxe:**

```
MON>LP [<endinic>[,<endfim>]]
```

Mesmas regras de `<endinic>`/`<endfim>` do `L` (inclusive continuar de onde o `L`/`LP` mais recente
parou, se nenhum endereço for passado). Cancelar a janela de salvar não gera arquivo nenhum - só mostra
`CANCELADO`.

### EDIT

**Abre uma janela separada** com um editor de linhas pro **programa-fonte Z80**, no estilo do editor de
BASIC do ZX-81/ZX Spectrum - a listagem é a própria área de cima do documento (sem log de comandos nem
mensagem "OK"), com um cursor `>` marcando a linha atual. Um campo `ASM>` reservado embaixo (junto de uma
linha de status logo acima dele) recebe tanto linhas novas do programa quanto os comandos de
gerenciamento abaixo.

**Sintaxe de cada linha** (formato do manual original do MegaAssembler):

```
NN Label: instrucao operando ;comentario
```

- **`NN`** - número da linha, **obrigatório**, **decimal** (0-65529, mesmo teto do número de linha do
  BASIC/MSX). Digitar de novo o mesmo número **substitui** a linha.
- **`Label:`** - opcional, termina em `:`.
- **`instrucao`** - um mnemônico Z80 válido ou uma das pseudo-instruções `ORG`/`DEFB`/`DEFW`/`DEFM`/
  `DEFS`/`EQU`/`END`. `EQU` exige `Label:`.
- **`;comentario`** - opcional, até o fim da linha.

**Números dentro do operando** seguem a mesma convenção já estabelecida no resto do Mamute:
**hexadecimal por padrão** (diferente do manual original, que usa decimal) - sufixos opcionais `H`
(hexa, redundante), `B` (binário), `D` (decimal, único jeito de escrever decimal agora).

**Navegação e edição, ao estilo ZX-81:**

- **Setas Cima/Baixo** movem o cursor `>` pela listagem.
- **ENTER com o campo VAZIO** puxa a linha do cursor `>` pro campo, pronta pra editar.
- **ENTER com o campo preenchido** grava a linha digitada (nova ou substituindo por `NN`).
- **ESC** descarta o que estiver no campo, sem gravar nada (não fecha a janela - use `QUIT` pra isso).
- **Tela cheia**: ao digitar linhas novas, o cursor rola **meia tela** automaticamente pra caber mais.
- **`LIST`** (digitado no campo, sem `NN` na frente): lista a partir da 1ª linha. Se o programa não
  couber inteiro, pergunta `Rolar mais uma tela? (S/N)` no rodapé (responda no mesmo campo + ENTER).

**Comandos de gerenciamento** (também digitados no campo, sem `NN` na frente):

- **`NEW`** - apaga o programa inteiro da memória, sem confirmação.
- **`DELETE <lininic>[-[<linfin>]]`** - apaga uma linha (`DELETE 50`), um intervalo inclusive
  (`DELETE 50-90`), ou da linha até o fim do programa (`DELETE 50-`, sem número final).
- **`RENUM [<novali>[,<antigali>[,<incr>]]]`** - renumera a partir da linha ANTIGA `antigali` pra uma
  nova sequência começando em `novali` com passo `incr` (`RENUM` sozinho: tudo, começando em 10, passo
  10).
- **`CHANGE '<string1>'[,'<string2>']`** - troca todas as ocorrências de `<string1>` por `<string2>` em
  qualquer lugar de cada linha; se `<string2>` for omitido, apaga as ocorrências de `<string1>`.
- **`SAVE`**/**`LOAD`** - gravam/lêem o programa-fonte inteiro num arquivo `.mza` em **ASCII simples**
  (pede o nome do arquivo no mesmo estilo do `LOAD`/`SAVE` do `MON>`) - formato próprio desta versão, não
  o formato binário proprietário do MegaAssembler original. `LOAD` SUBSTITUI o programa em memória.
- **`MERGE`** - igual ao `LOAD`, mas NÃO apaga o programa em memória - funde os dois. Uma linha do
  arquivo com o MESMO número de uma linha já existente SOBREPÕE a existente.
- **`SEARCH '<string>'`** (entre aspas) - busca LITERAL, case-sensitive. **`SEARCH <string>`** (sem
  aspas) - busca LIVRE, case-insensitive. Bem-sucedida, a tela passa a mostrar SÓ as linhas encontradas
  (mesmas setas/`ENTER` de sempre navegam entre elas) - digite `LIST` pra voltar ao programa completo.
- **`LSEARCH`** - igual ao `SEARCH`, mas em vez de filtrar a tela, imprime a listagem das linhas
  encontradas num PDF de verdade (impressora virtual, `## Impressora Virtual` - pede o nome do arquivo).
- **`FIND`** - apelido de `SEARCH` (mesmo resultado).
- **`QUIT`** - fecha a janela do `EDIT` e volta pro `MON>`, SEM apagar o programa da memória - abrir
  `EDIT` de novo continua exatamente de onde parou.

- **`A [<opções>][/<offset>]`** - monta o programa-fonte de verdade, com o mesmo assembler Z80 nativo do
  msxIDE (compatível M80/Nestor80). `A` sozinho só valida - mostra a listagem clássica (número da linha,
  endereço ou valor do `EQU`, até 4 bytes hexa por linha, conteúdo da linha) com a mesma paginação do
  `LIST` (`Rolar mais uma tela? (S/N)`) se não couber tudo de uma vez. Em caso de erro, mostra a
  mensagem descritiva e o cursor `>` pula direto pra linha com problema. As opções (qualquer combinação,
  coladas, ex. `A ONPIRSDH`):
  - **`O`** - além de validar, GRAVA o código-objeto montado na RAM simulada, no endereço do `ORG`,
    resolvido pelo mapeamento de `PAGE` ativo agora (mesma regra do `DM`/`M`: só grava de verdade se a
    célula mapeada for RAM).
  - **`N`** - a listagem NÃO mostra a coluna do número de linha (o resto é igual).
  - **`P`** - imprime a MESMA listagem num PDF de verdade (impressora virtual, pede o nome do arquivo).
  - **`I`** - grava o código-objeto recém-montado direto em DISCO (pede o nome do arquivo), no formato
    real do `BSAVE`/`BLOAD` do MSX (cabeçalho `FE` + endereço inicial/final/execução) - funciona sozinho,
    não depende de `O` ter gravado nada na RAM antes.
  - **`R`** - anexa ao final da listagem uma referência cruzada dos símbolos (ordem alfabética): nome,
    valor (constante `EQU` ou endereço de definição do rótulo) e todos os endereços onde foi usado.
  - **`S`** - anexa ao final uma lista alfabética simples de símbolos (nome + valor, sem os endereços de
    uso).
  - **`D`** - igual a `S`, mas em ORDEM DE APARIÇÃO no fonte, não alfabética.
  - **`H`** - manda só a(s) lista(s) de símbolos (`S`/`D`, pelo menos uma precisa estar ativa) pra um PDF
    SEPARADO do de `P`.
  - **`/<offset>`** - monta o programa para o endereço indicado pelo `ORG` MAIS `<offset>` (hexa) - útil
    pra testar o mesmo código-objeto em outro endereço sem editar o `ORG` do fonte.
- **`MAP`** - mostra o endereço inicial e final da ÚLTIMA montagem bem-sucedida (`A` ou `A O` - os dois
  calculam o mesmo intervalo). Sem nenhuma montagem ainda, pede pra rodar `A` primeiro.

**Diferenças desta versão em relação ao manual original**: o eco cosmético "PASSO-1"/"PASSO-2" do assembler de 2 passagens não existe aqui (só fazia
sentido numa janela gráfica animada). O motor Z80 cobre o vocabulário que o `EDIT` realmente aceita
(mnemônicos Z80 + `ORG`/`DEFB`/`DEFW`/`DEFM`/`DEFS`/`EQU`/`END`) - macros, assembly condicional
(`IF`/`IFDEF`/etc.) e segmentos relocáveis (`ASEG`/`CSEG`/`PUBLIC`/`EXTRN`) não fazem parte da gramática
do `EDIT` e por isso não são suportados.

### CLS

**Limpa a tela** - apaga todo o conteúdo do log do `MON>` (rolagem, banner de abertura, histórico de
comandos anteriores - tudo), deixando a janela em branco pronta pra continuar. Não afeta memória/PAGE/
registradores - só o texto visível no log é apagado. Sem argumentos.

## Comandos do SUPER-X

O **SUPER-X** é um segundo monitor/debugger clássico de MSX (distinto do **MegaAssembler**, acima) sendo
incorporado ao Mamute Assembler aos poucos, comando por comando, a partir do `XCL`.

**Convenção de nomes**: todo comando portado do SUPER-X ganha o prefixo **`X`** na frente do nome
original do manual (`CL` → `XCL`, `D` → `XD`, `M` → `XM`, etc.) - tanto pra evitar colisão com um comando
de mesma letra já existente no MegaAssembler (`D`/`M` já significam outra coisa no Mamute) quanto por
consistência entre TODOS os comandos SUPER-X portados, mesmo os que não colidiriam com nada.

**Endereçamento estendido por slot/sub-slot/VRAM**: praticamente todo comando do SUPER-X (os futuros
`XD`/`XM`/etc., no roteiro no final desta seção) aceita um sufixo opcional depois do endereço, no formato
`<endereço>[#<slot>[-<subslot>]]`:

- **Sem sufixo** - o endereço é resolvido pelo mapeamento `PAGE` ativo agora (igual todo comando herdado
  do MegaAssembler).
- **`#<slot>`** (`0`-`3`) - acessa aquele slot físico diretamente, sub-slot `0`, **ignorando** o `PAGE`
  ativo - ex.: `C000#2` acessa o endereço `C000` no Slot 2, sub-slot 0, não importa o que `PAGE` tem
  mapeado ali agora.
- **`#<slot>-<subslot>`** (`0`-`3` cada) - igual acima, mas escolhendo também o sub-slot - ex.:
  `C000#2-1` acessa `C000` no Slot 2, Sub-slot 1.
- **`#S`**/**`#5`** - explicitamente "use o mapeamento `PAGE` ativo agora" (igual a omitir o sufixo -
  existe só pra clareza, quando o resto da linha já usa `#` bastante).
- **`#V`**/**`#4`** - endereço de **VRAM**, plano, sem slot/sub-slot/página nenhuma (a VRAM de um MSX
  real nunca é mapeada no espaço de endereços do Z80). Único caso onde o endereço NÃO fica restrito a
  64KB: vai de `0` a `2FFFF` (192KB), validado contra o tamanho de VRAM configurado agora (`Configurar ->
  Mamute (Memória)`).

Escrita em slot/sub-slot explícito segue a mesma regra do resto do Mamute: só tem efeito em células
mapeadas como RAM - ROM/BIOS/BASIC/EXTBIOS/Vazio são somente-leitura, recusa silenciosa.

### XCL

**Calculadora** - primeiro comando portado do monitor **SUPER-X** (ver a introdução da seção `##
Comandos do SUPER-X`, acima). No manual original do SUPER-X esse comando se chama só `CL` - aqui vira
**`XCL`** porque **todo comando
portado do SUPER-X para o Mamute Assembler leva o prefixo `X`** (convenção adotada de propósito, pra não
colidir com nenhum comando do MegaAssembler e ficar consistente entre todos os comandos SUPER-X, mesmo os
que não colidiriam com nada). Converte um número (ou avalia uma expressão matemática inteira) e mostra o
resultado em quatro formatos de uma vez: **HEX**, **BIN** (16 bits), **DEC+** (decimal sem sinal,
0-65535) e **DEC+-** (decimal com sinal, -32768 a 32767) - tudo sempre em **16 bits**, com wraparound
(mesma convenção de endereço do resto do Mamute: um resultado "grande demais" só dá a volta, nunca dá
erro por estourar).

**Sintaxe:**

```
MON>XCL <expressão>
```

**Números** seguem a mesma convenção de sempre - **hexadecimal por padrão**, sem precisar de sufixo
nenhum - mas o `XCL`, diferente do resto do Mamute, também aceita sufixos opcionais no final de cada
número pra escolher outra base: **`D`/`d`** (decimal), **`B`/`b`** (binário), **`H`/`h`** (hexa,
redundante com o padrão) e **`O`/`o`** (octal). O sufixo só vale se os dígitos antes dele forem válidos
naquela base - `10D` vira decimal 10 (não hexa `10D`), porque `10` é decimal válido; pra hexa de verdade
nesse caso específico, use o sufixo `H` explícito (`10DH`).

**Além de um número isolado, aceita expressões matemáticas completas**, com a precedência clássica (do
mais apertado pro mais frouxo: unários primeiro, depois `*`/`/`/`%`, depois `+`/`-`, depois `&`, depois
`^`, depois `|`) e **parênteses** pra mudar a ordem:

- **`+`** soma, **`-`** subtração (binária) ou troca de sinal (unária).
- **`*`** multiplicação, **`/`** divisão inteira, **`%`** módulo (resto da divisão).
- **`|`** OR bit a bit, **`&`** AND bit a bit, **`^`** XOR bit a bit.
- **`!`** NOT bit a bit (unário - complemento de todos os 16 bits).
- **`( )`** agrupam sub-expressões, mudando a ordem normal de avaliação.

Divisão ou módulo por zero mostram `?DIVISAO POR ZERO`; qualquer outro erro (número inválido, parênteses
sobrando, caractere desconhecido) mostra `?ERRO DE SINTAXE` (ou `?NUMERO INVALIDO: <token>` quando dá pra
apontar exatamente qual pedaço falhou).

Exemplos:

```
MON>XCL 4000
HEX  : 4000H
BIN  : 0100000000000000
DEC+ : 16384
DEC+-: 16384

MON>XCL (100H+2ADH)*3-1
HEX  : 0B06H
BIN  : 0000101100000110
DEC+ : 2822
DEC+-: 2822
```

**Fora do escopo desta versão** (podem entrar em fases futuras): literais ASCII entre aspas (`'A'`,
`"AB"`) e as variáveis de debugger `@0`-`@3`/`@B`/`@E`/`@S` do SUPER-X original numa expressão (`XCL
@1+1`) - nenhuma delas ainda existe no Mamute Assembler do msxIDE.

### XD

**Despejo de memória** - porta do comando `D` do SUPER-X, com o **endereçamento estendido completo**
(`#slot[-subslot]`/`#V`/`#4`/`#S`/`#5`, ver a introdução desta seção) - a grande diferença em relação ao
`D` do MegaAssembler é justamente poder mirar um slot/sub-slot/VRAM explícito, ignorando o `PAGE` ativo.

**Sintaxe:**

```
MON>XD <inicial>[,<final>][,SAVE]
```

`<inicial>` (obrigatório) - onde começa o despejo, aceita o sufixo `#...`. `<final>` (opcional, hexa
simples, sem sufixo próprio - **só o `<inicial>` escolhe o alvo**, igual a sintaxe original do SUPER-X)
- sem ele, despeja 128 bytes (mesmo tamanho de "1 tela" já usado pelo `M`/`DM`). **`SAVE`** (a palavra
literal, no lugar ou depois de `<final>`) abre um diálogo pra gravar a mesma listagem num arquivo `.txt`
separado - mecanismo independente do prefixo `?`/impressora virtual (`## Impressora Virtual`), mais
simples, sem PDF nenhum.

Exemplos:

```
MON>XD C000#2-1,C00F
```

despeja de `C000` a `C00F` no Slot 2, Sub-slot 1, direto, sem tocar no `PAGE` ativo;

```
MON>XD 0#V,FF,SAVE
```

despeja os primeiros 256 bytes da VRAM e ainda pergunta um arquivo `.txt` pra salvar a mesma listagem.

O **formato** de cada linha do despejo é escolhido pelo comando `XF`, ver abaixo - o padrão é `D`
(despejo clássico hexa+ASCII).

### XF

**Formato de exibição do `XD`** - invenção do msxIDE: o manual original do SUPER-X tem **5 comandos
separados** (`D`/`A`/`H`/`I`/`M`, cada um sua própria janela), mas como os comandos aqui são mais simples
que no paleobasic, existe só o `XD` mais um seletor de formato:

**Sintaxe:**

```
MON>XF <formato>
```

`<formato>` é uma letra:

- **`D`** (padrão) - despejo clássico: 8 bytes em hexa + 8 caracteres ASCII por linha.
- **`C`** - porta do modo **Char** do SUPER-X original (lá é o comando `H`) - mostra 4 caracteres/sprites
  consecutivos (32 bytes) de cada vez como uma grade de pixels **16 linhas x 16 colunas** (2 caracteres
  de 8x8 lado a lado, os 2 primeiros em cima e os 2 seguintes embaixo) - `0` = bit aceso, `-` = apagado.
  Cada linha termina com `<endereco> : <byteEsquerdo>:<byteDireito> <linhaDentroDoCaractere 0-7>`.
- **`A`** - só os caracteres ASCII decodificados, sem nenhuma coluna hexa.
- **`I`** - só o **mnemônico** de cada instrução (disassembly "limpo", sem endereço nem bytes crus).
- **`M`** - endereço + bytes crus + mnemônico lado a lado, o formato completo (igual ao `L`/`LP`).

*Nota: o modo "Multi" do SUPER-X original (também `M`) não é um formato de exibição - é um console
interativo pra digitar/montar instruções e gravar direto na memória, incompatível com um comando de
despejo não-interativo como o `XD`. O `XF M` daqui é outra coisa: o formato completo endereço+bytes+
mnemônico, lado a lado.*

O formato escolhido dura só enquanto a janela do Mamute Assembler estiver aberta (mesmo espírito volátil
do `C`/modo de exibição do `D`/`P`/`V`) - fechar e reabrir volta pro `D`.

### XA

**Listagem ASCII** - porta do comando `A` do SUPER-X, como um comando próprio (não só um formato do
`XD`/`XF`) - mesmo padrão de sintaxe do `XD`, mas sempre mostra só os caracteres ASCII decodificados,
**independente do formato atual escolhido em `XF`** (equivalente a rodar `XD` com `XF A` ligado, só que
sem precisar trocar o formato de volta depois).

**Sintaxe:**

```
MON>XA <inicial>[,<final>][,SAVE]
```

Mesmas regras do `XD`: `<inicial>` aceita o sufixo `#slot[-subslot]`/`#V`/`#4`/`#S`/`#5` (só ele escolhe
o alvo); sem `<final>`, despeja 128 bytes; `SAVE` abre o diálogo de salvar a listagem num `.txt`
separado (mesmo mecanismo do `XD`, não passa pela impressora virtual/PDF).

Exemplo:

```
MON>XA C000#2-1,C03F
```

mostra só o texto ASCII do bloco `C000`-`C03F` no Slot 2, Sub-slot 1.

### XI

**Listagem disassemblada** - porta do comando `I` do SUPER-X, como um comando próprio (não só um formato
do `XD`/`XF`) - mesmo padrão de sintaxe do `XD`/`XA`, mostrando sempre a listagem completa **endereço +
bytes crus + mnemônico**, igual ao `L`/`LP` (o manual original do SUPER-X descreve o `I` com exatamente
esse formato). Diferente do `XF I` (que só mostra o mnemônico, sem endereço/bytes, como MODO do `XD`) -
o comando `XI` em si sempre mostra a versão completa, igual ao `XF M`.

**Sintaxe:**

```
MON>XI <inicial>[,<final>][,SAVE]
```

Mesmas regras do `XD`/`XA`: `<inicial>` aceita o sufixo `#slot[-subslot]`/`#V`/`#4`/`#S`/`#5`; sem
`<final>`, despeja 128 bytes; `SAVE` abre o diálogo de salvar a listagem num `.txt` separado.

Exemplo:

```
MON>XI C100#2-1,C110
```

disassembla o bloco `C100`-`C110` no Slot 2, Sub-slot 1.

**Comandos já portados:**

| Comando | Status |
|---|---|
| `XCL` | **Implementado** - calculadora HEX/BIN/DEC/octal, ver `### XCL` acima. |
| `XD` / `XF` | **Implementado** - despejo de memória com endereçamento estendido + seletor de formato (`D`/`C`/`A`/`I`/`M`), ver `### XD`/`### XF` acima. |
| `XA` | **Implementado** - listagem ASCII como comando próprio, ver `### XA` acima. |
| `XI` | **Implementado** - listagem disassemblada como comando próprio, ver `### XI` acima. |

**Roteiro dos próximos comandos** (nomes/sintaxe do manual original do SUPER-X - `X` na frente é a
convenção de nome deste port, ver acima; sintaxe/comportamento exatos podem ajustar durante a
implementação de cada um). O SUPER-X original tem `D`/`A`/`H`/`I`/`M` como **5 comandos separados**, cada
um sua própria janela editável em tela cheia - o msxIDE já cobre a parte de EXIBIÇÃO de todos os 5 (sem
edição/gravação ao vivo) através do `XD` + `XF` (formatos `D`/`A`/`C`/`H`→`I`/`M`, ver acima); as linhas
`XA`/`XI`/`XH`/`XM` abaixo continuam na lista só pelo que ainda falta de CADA UM (edição ao vivo célula a
célula, pilha de jump/call navegável, console de assembler interativo, etc.) - não são mais comandos
100% pendentes.

| Comando | Sintaxe (SUPER-X) | Função |
|---|---|---|
| `XD` | `<inic>[#slot][,<fim>[,<arq>]]` | **Exibição já portada** (`XD`+`XF`, acima) - falta só a edição ao vivo em grade |
| `XA` | `<inic>[#slot][,<fim>[,<arq>]]` | **Implementado como comando próprio** (`### XA`, acima) - falta só a edição ao vivo de texto |
| `XI` | `<inic>[#slot][,<fim>[,<arq>]]` | **Implementado como comando próprio** (`### XI`, acima) - falta a pilha de jump/call navegável (`←`/`→`) |
| `XH` | `<inic>[#slot][,<fim>[,<arq>]]` | **Exibição já portada** (`XF C`) - falta a edição de bit/caractere (Space/Invert/Clear/Fill) |
| `XM` | `<inic>[#slot]` | Entrada assembler interativa (monta e grava direto na memória) - console, não um formato de exibição, continua pendente |
| `XBL` | `<linha>` | LIST de BASIC a partir da memória crua |
| `XBT` | `<origem>[#slot],<fimorigem>,<destino>[#slot]` | Transferência de bloco |
| `XCD` | `<diretório>` | Muda diretório (MSX-DOS2) |
| `XRT` | `<origem>[#slot],<fimorigem>,<destino>[#slot]` | Realoca bloco de código de máquina e corrige ponteiros internos que apontem pra dentro do bloco movido |
| `XFL` | `<inic>[#slot],<fim>,<valor>` | Preenche bloco com um byte |
| `XCM` | `<inic>[#slot],<fim>,<inic2>[#slot][,S]` | Compara dois blocos (lista diferenças; `S` lista iguais) |
| `XFD` | `<inic>[#slot],<fim>` | Busca dados - pede o padrão depois, lista TODAS as ocorrências |
| `XCS` | - | Alterna o tipo de checksum (soma simples / soma + endereço) |
| `XTS` | `<inic>[#slot],<fim>` | Calcula checksum do bloco |
| `XGO` | `<endereço>[#slot]` | Executa programa (para em breakpoint) |
| `XRG` | `[<reg>,<valor>]` / `XRG *` / `XRG +` | Mostra/edita registradores; `*` limpa tudo exceto pilha; `+` reseta a pilha |
| `XTR` | `<endereço>` | Trace passo a passo, imprime registradores a cada instrução |
| `XCK` | - | Info da máquina (slot ativo, RAM do sistema, localização de ROMs, mapeador, discos) |
| `XSF` | `[<tecla>,<string>]` | Programa uma tecla de função |
| `XBF` | - | Busca string dentro de uma listagem BASIC (`?` = curinga de 1 caractere) |
| `XPP` | `[<página>,<segmento>]` | Seleciona segmento do mapeador de RAM numa página |
| `XSD` | `<arq>,<inic>[#slot],<fim>[,B\|D\|X]` | "Super disassembler" - disassembly pra arquivo texto, ou exporta bytes crus como `DEFB`/`DATA`/inline X-BASIC |
| `XFS` | `<drive>` | Lista arquivos do disco (equivalente a `DIR`) |
| `XCI` | `<drive>` | Uso do disco (clusters usados/total) |
| `XOF` | `[<offset>]` | Offset global - desloca o endereço `0` "lógico" pra todos os comandos, inclusive rotinas de disco |
| `XCU` | `[<número>]` | Troca modo de CPU (MSX turboR: Z80/R800 ROM/DRAM) |
| `XCO` | `[<fg>],[<bg>],[<borda>]` | Cor da tela |
| `XKR` | `<endereço>[#slot]` | Mostra memória como texto usando fonte japonesa |
| `XKT` | `<arquivo>` | Exibe arquivo de texto em japonês |
| `XTP` | `<arquivo>` | Exibe arquivo de texto (paginado, `ENTER`/`ESPAÇO`/`ESC`) |
| `XKL` | `[<drive>]` | (Re)carrega a fonte japonesa pra VRAM |
| `XSV` | `<arq>,<inic>[#slot],<fim>,[<execução>[,<offset>]]` | Salva com cabeçalho BSAVE |
| `XLD` | `<arq>[,<offset>[#slot]]` | Carrega com cabeçalho BLOAD |
| `XS#` | `<arq>,<inic>[#slot],<fim>` | Salva bytes crus, sem cabeçalho |
| `XL#` | `<arq>,<endereço>[#slot]` | Carrega bytes crus, sem cabeçalho |
| `XS%` | `[<drive>:]<setorinic>,[<setorfim>],<endereço>[#slot]` | Grava memória direto em setor(es) de disco |
| `XL%` | `[<drive>:]<setorinic>,[<setorfim>],<endereço>[#slot]` | Lê setor(es) de disco direto pra memória |
| `XIM` | `<endereço>,<slot>,<tipo>` | Adiciona uma nota persistente a um endereço |
| `XIC` | `<endereço>` | Consulta se existe nota pra um endereço |
| `XIL` | `<drive>` | Carrega o arquivo de notas |
| `XIS` | `<drive>` | Salva o arquivo de notas |
| `XPI` | `<porta>` | Lê byte de uma porta de I/O |
| `XPO` | `<porta>,<valor>` | Escreve byte numa porta de I/O |

`CLS`, `GO`/`RG` (cobertos pelo `PAGE`+`X`+`G` já existentes), `BT` (≈ `T`), `FL` (≈ `F`) e `TK` (≈ o
teclado numérico configurável do `S`) já têm equivalente direto no Mamute Assembler e não precisam de
porta separada. As 7 variáveis de debugger do SUPER-X (`@0`-`@3`/`@B`/`@E`/`@S`, endereço com slot/VRAM
já embutido) e os literais ASCII entre aspas do `XCL` (`'A'`/`"AB"`) também fazem parte do manual
original, mas ainda não têm data pra entrar - ver a nota "Fora do escopo desta versão" no `### XCL` acima.
