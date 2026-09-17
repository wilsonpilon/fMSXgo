# Referência: formato de fonte do Aquarela (.FNT)

> Notas de engenharia reversa sobre o **Aquarela**, outro editor de fontes/alfabetos para MSX
> (alternativa ao Graphos III, que é o formato `.ALF` já suportado pelo editor de alfabetos —
> `editor/CharsetEditorGui.pbi`). Sem acesso à documentação oficial do Aquarela até o momento;
> tudo aqui vem de engenharia reversa dos bytes crus de arquivos `.fnt` de exemplo, não de nenhuma
> especificação lida. Tratar como **hipótese bem testada, não como fato documentado** — releia esta
> nota inteira antes de codificar um importador em cima dela, e reforce a validação se aparecer mais
> amostras ou a documentação real do programa.
>
> **2026-07-22/23**: o disco de instalação real do Aquarela (`AQUARELA.COM`/`.OVL` + dezenas de
> fontes comerciais `.FNT`) foi encontrado e está em `Aquarela/Disco/` (e cópias por sessão de
> emulador em `Aquarela/MSX_*/`, e uma cópia organizada em `alfabetos/FNT/`). O usuário rodou o
> `.COM` de verdade num emulador e testou dezenas de arquivos individualmente, reportando quais
> carregam certo e quais dão erro — essa validação ao vivo (não engenharia reversa de bytes) é hoje
> a fonte mais confiável desta nota. **Status resumido (atualizado 2026-07-23)**: layout do glifo
> CONFIRMADO por comparação pixel a pixel contra uma screenshot real do Aquarela — 16×16, 2 planos de
> 16 bytes por linha, **começando 7 bytes depois do que se pensava** (ver "DESLOCAMENTO DE 7 BYTES",
> a correção mais importante desta nota — invalida a fórmula usada em quase todas as seções abaixo,
> mantidas por histórico). Implementado e testado em `editor/AquarelaCharsetEditorGui.pbi`. Do grupo
> de 2280 bytes, só 2 de 51 arquivos (`ITAL2.FNT`, `STAMP.FNT`) carregavam sem erro no Aquarela real —
> os outros 49 (mais 2 do grupo de 2312) foram identificados como corrompidos e **já apagados pelo
> usuário** (não pela IA) antes da correção do deslocamento ser descoberta.

## Amostras analisadas

> Seção histórica — caminhos abaixo são de antes da reorganização de `alfabetos/` em
> `alfabetos/ALF/` + `alfabetos/FNT/{2280,2304,2312,corrompidos}/...`. Atualização (2026-07-23):
> `CHORO.FNT` e `pacma2.fnt`/`PACMA2.FNT` **dão erro ao carregar no Aquarela de verdade** (âncora não
> é 'A' — ver seção acima) e foram movidos para `alfabetos/FNT/corrompidos/`; `pacma1.fnt`/
> `PACMA1.FNT` também. `data70.fnt`/`DATA70.FNT` mudou de tamanho pra 2312 bytes na cópia mais
> recente do disco e carrega bem — está em `alfabetos/FNT/2312/limpo/`.

| Arquivo | Tamanho | Slots reais | Slots em branco | Valor de preenchimento em branco |
|---|---|---|---|---|
| `alfabetos/CHORO.FNT` | 2280 bytes | 71 | 0 | — |
| `alfabetos/data70.fnt` | 2280 bytes | 39 | 32 (posições 0–31) | `0x40` |
| `alfabetos/pacma1.fnt` | 2280 bytes | 0 | 71 (arquivo inteiro) | `0x40` |
| `alfabetos/pacma2.fnt` | 2280 bytes | 71 | 0 | — |

Os 4 arquivos têm **exatamente o mesmo tamanho** (2280 bytes) independente do conteúdo — forte
indício de que esse é um tamanho fixo do formato de exportação do Aquarela, não algo calculado a
partir de quantos caracteres o autor realmente desenhou.

## Formato do registro (confirmado, sem exceção nos 4 arquivos)

