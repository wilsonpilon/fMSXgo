# MSX Basic DignifieR — Guia do Usuário

> Adaptação, para o nosso projeto em PureBasic, da documentação original do **MSX Basic DignifieR** (`msxbader`), parte da suíte [Basic Dignified](https://github.com/farique1/basic-dignified) de farique1. Este módulo também já era exclusivo do MSX no projeto original. A mudança aqui foi trocar a invocação por linha de comando (`python msxbader.py`) por uma ação da nossa IDE, e reorganizar as opções como um **painel de configurações**, em vez de argumentos de terminal.

---

## O que é

O **DignifieR** faz o caminho **inverso** do módulo Basic Dignified: pega um programa **MSX BASIC clássico** (com números de linha, `GOTO`/`GOSUB` numéricos, tudo colado sem espaço) e converte para o formato **Dignified** (sem números de linha, rótulos nomeados, espaçamento legível).

Serve para quando você tem um programa clássico pronto — digitado de uma revista, salvo de um emulador, feito por outra pessoa — e quer **trazê-lo para dentro do fluxo Dignified** da IDE: editar com mais conforto, entender melhor a lógica, ou continuar desenvolvendo em cima dele usando os recursos modernos (rótulos, funções, variáveis longas etc.).

Ele automatiza a parte chata e repetitiva de remover números de linha na mão, criar rótulos para os desvios, e ajustar o espaçamento entre palavras-chave.

> A combinação de todas as opções configuráveis com a variedade de dialetos do BASIC clássico é razoavelmente complexa e não foi testada tão exaustivamente quanto deveria — vale conferir o resultado antes de confiar cegamente nele, principalmente em código mais antigo ou incomum.

## Como usar na IDE

Abra o arquivo BASIC clássico (`.amx`/`.bmx`/`.asc`/`.bas`) e use a ação **"Converter para Dignified"** no menu da IDE (ou o atalho correspondente). O resultado é aberto como um novo arquivo `.dmx`, pronto para edição — nada é sobrescrito no arquivo original.

Se nenhum nome de destino for informado, o arquivo gerado reaproveita o nome de origem com a extensão `.dmx`.

## Opções de conversão (painel de configurações)

Essas opções controlam **como** o BASIC clássico é reescrito em Dignified. Ficam disponíveis num painel de configurações (por projeto, com a opção de ajustar por conversão individual), substituindo os argumentos de linha de comando do projeto original.

| Opção | O que faz | Padrão |
|---|---|---|
| Converter para minúsculas | Converte todo o texto para minúsculas, **exceto** literais (conteúdo entre aspas, `DATA`, `REM`) | Ativado |
| Manter espaços originais | Por padrão, todos os espaços são normalizados para **1**. Esta opção mantém espaços extras originais além disso | Desativado |
| Converter `LOCATE:PRINT` | Converte `locate x,y:print` para o define `[?](x,y)` usado pelo módulo Basic Dignified | Ativado |
| Nível de detalhe (verbose) | `0` = silencioso, `1` = +erros, `2` = +avisos, `3` = +etapas, `4` = +detalhes | `3` |

### Formatação de rótulos

Controla como os **rótulos** (destinos de `GOTO`/`GOSUB`) são gerados a partir dos números de linha originais. Pode combinar mais de uma opção:

| Código | Efeito |
|---|---|
| `i` | Indenta as linhas que não são rótulo, depois do primeiro rótulo aparecer |
| `s` | Adiciona uma linha em branco antes de cada rótulo |

Padrão: `i` + `s` (ambos ativos).

### Formatação de REMs

Controla como os comentários `REM` do código clássico são tratados na conversão. Pode combinar mais de uma opção:

| Código | Efeito |
|---|---|
| `l` | Remove REMs que estão **sozinhos** numa linha |
| `i` | Remove REMs no **fim** de uma linha |
| `b` | Mantém linhas de REM **em branco** como linhas em branco |
| `m` | **Move** REMs que estavam no meio da linha para **acima** da linha original |
| `k` | Adiciona um rótulo se um REM apontado por uma instrução de desvio foi removido |

Padrão: `m`.

### Desmembrar `THEN`/`ELSE`

Controla se e onde a linha é quebrada (usando `_`) ao redor de `THEN`/`ELSE`, para facilitar a leitura de `IF`s longos. Pode combinar mais de uma opção:

| Código | Efeito |
|---|---|
| `t` | Quebra a linha **depois** de `THEN` |
| `n` | Quebra a linha **antes** de `THEN` |
| `e` | Quebra a linha **depois** de `ELSE` |
| `b` | Quebra a linha **antes** de `ELSE` |

Padrão: `t` + `e`.

### Desmembrar dois-pontos (`:`)

Controla como a linha é quebrada em cada `:` (separador de instruções). Pode combinar mais de uma opção:

| Código | Efeito |
|---|---|
| `w` | Quebra a linha **sem** indentar |
| `i` | Quebra a linha **indentando** a partir do primeiro `:` |
| `c` | Coloca o `:` na linha **de baixo** |

Padrão: `i` + `c`.

### Regras avançadas de espaçamento (regex)

Para ajuste fino de como o espaçamento é aplicado ao redor de palavras-chave e símbolos, o painel avançado expõe expressões regulares (case insensitive) equivalentes às do projeto original. Só mexa aqui se precisar de um comportamento bem específico — os padrões cobrem a grande maioria dos casos.

| Opção | O que faz | Padrão |
|---|---|---|
| Repelir antes da palavra-chave | Caracteres que, antes de uma palavra-chave, forçam um espaço **antes** dela | `[a-z0-9{}")$]` |
| Repelir depois da palavra-chave | Caracteres que, depois de uma palavra-chave, forçam um espaço **depois** dela | `[a-z0-9{}"(]` |
| Juntar antes | Elementos antes dos quais os espaços devem ser **removidos** | `^(,|:)$` |
| Juntar depois | Elementos depois dos quais os espaços devem ser **removidos** | `^(,|:)$` |
| Forçar espaço antes | Elementos que **sempre** devem ter espaço antes | `^(:|\+|-|\*|/|\^|\\)$` |
| Forçar espaço depois | Elementos que **sempre** devem ter espaço depois | `^(#|\+|-|\*|/|\^|\\)$` |
| Forçar junção | Elementos que devem ficar sempre **colados**, sem espaço | `(<=|>=|=<|=>|\)-\()` |

---

## Fluxo recomendado

1. Abra ou importe o programa BASIC clássico na IDE.
2. Rode **"Converter para Dignified"**.
3. Revise o `.dmx` gerado — confira principalmente os rótulos criados a partir de `GOTO`/`GOSUB` e os `REM`s reposicionados, já que são os pontos mais sensíveis da conversão.
4. A partir daí, o arquivo `.dmx` segue o fluxo normal descrito em `BADIG-USER.md` — pode ser editado, compilado, tokenizado, etc.

> Assim como no módulo original, esta conversão é uma **ferramenta de partida**, não uma garantia de resultado perfeito — código clássico muito antigo, com truques de linha ou dialetos incomuns, pode exigir ajuste manual depois de convertido.