- **Sem cabeçalho** — o primeiro byte do arquivo já é o primeiro byte do primeiro glifo.
- **32 bytes por caractere**, dividido em duas metades de 16 bytes:
  - **Bytes 0–15**: o glifo real. Interpretado como 16 linhas de 1 byte (8 pixels de largura ×
    16 linhas de altura), MSB à esquerda. Nas amostras analisadas o desenho de fato só ocupa uma
    faixa central de ~6–7 linhas dentro dessas 16 — o resto fica em branco, sugerindo uma célula
    alta (16px) usada de forma conservadora pela maioria dos glifos.
  - **Bytes 16–31**: **sempre zero** — confirmado em 142 registros com conteúdo real (71 de
    `CHORO.FNT` + 71 de `pacma2.fnt`) mais os registros em branco de `data70.fnt`/`pacma1.fnt`,
    sem uma única exceção. Provavelmente reservado (talvez para uma variante de 16px de largura
    que este conjunto de amostras nunca usa, ou para dado de cor — ver seção "SCREEN 1 vs SCREEN 2"
    nos tópicos futuros abaixo).
- **Arquivo = 71 registros completos (2272 bytes) + 8 bytes finais** — sempre os primeiros 8 bytes
  de um 72º registro que nunca chega a ficar completo (em `CHORO.FNT` esses 8 bytes finais tinham
  conteúdo real de glifo; nos outros 3 arquivos são só mais preenchimento em branco). Não está claro
  se isso é um formato de exatos "71 caracteres mais uma fração" ou se o tamanho de 2280 bytes é só
  um limite fixo de exportação que não bate exatamente com N×32.
- **Valor de "posição vazia"**: varia entre amostras — `0x00` em `CHORO.FNT`, `0x40` em
  `data70.fnt`/`pacma1.fnt`. Não sabemos se isso é versão do Aquarela, modo de exportação, ou
  alguma outra variável — mais uma pergunta em aberto.

## Prova cruzada entre arquivos (o achado mais forte)

Comparando os 71 glifos de cada arquivo byte a byte (não por semelhança visual):

- **`CHORO.FNT` ≡ `pacma2.fnt`, deslocamento 0**: os índices 23–31 são **idênticos, byte a byte**,
  nos dois arquivos.
- **`data70.fnt`, deslocamento +16** dos outros dois: os mesmos 9 glifos aparecem nos índices
  39–47 de `data70.fnt` (39 = 23+16, 47 = 31+16, sem exceção).

São **3 arquivos independentes concordando exatamente** sobre o mesmo alinhamento relativo entre
posições. A explicação mais simples: o Aquarela vem com uma fonte padrão, e um autor de fonte só
substitui os caracteres que quer desenhar — esses 9 (prováveis códigos de caractere que nenhum dos
três autores customizou) guardam o desenho de fábrica do programa, sempre na mesma posição real.

## FORMATO DO GLIFO: CONFIRMADO (2026-07-22, renderização visual)

> Isto substitui a hipótese "8×16, segunda metade sempre zero" das seções abaixo (mantidas por
> histórico). A hipótese antiga estava **errada** — vinha só das 4 amostras originais, que por
> coincidência eram todas fontes estreitas o bastante pra nunca acender um bit na metade direita.

Usando o subconjunto `alfabetos/FNT/2304/` — fontes que o usuário confirmou terem sido **lidas sem
erro e mostradas por inteiro** no Aquarela rodando de verdade num emulador (`ARNOLDG`, `BRODWAY`,
`ERAS`, `EXOTIQG`, `LCD`, `LETRASET`, `YANKIEG.FNT`) — renderizamos os bytes crus como imagem sob
3 hipóteses de layout e comparamos visualmente:

1. **Linhas intercaladas** (byte par = metade esquerda da linha N, byte ímpar = metade direita da
   linha N): produz ruído, sem letras reconhecíveis.
2. **Dois glifos 8×16 por registro** (bytes 0–15 = um caractere, bytes 16–31 = outro): idem, ruído.
3. **Dois planos de 16 bytes** (bytes 0–15 = coluna esquerda de 8px de cada uma das 16 linhas,
   bytes 16–31 = coluna direita de 8px das mesmas 16 linhas, formando um glifo real de
   **16 colunas × 16 linhas**): **produz letras perfeitamente legíveis**, testado em `LETRASET.FNT`
   e `ERAS.FNT` (dois estilos visuais bem diferentes, um script cursivo e um geométrico sans-serif) —
   ambos leem, na ordem exata reportada pelo usuário na seção seguinte:
   `A B C D E F G H I J K L M N O P Q R S T U V W X Y Z & ? ! " 0 1 ...`

**Fórmula (revisada — ver "DESLOCAMENTO DE 7 BYTES" logo abaixo, esta versão estava incompleta)**:
registro de 32 bytes, `rec[0..31]`, para a linha `r` de 0 a 15:

```
byte_esquerdo = rec[r]        ; bits 7..0 = colunas 0..7 do glifo (MSB = pixel mais à esquerda)
byte_direito  = rec[16 + r]   ; bits 7..0 = colunas 8..15 do glifo
```

Ou seja: **não são "duas metades independentes"** como a hipótese antiga descrevia — são dois
**planos de bitmap** (esquerdo/direito), cada um cobrindo as 16 linhas inteiras, não uma divisão
alto/baixo do registro. É o mesmo princípio de fonte 16px-larga usado por vários programas MSX, só
que armazenado plano-a-plano em vez de intercalado linha-a-linha. **Isto ficou parcialmente certo**
(o layout de 2 planos por linha está correto) **mas incompleto** — faltava um deslocamento de 7
bytes na posição de início de cada registro, só descoberto depois (seção seguinte).

## DESLOCAMENTO DE 7 BYTES: bug real, confirmado pixel a pixel contra o Aquarela de verdade (2026-07-23)

> Isto substitui de vez a fórmula acima. É a causa raiz do "floreio decorativo desconexo no topo de
> cada letra" que aparecia em toda renderização anterior desta nota — nunca foi decoração, era o
> final do caractere ANTERIOR vazando pro topo do caractere seguinte.

O usuário reportou que a letra G (e outras) apareciam com os quadrantes errados no editor
(`AquarelaCharsetEditorGui.pbi`) comparado à tela real do Aquarela rodando num emulador. Duas
hipóteses de troca (bloco de 8 linhas, espelhamento vertical completo) foram testadas contra o
alfabeto inteiro de `LETRASET.FNT`/`ERAS.FNT` e **pioraram tudo** — o alfabeto inteiro virava ruído,
não só a letra citada. Isso descartava troca/espelhamento como explicação.

O usuário então enviou uma screenshot real do Aquarela rodando no openMSX mostrando a letra 'A' de
`LETRASET.FNT` na grade de edição 16×16. Extraindo o bitmap exato da screenshot pixel a pixel
(célula a célula, sem depender de leitura visual) e comparando contra a decodificação da fórmula
"confirmada" anterior:

- **As 9 primeiras linhas da tela real (linhas 0–8) batem, byte a byte, com as linhas 7–15 da minha
  decodificação antiga** (o "corpo" da letra que eu já lia certo).
- **As 7 linhas finais da tela real (linhas 9–15, uma barra larga + duas pernas — o traço horizontal
  característico de um "A") não existiam em lugar nenhum da minha decodificação** — nem no mesmo
  registro, nem no próximo.

Testando deliberadamente um deslocamento de posição inicial — em vez do registro do caractere N
começar no byte `N×32` do arquivo, ele começa no byte `7 + N×32` — **as 16 linhas bateram
perfeitamente, uma por uma, contra a screenshot real**. Renderizando o alfabeto inteiro de
`LETRASET.FNT` com esse deslocamento: cada letra virou uma forma cursiva completa e conectada (sem
fragmento nenhum) — confirmado depois também dentro do próprio `.exe` compilado (não só em Python),
lendo `LETRASET.FNT` de verdade e comparando o dump ASCII resultante, que bateu exatamente com a
screenshot real.

**Fórmula CONFIRMADA** (registro de 32 bytes começando no byte `7 + N×32` do arquivo, não `N×32`):

```
base = 7 + N * 32             ; N = índice do caractere (0-based)
byte_esquerdo = file[base + r]        ; r = linha 0..15
byte_direito  = file[base + 16 + r]
```

**O que são os 7 bytes antes do primeiro registro (byte 0–6 do arquivo)?** Não são cabeçalho nem
lixo — são a ponta final (*wrap-around*) do ÚLTIMO registro do arquivo. Com registros de 32 bytes
começando no byte 7, o registro 71 (o último, numa tabela de 72) ocupa os bytes `2279..2310` — mas o
arquivo só tem 2304 bytes (índices 0–2303), então os últimos 7 bytes desse registro (`2304..2310`)
dão a volta pro início do arquivo (`0..6`). É uma estrutura circular: os índices lógicos dos
registros são contínuos, só que a posição física no arquivo tem essa rotação fixa de 7 bytes.
`AquarelaCharsetEditorGui.pbi` já implementa isso (`#AqEd_RecordOffset = 7`) tanto pra ler quanto
pra escrever (ver `AqEd_LoadFnt`/`AqEd_SaveFnt`) — como o editor só expõe 32 dos 72 registros (bem
antes de onde a rotação entraria em jogo), a escrita não precisa lidar com o wrap-around de verdade,
só preencher o resto do arquivo com o byte de posição-vazia `$40`.

**Impacto em achados anteriores desta nota**: qualquer decodificação/renderização registrada ANTES
de 2026-07-23 (incluindo a maioria das imagens/comparações citadas nas seções abaixo, e a análise de
"âncora de posição" que concluiu que `CHORO.FNT` começava em 'C') usou a fórmula sem o deslocamento
de 7 bytes — **está tecnicamente incorreta**, mesmo que o resultado visual parecesse "razoável" (as
9 linhas que batiam eram convincentes o bastante pra enganar leitura visual e até um teste
automatizado de legibilidade do alfabeto inteiro). `CHORO.FNT` e os outros arquivos do grupo de 2280
bytes já foram apagados pelo usuário antes dessa correção ser encontrada, então a alegação "CHORO
começa em C" **não pôde ser re-testada** com a fórmula corrigida — tratar como não confirmada, não
como refutada.

## Âncora de posição: CONFIRMADO — precisa ser 'A', senão o arquivo está incompleto/corrompido

> **Nota (2026-07-23)**: as conclusões desta seção foram tiradas ANTES da correção do deslocamento de
> 7 bytes acima. A rejeição real do Aquarela ao carregar os arquivos do grupo de 2280 bytes é
> evidência empírica independente (o usuário testou no programa de verdade) e continua válida. Mas a
> alegação específica "`CHORO.FNT` decodifica começando em 'C'" usava a fórmula antiga (sem o
> deslocamento) e não foi re-verificada — os arquivos já foram apagados. Tratar a explicação
> "arquivo incompleto = começa em outra letra" como plausível mas não re-confirmada.

> Revisão (2026-07-23) da hipótese anterior ("a âncora varia legitimamente por arquivo, é só o
> primeiro glifo que o autor desenhou"). Essa hipótese estava **errada**: o usuário testou os 51
> arquivos do grupo de 2280 bytes direto no Aquarela e só 2 carregam sem erro —
> `ITAL2.FNT` e `STAMP.FNT` (pasta `alfabetos/FNT/2280/limpo/`, os únicos que sobraram lá). Os
> outros 49 (os 39 de `2280/anomalo/` + 10 de `2280/limpo/`, incluindo `CHORO.FNT`) dão **erro ao
> carregar, nada aparece** — apesar de vários deles (como `CHORO.FNT`) decodificarem "bonito" com a
> fórmula confirmada, tipo uma sequência C–D–E–F–...–Z perfeitamente legível.

Decodificando `ITAL2.FNT` e `STAMP.FNT` (os 2 que funcionam) com a mesma fórmula: **ambos começam
exatamente em 'A'** na posição 0, igual a `LETRASET.FNT`/`ERAS.FNT`. Já `CHORO.FNT` (que dá erro no
Aquarela) começa em 'C'. Isso deixa claro: **posição 0 = 'A' é obrigatório** — não é uma variação
válida de exportação, é a marca de que o arquivo tem o começo intacto. Arquivos onde a sequência
começa em outra letra (B, C, ...) estão **faltando dados do início** (por corrupção real — cópia
ruim, setor de disquete degradado, extração incompleta — não por escolha do autor da fonte), e o
Aquarela corretamente rejeita esses arquivos incompletos com um erro de carregamento.

Isso também **derruba** a "prova cruzada" antiga desta nota (seção abaixo, mantida por histórico):
CHORO/pacma2/data70 concordando em deslocamentos relativos não é evidência de um recurso de
exportação — é evidência de que esses arquivos sofreram o **mesmo tipo de corrupção** (perda de N
registros do início), provavelmente de uma fonte ou processo de cópia em comum.

**Implicação prática pro importador**: validar `posição 0 == 'A'` (comparando contra os bytes
conhecidos de `ITAL2.FNT`/`STAMP.FNT`/`LETRASET.FNT` etc, ou por reconhecimento de padrão) antes de
aceitar um `.FNT` — se não bater, tratar como corrompido/incompleto e recusar a importação (ou avisar
o usuário) em vez de tentar decodificar mesmo assim.

**Ressalva**: essa regra explica a maioria dos casos, mas **não é a única causa de corrupção** —
`KLORE.FNT`/`AMERIC2M.FNT` (grupo de 2312 bytes, ver seção própria abaixo) começam corretamente em
'A' e mesmo assim dão problema (não erro de carregamento direto, mas glifos quebrados a partir de um
certo ponto). Ou seja: âncora em 'A' é **necessária mas não suficiente** pra um arquivo ser válido.

## `alfabetos/FNT/2312/limpo/` confirmado pelo usuário: fontes 8×8 completas, sem corrupção

O usuário testou os arquivos dessa pasta (56 arquivos) no Aquarela de verdade e confirmou: carregam
normalmente, sem erro, e são **alfabetos 8×8** — completos, sem partes corrompidas. Bate exatamente
com a decodificação: renderizando `LOGO.FNT` com a fórmula confirmada acima, **todos** os glifos
(48+ testados) ficam inteiramente confinados às colunas 0–7 (metade esquerda do registro de 16px) —
a metade direita (colunas 8–15) nunca acende um bit em nenhum slot. A sequência lê perfeita:
`A B C D E F G H I J K L M N O P Q R S T U V W X Y Z & ? ! " 0 1 2 3 4 5 6 7 8 9 . : - ( ) , a b...`
— confirma de novo a ordem exata reportada pelo usuário, e mostra que pelo menos este arquivo
continua além dos 46 glifos "oficiais" (entrando em minúsculas).

Conclusão prática: **8×8 não é sinal de problema** — é só um estilo de fonte que nunca usa a metade
direita da célula de 16px. `KLORE.FNT`/`AMERIC2M.FNT` (seção anterior) também são "8×8" nesse mesmo
sentido (glifos confinados à esquerda), então "ser 8×8" sozinho não distingue corrompido de saudável
— o que distingue é a customização **parar no meio de um glifo com uma irregularidade de pixel**,
seguida imediatamente de preenchimento `0x40` **antes do fim esperado da sequência A–Z+símbolos**.
Nas fontes 2312/limpo confirmadas aqui, a sequência vai limpa até bem depois dos 46 glifos oficiais,
sem essa quebra abrupta.

## Correção: pastas "limpo"/"anomalo" em `alfabetos/FNT/` não significam corrompido/OK

A separação feita antes (ver conversa anterior) rotulava "anomalo" como "registro com bytes 16–31
diferentes de zero" — na época, uma hipótese de que isso seria sinal de corrupção. Com o layout real
confirmado acima, **bytes 16–31 não-zero é o comportamento NORMAL de qualquer glifo que usa a metade
direita dos 16px de largura** — ou seja, a maioria das fontes reais cai em "anomalo" só por ter
letras suficientemente largas, não por estarem corrompidas.

## `KLORE.FNT` / `AMERIC2M.FNT`: CONFIRMADO corrompido (2026-07-22, relato do usuário)

O usuário abriu esses dois arquivos no Aquarela de verdade e reportou: o alfabeto é essencialmente
**8×8** (não 16×16), vai de A–Z com `&`, `?`, `!`, `"`, `0` normalmente, o `1` aparece cortado, e daí
pra frente só aparecem "riscos duplos" no lugar do caractere — o mesmo problema, no mesmo ponto, nos
dois arquivos.

Decodificando com a fórmula confirmada acima (posições 0–29 = A–Z+`&?!"`, 30='0', 31='1'), os bytes
batem exatamente com essa descrição:

- Slots 0–30: glifos completos e bem formados, mas **confinados à metade esquerda** (colunas 0–7) —
  bate com "essencialmente 8×8".
- Slot 31 ('1'): também um dígito completo/reconhecível na decodificação, mas com um pixel isolado
  fora do traço principal (`.#.##...`) — pequena irregularidade que pode ser o que aparece como
  "cortado" na tela real.
- Slot 32 em diante: bytes `40` repetidos (o mesmo valor de "posição vazia" usado por dezenas de
  outros arquivos do corpus) — decodificados, viram duas listras verticais finas por célula, o que
  bate com "riscos duplos".

Ou seja: **nada nos bytes crus contradiz o relato do usuário** — a decodificação que eu fiz bate
exatamente com o que ele descreveu vendo a tela real do Aquarela. Isso não prova qual é a causa raiz
da corrupção (arquivo truncado? setor ruim no disco original? versão incompatível de exportação?),
só confirma que o comportamento visto no programa real e os bytes do arquivo são consistentes entre
si — o problema é genuíno, não um artefato do meu decodificador.

**Ação tomada**: os dois arquivos foram movidos para `alfabetos/FNT/corrompidos/` (fora da
classificação por tamanho/`limpo`/`anomalo`, que não captura esse tipo de problema). Se aparecerem
mais arquivos com esse mesmo sintoma (customização "trava" no meio de um caractere legível, seguida
de puro `0x40` antes do fim nominal do padrão A–Z+símbolos+dígitos), mover pra lá também.

## Observação visual do usuário (2026-07-22, direto da tela do Aquarela rodando)

Sem manual, mas rodando o `AQUARELA.COM` de verdade num emulador, o usuário reportou que:

- Os caracteres são **16×16** (não 8×16 como a hipótese anterior desta nota assumia a partir só dos
  4 arquivos originais — ver conflito abaixo).
- A ordem dos glifos editáveis, testada em vários alfabetos diferentes e consistente entre eles, é:
  **A–Z, depois `&`, `?`, `!`, `"`, depois `0`–`9`, depois `.`, `:`, `-`, `(`, `)`, `,`** — nessa
  ordem exata. Isso dá **46 glifos** (26 letras + 4 símbolos + 10 dígitos + 6 símbolos).

**Conflito a resolver**: a seção "Formato do registro" acima (baseada em 4 amostras) concluiu que o
glifo real usa só os bytes 0–15 do registro de 32 bytes (16 linhas × 1 byte = 8px de largura), com os
bytes 16–31 sempre zero nas amostras vistas até então. Isso é **compatível** com 16×16 se o glifo for
na verdade **16px de largura × 16 linhas de altura**, guardado em **dois planos de 16 bytes** (bytes
0–15 = coluna esquerda de cada uma das 16 linhas, bytes 16–31 = coluna direita) em vez de intercalado
por linha — nesse caso "segunda metade sempre zero" simplesmente significa que nenhuma das 4 amostras
originais tinha glifo usando a metade direita (plausível, várias fontes decorativas ficam mais
estreitas que a célula). Ainda não testado contra a nova leva de 55 arquivos reais do disco — próximo
passo antes de codificar qualquer parser/render do Aquarela.

## Análise em escala com o disco real (`Aquarela/Disco/*.FNT`, 55 arquivos)

Com o corpus bem maior agora disponível, uma verificação rápida de quantos dos 71 registros (32 bytes
cada) cada arquivo tem "customizados" (glifo real, nem `0x00` nem `0x40` repetido) deu um resultado
bem regular: os valores observados são exclusivamente **0, 7, 16, 23, 32, 39, 48, 55, 64, 71** —
nunca um valor fora dessa lista, em nenhum dos 55 arquivos. As diferenças entre valores consecutivos
alternam **7, 9, 7, 9, ...**, o que bate exatamente com "sempre um número inteiro de linhas de 16
colunas (múltiplos de 16: 0/16/32/48/64) mais, opcionalmente, mais 7 posições de uma linha parcial
seguinte" — ou seja, os autores de fonte parecem desenhar sempre em ordem estritamente sequencial
pela posição no arquivo (nunca pulam posições), e muitos param bem no meio de uma "linha" de 16.
Isso é consistente com um editor tipo grade 16-colunas × N-linhas (como a tabela do Graphos III em
`CharsetEditorGui.pbi`), mas **não prova** onde a grade de 16 colunas se alinha com os grupos de
caracteres reportados pelo usuário (26+4+10+6) — ainda não dá pra cravar isso sem mais evidência
(ex.: comparar o glifo numa posição específica contra o que a tela do Aquarela mostra pra aquele
código, ou achar um arquivo com exatamente 46 customizados pra testar a hipótese "os 46 glifos
reportados = as primeiras 46 posições do arquivo").

## O que NÃO está confirmado

- **CONFIRMADO** ~~Âncora absoluta~~ ~~Identidade letra a letra de cada posição~~ — ver seções acima
  ("FORMATO DO GLIFO: CONFIRMADO" e "Âncora de posição"). O layout do glifo (32 bytes = 2 planos de
  16, formando 16×16 real) está confirmado por renderização visual em duas fontes independentes. A
  âncora **varia por arquivo** (posição 0 = primeiro caractere que o autor realmente desenhou, não
  um código fixo) — mecanismo entendido, mas ainda sem confirmação formal de que o corte é sempre
  "início da tabela A/B/C/..." e nunca no meio de outro grupo (símbolos/dígitos).
- **Tamanho do arquivo não é fixo em 2280 bytes** como esta nota concluía antes — o disco real tem
  arquivos de 2280, 2304 e 2312 bytes (ver `alfabetos/FNT/{2280,2304,2312}/`). 2304 = 72 registros
  exatos (72×32, sem sobra). 2280 = 71 registros + 8 bytes finais. 2312 = 72 registros + 8 bytes
  finais. Ainda não sabemos a que corresponde essa diferença de tamanho (versão do Aquarela? número
  de caracteres customizados arredondado pra um destes 3 tamanhos de exportação? outra coisa?).
- Por que `CHORO.FNT` usa `0x00` como preenchimento de posição vazia enquanto `data70.fnt`/
  `pacma1.fnt` usam `0x40`.
- Os 8 bytes finais dos grupos de 2280/2312 bytes (registro incompleto seguinte) — sobra de
  exportação ou trecho significativo? No grupo de 2312 bytes esses 8 bytes terminam quase sempre em
  `...c8`, idêntico entre dezenas de arquivos independentes — não parece ruído aleatório, mas ainda
  não sabemos o que significa.

## Comparação com Graphos III (`.ALF`, já suportado)

| | Graphos III (`.ALF`) | Aquarela (`.FNT`) |
|---|---|---|
| Cabeçalho | 7 bytes (tipo `0xFE` + endereços inicial/final/execução) | nenhum encontrado |
| Células | 256 fixas, sempre presentes | só as usadas (até 71/72), resto nem existe no arquivo |
| Glifo | 8×8, 8 bytes | **16×16, 32 bytes** (2 planos de 16 bytes, colunas 0–7 e 8–15) |
| Por registro | 8 bytes | 32 bytes (confirmado — ver seção "FORMATO DO GLIFO" acima) |
| Tamanho total | 2055 bytes (7 + 256×8) fixo pelo formato | 2280, 2304 ou 2312 bytes conforme o arquivo (não fixo) |
| Âncora de posição | posição = código do caractere (0–255), fixo | **varia por arquivo** — posição 0 = 1º glifo customizado pelo autor |

## Próximos passos / tópicos futuros

1. **~~Menu placeholder~~ Editor de verdade implementado (2026-07-23), ampliado pra 46 caracteres
   (2026-07-23)**: `editor/AquarelaCharsetEditorGui.pbi` (`AquarelaCharsetEditor_OpenWindow`, ligado a
   `Criar -> Alfabeto Aquarela...` em `BadigEditor.pb`). Grade de edição sempre 16×16 (mesmo pros
   glifos "8×8" do Aquarela, que na prática só usam a metade esquerda) e tabela de 46 caracteres
   (grade de 8 colunas × 6 linhas, as 2 últimas células sem uso = A-Z + `& ? ! "` + `0-9` +
   `. : - ( ) ,`, o trecho confirmado por teste real - ver "Observação visual do usuário" acima e
   "Próximos passos" item 5). Sem integração com `ProjectDB` (que só modela o formato 256×8 do
   Graphos III) - ferramenta autocontida baseada em arquivo (Abrir/Salvar/Salvar como), salvando
   sempre no formato de 2304 bytes (72 registros, os 26 além dos 46 editáveis preenchidos com
   `0x40`). **Nota de implementação**: `Line()` não renderizava as
   linhas de grade nesta janela em teste real (mesmo com `StartDrawing()` retornando sucesso) -
   trocado por `Box()` de 1px, que funciona; se outro editor da base de código um dia mostrar o
   mesmo sintoma (grade/linha que não aparece apesar do desenho "ter dado certo"), suspeitar do
   mesmo problema.
2. **~~Deslocamento de 7 bytes~~ CORRIGIDO (2026-07-23)**: `#AqEd_RecordOffset = 7` em
   `AquarelaCharsetEditorGui.pbi`, aplicado em `AqEd_LoadFnt`/`AqEd_SaveFnt` — ver seção
   "DESLOCAMENTO DE 7 BYTES" acima pra prova completa (comparação pixel a pixel contra screenshot
   real do Aquarela, confirmada dentro do `.exe` compilado). Antes dessa correção, TODO glifo
   decodificado (nesta nota e no editor) tinha um "floreio" desconexo no topo — na real, era o final
   do caractere anterior vazando pro topo, e faltavam as últimas ~7 linhas do caractere de verdade.
3. **~~Validação de layout~~ CONCLUÍDA (2026-07-22, revisada 2026-07-23)**: 32 bytes = 2 planos de 16,
   glifo 16×16 real, começando no byte `7 + N×32` do arquivo (item 2 acima) — confirmado por
   renderização visual e, por fim, por comparação pixel a pixel contra o Aquarela rodando de verdade.
4. **~~Estratégia de âncora~~ CONCLUÍDA (2026-07-23), com ressalva**: posição 0 precisa ser 'A' — não é
   uma âncora variável legítima, é a marca de arquivo íntegro. Ver seção "Âncora de posição" acima.
   **Ressalva importante**: essa conclusão foi tirada com a fórmula ANTES da correção do item 2 —
   `CHORO.FNT` (o exemplo citado) já foi apagado e não pôde ser re-testado com a fórmula corrigida,
   então trate "arquivos incompletos começam em outra letra" como plausível, não re-confirmado.
   Importador deve **validar posição 0 == 'A' e recusar** arquivos que não batam. Ressalva adicional:
   âncora correta não garante o arquivo inteiro são — ver `KLORE.FNT`/`AMERIC2M.FNT` (também já
   apagados), que começavam em 'A' mas ainda assim tinham outra corrupção mais adiante.
5. **Critério de validação pro importador, atualizado com os testes reais do usuário**:
   - Posição 0 deve decodificar como 'A' (comparar contra um arquivo-âncora tipo `ITAL2.FNT` ou por
     reconhecimento de padrão) — senão, recusar (arquivo incompleto).
   - Mesmo com posição 0 correta, ainda pode haver corrupção adiante (caso `KLORE`/`AMERIC2M`) — não
     se sabe ainda um critério byte-a-byte pra detectar isso automaticamente; por enquanto só
     testagem manual contra o Aquarela real revela.
   - Tamanho do arquivo (2280 vs 2304 vs 2312) **não prediz** validade sozinho — o grupo de 2280
     bytes teve 49/51 corrompidos mas 2 válidos; os grupos de 2304 e 2312 (`limpo/`) parecem bem mais
     confiáveis nas amostras testadas até agora, mas não foram testados peça por peça feito o 2280.
6. **Suporte a importação `.FNT` do Aquarela no editor de alfabetos** (`CharsetEditorGui.pbi` ou um
   editor dedicado novo, dado que o conjunto de caracteres é bem menor — até 72, não 256, e a célula
   é 16×16 em vez de 8×8) ao lado do já existente "Carregar do Graphos III...". Layout e âncora já
   confirmados (itens 2–3); usar o critério de validação do item 4 antes de aceitar um arquivo.
7. **Suporte a SCREEN 2 além de SCREEN 1** no editor de alfabetos (ligado, mas não exclusivo, ao
   trabalho acima) — hoje o editor (e o `.ALF` do Graphos III) modela exatamente a Pattern
   Generator Table de **SCREEN 1**: uma única tabela de 256 padrões × 8 bytes (2048 bytes), com cor
   definida grosseiramente por grupo de 8 códigos de caractere (Color Table de 32 bytes, fora do
   escopo atual do editor — ele só lida com o desenho monocromático). **SCREEN 2** (resolução mais
   alta) usa uma Pattern Generator Table **3× maior**: três "terços" de 256 padrões × 8 bytes cada
   (6144 bytes no total, cobrindo posições de caractere 0–255/256–511/512–767, um terço por terço
   da tela) — e uma Color Table do **mesmo tamanho** (6144 bytes), porque em SCREEN 2 cada uma das
   8 linhas de pixel de um glifo pode ter seu próprio par de cores FG/BG, em vez de um par só para
   o caractere inteiro como em SCREEN 1. Suportar SCREEN 2 de verdade significa: (a) o editor lidar
   com os 3 bancos/terços de padrão em vez de só 1, e (b) adicionar suporte a cor de verdade (hoje
   inexistente no editor — só desenho monocromático) — mudança de modelo de dados bem maior que só
   trocar o formato de arquivo importado, vale tratar como item separado ao planejar.
8. ~~Investigar se os 16 bytes sempre-zero guardam relação com cor do SCREEN 2~~ — **descartado**: a
   segunda metade do registro não é "sempre zero" nem reservada, é o plano de bitmap da coluna
   direita do glifo (ver "FORMATO DO GLIFO: CONFIRMADO" acima). Sem indício de dado de cor em
   nenhuma amostra até agora.
