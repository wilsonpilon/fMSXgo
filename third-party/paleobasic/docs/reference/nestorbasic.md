# NestorBASIC 1.11 - Referencia de funcoes

Gerado a partir de `nestor/SRC/NBASIC/nbas111e.txt` (manual original, by Nestor Soriano / Konami Man, 2004) e da mesma base de dados usada pela janela Ajuda -> Nestor Basic... do editor. Wrappers Dignified `.NB_*` sao gerados por Arquivo -> Novo Nestor Basic...

## Indice

- [Introducao](#introducao)
- [Funcoes gerais](#funcoes-gerais)
- [Acesso a segmentos (RAM)](#acesso-a-segmentos-ram)
- [Acesso a VRAM](#acesso-a-vram)
- [Acesso a disco](#acesso-a-disco)
- [Compressao e descompressao grafica](#compressao-e-descompressao-grafica)
- [Execucao de programas BASIC guardados em RAM](#execucao-de-programas-basic-guardados-em-ram)
- [Funcoes diversas](#funcoes-diversas)
- [Efeitos sonoros PSG](#efeitos-sonoros-psg)
- [Tocador Moonblaster](#tocador-moonblaster)
- [Controle de uso de segmentos](#controle-de-uso-de-segmentos)
- [NestorMan e InterNestor Suite/Lite](#nestorman-e-internestor-suitelite)

## Introducao

### Introducao ao NestorBASIC

NestorBASIC (by Nestor Soriano / Konami Man, 2004) e um conjunto de rotinas em codigo de maquina que da acesso, direto do MSX-BASIC, a memoria mapeada (ate 4Mb), VRAM inteira, disco/setores fisicos, compressao grafica, execucao de programas BASIC guardados em RAM, tocador Moonblaster, efeitos sonoros PSG e mais - tudo TurboBASIC-compativel.

## Carregamento
Uma unica vez por programa: `bload "nbasic.bin",r`. Depois disso:
- `p(0)` = numero de segmentos de RAM disponiveis (sempre >=5), ou codigo de erro (0 a 4) se a instalacao falhou
- O primeiro `usr()` (ou `usr0()`) fica reservado pro NestorBASIC - `usr1` a `usr9` continuam livres

**IMPORTANTE:** o carregamento NUNCA pode ser feito dentro de `func`/`ret` (GOSUB/RETURN) - o `bload...,r` mexe na pilha do BASIC, entao um RETURN depois quebra. Use GOTO/rotulo (ver o template gerado por Arquivo -> Novo Nestor Basic..., que ja faz isso certo).

## Modelo de chamada
Toda funcao usa `usr(numero)`, parametros/retornos no array inteiro `p()` (`defint p:dim p(15)` no minimo) e, quando a funcao mexe com nomes de arquivo ou texto, o array de strings `f$()` (`dim f$(1)` se precisar de duas strings ao mesmo tempo, `dim f$(0)` senao). O valor devolvido por `usr()` e sempre o codigo de erro (0 = sem erro). Cada topico de funcao aqui mostra o nome do wrapper Dignified `.NB_*` correspondente (gerado em Arquivo -> Novo Nestor Basic...) e um exemplo pronto de como chama-lo - use-os ao inves de montar `p()`/`usr()` na mao sempre que possivel.

## Segmentos logicos
A RAM mapeada e organizada em segmentos logicos de 16K (endereco `&H0000` a `&H3FFF` dentro de cada um), numerados de forma uniforme independente de slot/segmento fisico real:
- `0` = o proprio NestorBASIC
- `1` = TurboBASIC (so sobrescreva se nao for usar o compilador)
- `2` = RAM principal do BASIC, pagina 2 (`&H8000`-`&HBFFF`)
- `3` = RAM principal do BASIC, pagina 3 (`&HC000`-`&HFFFF`)
- `4` = buffer interno (usado pelas funcoes marcadas **(S4)** - nao guarde dados la enquanto usa-las)
- `5` a `p(0)-1` = livres pro programa (o `5` vira o tocador Moonblaster se `.NB_LoadPlayer` for chamado)
- `255` = alias especial pra RAM principal do BASIC (`&H8000`-`&HFFFF` direto, sem converter endereco)
- Acima de `p(0)-1`: segmentos de VRAM (ver .NB_VReadByte e funcoes de VRAM) - so nas funcoes que aceitam

## Sobre esta ajuda
Navegue pela arvore a esquerda (grupos = secoes do manual original) ou digite na caixa de busca pra filtrar por nome, numero de funcao ou grupo.

## Funcoes gerais

Instalacao/desinstalacao do NestorBASIC e informacoes gerais sobre ele e sobre um segmento.

### 0 - Desinstalar o NestorBASIC (S4)

**Wrapper Dignified:** `.NB_Uninstall`

**Como chamar:**
- `erro = .NB_Uninstall(liberarRam)`

Desinstala o NestorBASIC: libera o `usr()` e, no DOS 2, desaloca todos os segmentos. Tambem para qualquer interrupcao do usuario, efeito PSG ou musica em execucao. Sempre desinstale antes de voltar ao DOS - senao os segmentos alocados ficam presos ate reiniciar o computador.

## Entrada
- `p(0)` = 0 para NAO liberar a area de RAM principal do BASIC reservada pela rotina de salto (~500 bytes) - um CLEAR feito depois da instalacao continua valido; <>0 pra liberar (faz um CLEAR automatico, FRE(0) volta ao valor de antes de instalar - as variaveis sao reinicializadas)

Nunca retorna erro.

### 1 - Informacoes gerais e sobre um segmento

**Wrapper Dignified:** `.NB_GetInfo`

**Como chamar:**
- `numSegmentos, erro = .NB_GetInfo(segmento)`

Devolve informacoes gerais sobre o NestorBASIC instalado e sobre um segmento especifico.

## Entrada
- `p(0)` = segmento logico a investigar

## Saida
- `p(0)` = numero de segmentos de RAM disponiveis
- `p(1)` = versao principal do NestorBASIC
- `p(2)` = versao secundaria (BCD, mostrar em hexadecimal)
- `p(3)` = versao principal do MSX-DOS
- `p(4)` = versao secundaria do MSX-DOS (BCD, mostrar em hexadecimal)
- `p(5)` = tamanho ocupado na RAM principal pela rotina de salto do NestorBASIC
- `p(6)` = tamanho da VRAM em K (64 ou 128)
- `p(7)` = endereco inicial da area livre no segmento 0 (maximo `&H3DA8`; ha um bug documentado no manual original - o valor volta pertencendo a pagina 1, ex. `&H7C60`, e precisa ser ajustado pro intervalo `&H0000`-`&H4000` antes de usar)
- `p(8)` = numero da ultima funcao chamada (esta funcao 1 nao conta)
- `p(9)` = numero de arquivos abertos no momento
- `p(10)` = numero maximo de arquivos simultaneos (so vale sob DOS 1)
- `p(11)` = slot do segmento pedido em `p(0)` (255 se nao existir ou for VRAM)
- `p(12)` = segmento fisico do segmento pedido em `p(0)`
- `f$(0)` = caminho completo do arquivo NBASIC.BIN

## Erros
-1 = o segmento pedido em `p(0)` nao existe, e VRAM ou e o 255 (mesmo assim, `p(0)` a `p(10)` continuam validos).

## Acesso a segmentos (RAM)

Leitura, escrita, copia e preenchimento de bytes/inteiros dentro dos segmentos logicos de RAM (funcoes 2 a 12). Endereco sempre no intervalo `&H0000`-`&H3FFF` dentro do segmento.

### 2 - Ler um byte de um segmento

**Wrapper Dignified:** `.NB_ReadByte`

**Como chamar:**
- `byte, erro = .NB_ReadByte(segmento, endereco)`

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco

## Saida
- `p(2)` = byte lido

### 3 - Ler um byte de um segmento (com autoincremento)

**Wrapper Dignified:** `.NB_ReadByteInc`

**Como chamar:**
- `byte, novoEndereco, erro = .NB_ReadByteInc(segmento, endereco)`

Igual a funcao 2, mas devolve o endereco seguinte - util pra ler sequencialmente em loop.

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco

## Saida
- `p(2)` = byte lido
- `p(1)` = `p(1)+1`

### 4 - Ler um inteiro de um segmento

**Wrapper Dignified:** `.NB_ReadInt`

**Como chamar:**
- `valor, erro = .NB_ReadInt(segmento, endereco)`

Le 2 bytes (byte baixo no endereco, byte alto no endereco+1).

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco

## Saida
- `p(2)` = inteiro lido

### 5 - Ler um inteiro de um segmento (com autoincremento)

**Wrapper Dignified:** `.NB_ReadIntInc`

**Como chamar:**
- `valor, novoEndereco, erro = .NB_ReadIntInc(segmento, endereco)`

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco

## Saida
- `p(2)` = inteiro lido
- `p(1)` = `p(1)+2`

### 6 - Escrever um byte num segmento

**Wrapper Dignified:** `.NB_WriteByte`

**Como chamar:**
- `erro = .NB_WriteByte(segmento, endereco, valor)`

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco
- `p(2)` = byte a escrever

### 7 - Escrever um byte num segmento (com autoincremento)

**Wrapper Dignified:** `.NB_WriteByteInc`

**Como chamar:**
- `novoEndereco, erro = .NB_WriteByteInc(segmento, endereco, valor)`

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco
- `p(2)` = byte a escrever

## Saida
- `p(1)` = `p(1)+1`

### 8 - Escrever um inteiro num segmento

**Wrapper Dignified:** `.NB_WriteInt`

**Como chamar:**
- `erro = .NB_WriteInt(segmento, endereco, valor)`

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco
- `p(2)` = inteiro a escrever

### 9 - Escrever um inteiro num segmento (com autoincremento)

**Wrapper Dignified:** `.NB_WriteIntInc`

**Como chamar:**
- `novoEndereco, erro = .NB_WriteIntInc(segmento, endereco, valor)`

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco
- `p(2)` = inteiro a escrever

## Saida
- `p(1)` = `p(1)+2`

### 10 - Copiar um bloco entre segmentos

**Wrapper Dignified:** `.NB_CopySegToSeg`

**Como chamar:**
- `novoEndOrigem, novoEndDestino, erro = .NB_CopySegToSeg(segOrigem, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)`

`p(3)+p(4)` precisa ficar abaixo de `&H4000`, senao o resultado e imprevisivel.

## Entrada
- `p(0)` = segmento de origem
- `p(1)` = endereco de origem
- `p(2)` = segmento de destino
- `p(3)` = endereco de destino
- `p(4)` = tamanho
- `p(5)` = <>0 autoincrementa `p(1)`
- `p(6)` = <>0 autoincrementa `p(3)`

## Saida
- `p(1)` = `p(1)+p(4)` se `p(5)<>0`
- `p(3)` = `p(3)+p(4)` se `p(6)<>0`

### 11 - Preencher uma area de RAM com um byte

**Wrapper Dignified:** `.NB_FillRam`

**Como chamar:**
- `erro = .NB_FillRam(segmento, endereco, byte, tamanho)`

`p(1)+p(3)` precisa ficar abaixo de `&H4000`.

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco inicial
- `p(2)` = byte
- `p(3)` = tamanho da area

### 12 - Preencher uma area de RAM com um byte (com autoincremento)

**Wrapper Dignified:** `.NB_FillRamInc`

**Como chamar:**
- `novoEndereco, erro = .NB_FillRamInc(segmento, endereco, byte, tamanho)`

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco inicial
- `p(2)` = byte
- `p(3)` = tamanho da area

## Saida
- `p(1)` = `p(1)+p(3)`

## Acesso a VRAM

Leitura, escrita, copia e preenchimento na VRAM inteira (funcoes 13 a 25). `bloco` = 0 (64K VRAM baixa) ou 1 (64K VRAM alta, so em maquinas com 128K); endereco `&H0000`-`&HFFFF`. Se um autoincremento passar de `&HFFFF`, o endereco volta a 0 e o bloco se inverte (0<->1).

### 13 - Ler um byte da VRAM

**Wrapper Dignified:** `.NB_VReadByte`

**Como chamar:**
- `byte, erro = .NB_VReadByte(bloco, endereco)`

## Entrada
- `p(0)` = bloco
- `p(1)` = endereco

## Saida
- `p(2)` = byte lido

### 14 - Ler um byte da VRAM (com autoincremento)

**Wrapper Dignified:** `.NB_VReadByteInc`

**Como chamar:**
- `byte, novoBloco, novoEndereco, erro = .NB_VReadByteInc(bloco, endereco)`

## Entrada
- `p(0)` = bloco
- `p(1)` = endereco

## Saida
- `p(2)` = byte lido
- `p(0):p(1)` = `p(0):p(1)+1` (pode virar o bloco)

### 15 - Ler um inteiro da VRAM

**Wrapper Dignified:** `.NB_VReadInt`

**Como chamar:**
- `valor, erro = .NB_VReadInt(bloco, endereco)`

## Entrada
- `p(0)` = bloco
- `p(1)` = endereco

## Saida
- `p(2)` = inteiro lido

### 16 - Ler um inteiro da VRAM (com autoincremento)

**Wrapper Dignified:** `.NB_VReadIntInc`

**Como chamar:**
- `valor, novoBloco, novoEndereco, erro = .NB_VReadIntInc(bloco, endereco)`

## Entrada
- `p(0)` = bloco
- `p(1)` = endereco

## Saida
- `p(2)` = inteiro lido
- `p(0):p(1)` = `p(0):p(1)+2`

### 17 - Escrever um byte na VRAM

**Wrapper Dignified:** `.NB_VWriteByte`

**Como chamar:**
- `erro = .NB_VWriteByte(bloco, endereco, valor)`

## Entrada
- `p(0)` = bloco
- `p(1)` = endereco
- `p(2)` = byte a escrever

### 18 - Escrever um byte na VRAM (com autoincremento)

**Wrapper Dignified:** `.NB_VWriteByteInc`

**Como chamar:**
- `novoBloco, novoEndereco, erro = .NB_VWriteByteInc(bloco, endereco, valor)`

## Entrada
- `p(0)` = bloco
- `p(1)` = endereco
- `p(2)` = byte a escrever

## Saida
- `p(0):p(1)` = `p(0):p(1)+1`

### 19 - Escrever um inteiro na VRAM

**Wrapper Dignified:** `.NB_VWriteInt`

**Como chamar:**
- `erro = .NB_VWriteInt(bloco, endereco, valor)`

## Entrada
- `p(0)` = bloco
- `p(1)` = endereco
- `p(2)` = inteiro a escrever

### 20 - Escrever um inteiro na VRAM (com autoincremento)

**Wrapper Dignified:** `.NB_VWriteIntInc`

**Como chamar:**
- `novoBloco, novoEndereco, erro = .NB_VWriteIntInc(bloco, endereco, valor)`

## Entrada
- `p(0)` = bloco
- `p(1)` = endereco
- `p(2)` = inteiro a escrever

## Saida
- `p(0):p(1)` = `p(0):p(1)+2`

### 21 - Copiar um bloco da VRAM pra RAM

**Wrapper Dignified:** `.NB_CopyVramToRam`

**Como chamar:**
- `novoBlocoOrigem, novoEndOrigem, novoEndDestino, erro = .NB_CopyVramToRam(blocoOrigem, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)`

`p(3)+p(4)` precisa ficar abaixo de `&H4000`.

## Entrada
- `p(0)` = bloco de origem (VRAM)
- `p(1)` = endereco de origem (VRAM)
- `p(2)` = segmento de destino
- `p(3)` = endereco de destino
- `p(4)` = tamanho
- `p(5)` = <>0 autoincrementa origem
- `p(6)` = <>0 autoincrementa destino

## Saida
- `p(1)` = `p(1)+p(4)` se `p(5)<>0`
- `p(2):p(3)` = `p(2):p(3)+p(4)` se `p(6)<>0`

### 22 - Copiar um bloco da RAM pra VRAM

**Wrapper Dignified:** `.NB_CopyRamToVram`

**Como chamar:**
- `novoEndOrigem, novoBlocoDestino, novoEndDestino, erro = .NB_CopyRamToVram(segOrigem, endOrigem, blocoDestino, endDestino, tamanho, incOrigem, incDestino)`

## Entrada
- `p(0)` = segmento de origem
- `p(1)` = endereco de origem
- `p(2)` = bloco de destino (VRAM)
- `p(3)` = endereco de destino (VRAM)
- `p(4)` = tamanho
- `p(5)` = <>0 autoincrementa origem
- `p(6)` = <>0 autoincrementa destino

## Saida
- `p(1)` = `p(1)+p(4)` se `p(5)<>0`
- `p(2):p(3)` = `p(2):p(3)+p(4)` se `p(6)<>0`

### 23 - Copiar um bloco entre duas areas da VRAM

**Wrapper Dignified:** `.NB_CopyVramToVram`

**Como chamar:**
- `novoBlocoOrigem, novoEndOrigem, novoBlocoDestino, novoEndDestino, erro = .NB_CopyVramToVram(blocoOrigem, endOrigem, blocoDestino, endDestino, tamanho, incOrigem, incDestino)`

Tamanho maximo `&H4000` bytes por chamada - pra blocos maiores (ate 64K), repita a chamada incrementando os enderecos a cada volta.

## Entrada
- `p(0)` = bloco de origem
- `p(1)` = endereco de origem
- `p(2)` = bloco de destino
- `p(3)` = endereco de destino
- `p(4)` = tamanho (maximo `&H4000`)
- `p(5)` = <>0 autoincrementa origem
- `p(6)` = <>0 autoincrementa destino

## Saida
- `p(0):p(1)` = `p(0):p(1)+p(4)` se `p(5)<>0`
- `p(2):p(3)` = `p(2):p(3)+p(4)` se `p(6)<>0`

### 24 - Preencher uma area de VRAM com um byte

**Wrapper Dignified:** `.NB_FillVram`

**Como chamar:**
- `erro = .NB_FillVram(bloco, endereco, byte, tamanho)`

Maximo 16K por chamada.

## Entrada
- `p(0)` = bloco
- `p(1)` = endereco inicial
- `p(2)` = byte
- `p(3)` = tamanho da area (maximo 16K)

### 25 - Preencher uma area de VRAM com um byte (com autoincremento)

**Wrapper Dignified:** `.NB_FillVramInc`

**Como chamar:**
- `novoBloco, novoEndereco, erro = .NB_FillVramInc(bloco, endereco, byte, tamanho)`

Maximo 16K por chamada.

## Entrada
- `p(0)` = bloco
- `p(1)` = endereco inicial
- `p(2)` = byte
- `p(3)` = tamanho da area (maximo 16K)

## Saida
- `p(0):p(1)` = `p(0):p(1)+p(3)`

## Acesso a disco

Arquivos, diretorios, setores fisicos, unidades e RAM disk (funcoes 26 a 52). Atributos: `R+2*H+4*S+8*V+16*D+32*A` (Somente leitura+Oculto+Sistema+Volume+Diretorio+Arquivo). Unidade normalmente `0=A:,1=B:,...,7=H:` - EXCETO em .NB_GetDiskSpace e .NB_GetDir, onde e `0=unidade padrao,1=A:,...,8=H:` (assim mesmo no manual original).

### 26 - Procurar arquivos (S4)

**Wrapper Dignified:** `.NB_FindFile`

**Como chamar:**
- `nomeArquivo$, erro = .NB_FindFile(mascara$, buscarProximo, atributosBusca)`

`buscarProximo=0` procura o primeiro arquivo que bate com a mascara (vazia = `*.*`); deixe `1` pras buscas seguintes (a propria funcao mantem isso em `p(0)`).

## Entrada
- `f$(1)` = mascara de busca (pode ter unidade e, no DOS 2, caminho)
- `p(0)` = 0 primeira busca / 1 proxima busca
- `p(1)` = atributos de busca: `2*H+4*S+8*V+16*D` (incluir Ocultos/Sistema/so Volume/Diretorios)

## Saida
- `f$(0)` = nome do arquivo encontrado
- `p(0)` = 1
- `p(1)` = atributos do arquivo (sempre 0 no DOS 1): `R+2*H+4*S+8*V+16*D+32*A`
- `p(2)` a `p(6)` = hora, minuto, dia, mes, ano da ultima modificacao
- `p(7)` = primeiro cluster (2 a 4095)
- `p(8)` = unidade logica (0=A:,...,7=H:)
- `p(9)`/`p(10)` = tamanho do arquivo, parte baixa/alta (`p(9)+65536*p(10)`)
- `p(11)` = contador de resultados (0 se nao achou na primeira busca; incrementa a cada busca seguinte)

Erro quando nao ha mais arquivos batendo com a mascara (erro de arquivo nao encontrado).

### 27 - Renomear um arquivo (S4)

**Wrapper Dignified:** `.NB_RenameFile`

**Como chamar:**
- `erro = .NB_RenameFile(nome$, novoNome$)`

No DOS 1 aceita curingas e renomeia varios de uma vez; no DOS 2 so um arquivo por chamada.

## Entrada
- `f$(0)` = nome atual
- `f$(1)` = nome novo (so o nome, sem unidade/caminho)

### 28 - Apagar um arquivo (S4)

**Wrapper Dignified:** `.NB_DeleteFile`

**Como chamar:**
- `erro = .NB_DeleteFile(nome$)`

No DOS 1 aceita curingas (apaga varios de uma vez); no DOS 2 so um arquivo, e da erro se estiver aberto.

## Entrada
- `f$(0)` = nome do arquivo (pode ter unidade e, no DOS 2, caminho)

### 29 - Mover um arquivo (DOS 2)

**Wrapper Dignified:** `.NB_MoveFile`

**Como chamar:**
- `erro = .NB_MoveFile(nome$, novoLocal$)`

So existe no DOS 2 (no DOS 1 sempre da erro 1). Move uma pasta inteira move tambem seu conteudo.

## Entrada
- `f$(0)` = nome/caminho atual
- `f$(1)` = novo local (so o caminho, sem nome de arquivo nem letra de unidade - so pode mover dentro da mesma unidade)

### 30 - Criar um arquivo ou diretorio

**Wrapper Dignified:** `.NB_CreateFile`

**Como chamar:**
- `erro = .NB_CreateFile(nome$, atributos)`

O arquivo criado fica com 0 bytes e fechado (abra depois com .NB_OpenFile). No DOS 1 so cria arquivos e `p(0)` e ignorado; no DOS 2 sempre cria com o atributo Archive alem dos pedidos.

## Entrada
- `f$(0)` = nome do arquivo/subdiretorio (pode ter unidade e caminho)
- `p(0)` = atributos de criacao (ignorado no DOS 1): `R+2*H+4*S` (arquivo) ou `2*H+16` (diretorio)

### 31 - Abrir um arquivo

**Wrapper Dignified:** `.NB_OpenFile`

**Como chamar:**
- `numeroArquivo, erro = .NB_OpenFile(nome$)`

## Entrada
- `f$(0)` = nome do arquivo (pode ter unidade e, no DOS 2, caminho)

## Saida
- `p(0)` = numero atribuido ao arquivo (use nas demais funcoes de arquivo)

No DOS 1, erro 3 = ja tem arquivos demais abertos (o maximo sai de .NB_GetInfo).

### 32 - Fechar um arquivo

**Wrapper Dignified:** `.NB_CloseFile`

**Como chamar:**
- `erro = .NB_CloseFile(numeroArquivo)`

Sempre feche um arquivo que nao vai mais usar - senao dados escritos podem ficar presos nos buffers internos do DOS, e a entrada de diretorio pode nao ser atualizada.

## Entrada
- `p(0)` = numero do arquivo

### 33 - Ler de um arquivo (S4)

**Wrapper Dignified:** `.NB_ReadFile`

**Como chamar:**
- `bytesLidos, novoEnderecoDestino, erro = .NB_ReadFile(numeroArquivo, segDestino, enderecoDestino, tamanho, incrementar)`

Le a partir da posicao atual do ponteiro do arquivo (avanca sozinho depois). Pra ler ate o fim (ou o arquivo inteiro, se for menor que 16K), peca 16K (`tamanho=&H4000`) e ignore erro 1/199 (so significam fim de arquivo).

## Entrada
- `p(0)` = numero do arquivo
- `p(2)` = segmento de destino
- `p(3)` = endereco de destino
- `p(4)` = numero de bytes a ler
- `p(6)` = <>0 avanca `p(3)`

## Saida
- `p(7)` = bytes realmente lidos
- `p(3)` = `p(3)+p(4)` se `p(6)<>0`

### 34 - Ler de um arquivo pra VRAM (S4)

**Wrapper Dignified:** `.NB_ReadFileToVram`

**Como chamar:**
- `bytesLidos, novoBlocoDestino, novoEnderecoDestino, erro = .NB_ReadFileToVram(numeroArquivo, blocoDestino, enderecoDestino, tamanho, incrementar)`

Maximo `&H4000` bytes por chamada.

## Entrada
- `p(0)` = numero do arquivo
- `p(2)` = bloco de destino (VRAM)
- `p(3)` = endereco de destino
- `p(4)` = numero de bytes a ler (maximo `&H4000`)
- `p(6)` = <>0 avanca `p(3)`

## Saida
- `p(7)` = bytes realmente lidos
- `p(2):p(3)` = `p(2):p(3)+p(4)` se `p(6)<>0`

### 35 - Ler setores do disco (S4)

**Wrapper Dignified:** `.NB_ReadSectors`

**Como chamar:**
- `bytesLidos, novoEnderecoDestino, erro = .NB_ReadSectors(unidade, primeiroSetor, segDestino, enderecoDestino, numSetores, incrementar)`

Leitura bruta, direto por setor fisico (nao passa por arquivo). Sem leitura parcial: erro = `p(7)` volta 0; sem erro = `p(7)` = `p(4)*512`. Maximo 32 setores (16K) por chamada.

## Entrada
- `p(0)` = unidade (0=A:,...,7=H:)
- `p(1)` = primeiro setor
- `p(2)` = segmento de destino
- `p(3)` = endereco de destino
- `p(4)` = numero de setores (maximo 32)
- `p(6)` = <>0 avanca `p(3)`

## Saida
- `p(7)` = `p(4)*512` (0 se deu erro)
- `p(3)` = `p(3)+p(4)*512` se `p(6)<>0`

### 36 - Ler setores do disco pra VRAM (S4)

**Wrapper Dignified:** `.NB_ReadSectorsToVram`

**Como chamar:**
- `bytesLidos, novoBlocoDestino, novoEnderecoDestino, erro = .NB_ReadSectorsToVram(unidade, primeiroSetor, blocoDestino, enderecoDestino, numSetores, incrementar)`

Maximo 32 setores (16K) por chamada.

## Entrada
- `p(0)` = unidade
- `p(1)` = primeiro setor
- `p(2)` = bloco de destino (VRAM)
- `p(3)` = endereco de destino
- `p(4)` = numero de setores (maximo 32)
- `p(6)` = <>0 avanca `p(3)`

## Saida
- `p(7)` = `p(4)*512` (0 se deu erro)
- `p(2):p(3)` = `p(2):p(3)+p(4)*512` se `p(6)<>0`

### 37 - Escrever num arquivo (S4)

**Wrapper Dignified:** `.NB_WriteFile`

**Como chamar:**
- `bytesEscritos, novoEnderecoOrigem, erro = .NB_WriteFile(numeroArquivo, segOrigem, enderecoOrigem, tamanho, incrementar)`

Escreve a partir da posicao atual do ponteiro (avanca sozinho depois).

## Entrada
- `p(0)` = numero do arquivo
- `p(2)` = segmento de origem
- `p(3)` = endereco de origem
- `p(4)` = numero de bytes a escrever
- `p(6)` = <>0 avanca `p(3)`

## Saida
- `p(7)` = bytes realmente escritos
- `p(3)` = `p(3)+p(4)` se `p(6)<>0`

### 38 - Escrever num arquivo a partir da VRAM (S4)

**Wrapper Dignified:** `.NB_WriteFileFromVram`

**Como chamar:**
- `bytesEscritos, novoBlocoOrigem, novoEnderecoOrigem, erro = .NB_WriteFileFromVram(numeroArquivo, blocoOrigem, enderecoOrigem, tamanho, incrementar)`

Maximo `&H4000` bytes por chamada.

## Entrada
- `p(0)` = numero do arquivo
- `p(2)` = bloco de origem (VRAM)
- `p(3)` = endereco de origem
- `p(4)` = numero de bytes (maximo `&H4000`)
- `p(6)` = <>0 avanca `p(3)`

## Saida
- `p(7)` = bytes realmente escritos
- `p(2):p(3)` = `p(2):p(3)+p(4)` se `p(6)<>0`

### 39 - Escrever setores do disco (S4)

**Wrapper Dignified:** `.NB_WriteSectors`

**Como chamar:**
- `bytesEscritos, novoEnderecoOrigem, erro = .NB_WriteSectors(unidade, primeiroSetor, segOrigem, enderecoOrigem, numSetores, incrementar)`

Sem escrita parcial. Maximo 32 setores (16K) por chamada.

## Entrada
- `p(0)` = unidade
- `p(1)` = primeiro setor
- `p(2)` = segmento de origem
- `p(3)` = endereco de origem
- `p(4)` = numero de setores (maximo 32)
- `p(6)` = <>0 avanca `p(3)`

## Saida
- `p(7)` = `p(4)*512` (0 se deu erro)
- `p(3)` = `p(3)+p(4)*512` se `p(6)<>0`

### 40 - Escrever setores do disco a partir da VRAM (S4)

**Wrapper Dignified:** `.NB_WriteSectorsFromVram`

**Como chamar:**
- `bytesEscritos, novoBlocoOrigem, novoEnderecoOrigem, erro = .NB_WriteSectorsFromVram(unidade, primeiroSetor, blocoOrigem, enderecoOrigem, numSetores, incrementar)`

Maximo 32 setores (16K) por chamada.

## Entrada
- `p(0)` = unidade
- `p(1)` = primeiro setor
- `p(2)` = bloco de origem (VRAM)
- `p(3)` = endereco de origem
- `p(4)` = numero de setores (maximo 32)
- `p(6)` = <>0 avanca `p(3)`

## Saida
- `p(7)` = `p(4)*512` (0 se deu erro)
- `p(2):p(3)` = `p(2):p(3)+p(4)*512` se `p(6)<>0`

### 41 - Preencher um arquivo com um byte (S4)

**Wrapper Dignified:** `.NB_FillFile`

**Como chamar:**
- `bytesEscritos, erro = .NB_FillFile(numeroArquivo, byte, tamanho)`

Maximo `&H4000` por chamada.

## Entrada
- `p(0)` = numero do arquivo
- `p(1)` = byte
- `p(4)` = tamanho (maximo `&H4000`)

## Saida
- `p(7)` = bytes realmente escritos

### 42 - Mover o ponteiro de um arquivo

**Wrapper Dignified:** `.NB_SeekFile`

**Como chamar:**
- `novaPosBaixa, novaPosAlta, erro = .NB_SeekFile(numeroArquivo, metodo, offsetBaixo, offsetAlto)`

Pra saber a posicao atual sem mover: `metodo=1, offsetBaixo=0, offsetAlto=0`. Pro tamanho do arquivo: `metodo=2, offsetBaixo=0, offsetAlto=0`.

## Entrada
- `p(0)` = numero do arquivo
- `p(1)` = metodo: 0=a partir do inicio, 1=a partir da posicao atual, 2=a partir do fim
- `p(2)`/`p(3)` = deslocamento com sinal, parte baixa/alta (16 bits cada)

## Saida
- `p(4)`/`p(5)` = nova posicao do ponteiro, parte baixa/alta

### 43 - Obter a unidade padrao e as disponiveis

**Wrapper Dignified:** `.NB_GetDrives`

**Como chamar:**
- `unidadePadrao, vetorUnidades, erro = .NB_GetDrives()`

## Saida
- `p(0)` = unidade padrao (0=A:,...,7=H:)
- `p(1)` = vetor de bits das unidades disponiveis (bit 0 = A:, bit mais alto = H:)

### 44 - Definir a unidade padrao

**Wrapper Dignified:** `.NB_SetDrive`

**Como chamar:**
- `erro = .NB_SetDrive(unidade)`

## Entrada
- `p(0)` = unidade a definir (0=A:,...,7=H:)

Erro 62 = unidade invalida (nao existe ou maior que 7).

### 45 - Obter informacoes de espaco em disco

**Wrapper Dignified:** `.NB_GetDiskSpace`

**Como chamar:**
- `setoresPorCluster, totalClusters, clustersLivres, erro = .NB_GetDiskSpace(unidade)`

Espaco livre em bytes = `p(1)*p(3)*512`; em K = `p(1)*p(3)/2` (e o mesmo trocando `p(3)` por `p(2)` pro total).

## Entrada
- `p(0)` = unidade (0=padrao,1=A:,...,8=H: - reparar que aqui e diferente!)

## Saida
- `p(1)` = setores por cluster
- `p(2)` = total de clusters (maximo 4096)
- `p(3)` = clusters livres

### 46 - Obter o diretorio padrao (DOS 2)

**Wrapper Dignified:** `.NB_GetDir`

**Como chamar:**
- `diretorio$, erro = .NB_GetDir(unidade)`

So existe no DOS 2 (no DOS 1 sempre da erro 1). String devolvida nao tem letra de unidade nem barra no inicio/fim; raiz = string vazia.

## Entrada
- `p(0)` = unidade (0=padrao,1=A:,...,8=H: - reparar que aqui e diferente!)

## Saida
- `f$(0)` = diretorio padrao

### 47 - Definir o diretorio padrao (DOS 2)

**Wrapper Dignified:** `.NB_SetDir`

**Como chamar:**
- `erro = .NB_SetDir(caminho$)`

So existe no DOS 2. Nao muda a unidade padrao (use .NB_SetDrive pra isso).

## Entrada
- `f$(0)` = unidade (opcional) + diretorio

### 48 - Obter o tamanho do RAM disk (DOS 2)

**Wrapper Dignified:** `.NB_GetRamDiskSize`

**Como chamar:**
- `tamanho16k, erro = .NB_GetRamDiskSize()`

So existe no DOS 2. Tamanho em K = resultado*16; 0 = RAM disk nao existe.

## Saida
- `p(0)` = tamanho em segmentos de 16K

### 49 - Criar o RAM disk (DOS 2)

**Wrapper Dignified:** `.NB_CreateRamDisk`

**Como chamar:**
- `tamanhoCriado, erro = .NB_CreateRamDisk(tamanho16k)`

So existe no DOS 2. Por padrao o NestorBASIC ja pegou todos os segmentos livres pra si ao instalar - use .NB_SetSegmentCount pra liberar segmentos antes de chamar esta funcao. Se nao houver o tamanho pedido mas der pra criar um menor, cria e nao da erro (so retorna o tamanho real criado); se nao houver segmento nenhum, da erro.

## Entrada
- `p(0)` = tamanho pedido em segmentos de 16K

## Saida
- `p(0)` = tamanho realmente criado

### 50 - Obter os atributos de um arquivo (DOS 2)

**Wrapper Dignified:** `.NB_GetAttrByHandle / .NB_GetAttrByName`

**Como chamar:**
- `atributos, erro = .NB_GetAttrByHandle(numeroArquivo)`
- `atributos, erro = .NB_GetAttrByName(nome$)`

So existe no DOS 2. No manual original e uma unica funcao (`p(0)=255` + `f$(0)` = nome pra consultar por nome, ao inves de numero de arquivo ja aberto) - aqui virou dois wrappers separados pra nao precisar lembrar do valor magico 255.

## Saida
- `p(1)` = atributos: `R+2*H+4*S+8*V+16*D+32*A`

### 51 - Definir os atributos de um arquivo (DOS 2)

**Wrapper Dignified:** `.NB_SetAttrByHandle / .NB_SetAttrByName`

**Como chamar:**
- `atributosFinal, erro = .NB_SetAttrByHandle(numeroArquivo, atributos)`
- `atributosFinal, erro = .NB_SetAttrByName(nome$, atributos)`

So existe no DOS 2. So da pra mudar Sistema/Oculto/Somente leitura/Archive num arquivo (Oculto num diretorio); tentar mudar qualquer outro atributo da erro. Nao da pra mudar pelo nome um arquivo que ja esta aberto - use a versao por numero nesse caso.

## Saida
- `p(1)` = atributos realmente definidos

### 52 - Interpretar um caminho (DOS 2)

**Wrapper Dignified:** `.NB_ParsePath`

**Como chamar:**
- `ultimoItem$, unidadeLogica, erro = .NB_ParsePath(caminho$, ehVolume)`

So existe no DOS 2. So trata a string (nao acessa o disco, nao muda unidade/diretorio padrao).

## Entrada
- `f$(0)` = caminho a interpretar
- `p(10)` = <>0 se o caminho se refere a um rotulo de volume

## Saida
- `f$(1)` = ultimo item do caminho
- `p(8)` = unidade logica (1=A:,...,8=H:)
- `p(9)` = posicao do ultimo item na string (0 se nao ha ultimo item)
- `p(0)` a `p(7)` = varios booleanos -1/0 (contem caracteres alem da unidade, tem diretorio, tem unidade, tem nome de arquivo, tem extensao, ultimo item ambiguo, ultimo item e ponto/ponto-ponto, ultimo item e ponto-ponto - todos 0 se `p(10)<>0`)

## Compressao e descompressao grafica

Formato de compressao Sunrise (o mesmo usado no logo da Sunrise): bytes nao repetidos (`&B00nnnnnn` + n bytes), byte repetido ate 63 vezes (`&B01nnnnnn` + 1 byte), byte repetido ate 16383 vezes (`&B10nnnnnn nnnnnnnn` + 1 byte) e marca de fim (`&HC0`). A (des)compressao continua sozinha no proximo segmento quando enche o atual (funcoes 53/54).

### 53 - Comprimir dados graficos

**Wrapper Dignified:** `.NB_CompressGraphics`

**Como chamar:**
- `tamanhoComprimido, segmentosUsados, novoBlocoOrigem, novoEndOrigem, novoSegDestino, novoEndDestino, erro = .NB_CompressGraphics(blocoOrigem, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)`

Comprime da VRAM pra um ou mais segmentos consecutivos de RAM - se encher um segmento, continua sozinha no proximo (por isso segmento/endereco de destino podem voltar diferentes do que foi passado). Nao suporta segmentos VRAM nem o 255 como destino.

## Entrada
- `p(0)` = bloco de origem (VRAM)
- `p(1)` = endereco de origem
- `p(2)` = primeiro segmento de destino
- `p(3)` = endereco de destino
- `p(4)` = tamanho dos dados a comprimir
- `p(5)` = <>0 avanca origem
- `p(6)` = <>0 avanca destino

## Saida
- `p(7)` = tamanho comprimido em RAM
- `p(8)` = numero de segmentos de RAM usados
- `p(0):p(1)` = `p(0):p(1)+p(4)` se `p(5)<>0`
- `p(2):p(3)` = endereco seguinte ao ultimo usado, se `p(6)<>0`

## Erros
5 = os segmentos acabaram antes de terminar de comprimir todos os dados pedidos.

### 54 - Descomprimir dados graficos

**Wrapper Dignified:** `.NB_DecompressGraphics`

**Como chamar:**
- `tamanhoDescomprimido, segmentosUsados, novoBlocoDestino, novoEndDestino, novoSegOrigem, novoEndOrigem, erro = .NB_DecompressGraphics(blocoDestino, endDestino, segOrigem, endOrigem, incDestino, incOrigem)`

Descomprime de um ou mais segmentos consecutivos de RAM pra VRAM (mesma logica de continuar sozinha no proximo segmento). Nao suporta segmentos VRAM nem o 255 como origem.

## Entrada
- `p(0)` = bloco de destino (VRAM)
- `p(1)` = endereco de destino
- `p(2)` = primeiro segmento de origem
- `p(3)` = endereco de origem
- `p(5)` = <>0 avanca destino
- `p(6)` = <>0 avanca origem

## Saida
- `p(7)` = tamanho descomprimido em VRAM
- `p(8)` = numero de segmentos de RAM usados
- `p(0):p(1)` = `p(0):p(1)+p(7)` se `p(5)<>0`
- `p(2):p(3)` = endereco seguinte ao ultimo usado, se `p(6)<>0`

## Erros
6 = dado invalido encontrado, ou os segmentos acabaram sem achar a marca de fim.

## Execucao de programas BASIC guardados em RAM

Guardar programas BASIC inteiros num segmento e trocar de programa preservando variaveis (funcoes 55 a 57). **Pre-requisito obrigatorio:** o endereco inicial dos programas BASIC precisa ter sido trocado de `&H8000` pra `&H8003` ANTES de instalar o NestorBASIC - uma unica vez, com `poke &Hf676,4:poke &H8003,0:new` (o ideal e fazer isso logo na primeira linha do programa que tambem carrega o NestorBASIC, testando `if peek(&Hf676)<>4 then ...`).

### 55 - Executar um programa BASIC guardado em RAM (S4)

**Wrapper Dignified:** `.NB_RunBasicProgram`

**Como chamar:**
- `erro = .NB_RunBasicProgram(segmento, endereco)`

Se der certo, o programa atual NUNCA retorna daqui - o novo programa roda da linha 1, com as variaveis numericas do programa atual preservadas (strings tambem, desde que estejam na area de strings do BASIC - force isso com `c$=c$+""` antes de chamar, se precisar). So retorna em caso de erro.

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco inicial

## Erros
-1 = segmento nao existe (ou e o 255).
-2 = RAM principal do BASIC insuficiente pro novo programa + variaveis existentes.

### 56 - Ativar um programa BASIC guardado em RAM (S4)

**Wrapper Dignified:** `.NB_ActivateBasicProgram`

**Como chamar:**
- `erro = .NB_ActivateBasicProgram(segmento, endereco)`

Igual a funcao 55, mas ao inves de rodar da linha 1, larga no modo direto (programa carregado e pronto, mas parado). Se der certo tambem nunca retorna daqui; mesmos erros de 55.

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco inicial

### 57 - Salvar o programa BASIC ativo com cabecalho especial (S4)

**Wrapper Dignified:** `.NB_SaveBasicProgram`

**Como chamar:**
- `arquivoAberto, erro = .NB_SaveBasicProgram(byteCabecalho, nome$)`

Salva com o cabecalho que as funcoes 55/56 esperam pra depois carregar (com .NB_ReadFile, por exemplo) num segmento e ativar/executar.

## Entrada
- `p(0)` = byte salvo na primeira posicao do cabecalho (o NestorBASIC nao usa, livre pro programa)
- `f$(0)` = caminho + nome do arquivo

## Saida
- `p(1)` = -1 se nao deu erro; senao, o numero do arquivo (ainda aberto) onde ocorreu o erro de disco - feche com .NB_CloseFile antes de tentar de novo

## Funcoes diversas

Execucao de codigo de maquina (BIOS/SUB-BIOS/RAM/segmento), strings em segmento, modo piscante da SCREEN 0 e interrupcao definida pelo usuario (funcoes 58 a 66).

### 58 - Executar codigo de maquina (BIOS/SUB-BIOS/RAM/area de sistema)

**Wrapper Dignified:** `.NB_ExecCode`

**Como chamar:**
- `af, bc, de, hl, ix, iy, af2, bc2, de2, hl2, a, cy, z, erro = .NB_ExecCode(subBios, endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)`

`subBios=0` executa direto (BIOS, RAM principal via BLOAD, ou area de sistema como o hook `&HFFCA`); `subBios<>0` chama via EXTROM (so enderecos ate `&H3FFF`). Devolve o registrador A e as flags Cy/Z ja separadas do par AF de saida (mais convenientes que decompor na mao).

## Entrada
- `p(0)` = 0 direto / <>0 via SUB-BIOS
- `p(1)` = endereco da rotina
- `p(2)` a `p(11)` = registradores de entrada: AF,BC,DE,HL,IX,IY,AF',BC',DE',HL'

## Saida
- `p(2)` a `p(11)` = registradores de saida (mesma ordem)
- `p(12)` = registrador A
- `p(13)` = flag Cy (-1 se ligada)
- `p(14)` = flag Z (-1 se ligada)

### 59 - Executar codigo de maquina guardado num segmento de RAM

**Wrapper Dignified:** `.NB_ExecCodeInSegment`

**Como chamar:**
- `af, bc, de, hl, ix, iy, af2, bc2, de2, hl2, a, cy, z, erro = .NB_ExecCodeInSegment(segmento, endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)`

A rotina precisa estar montada no intervalo `&H8000`-`&HBFFF` (o segmento e trocado pra pagina 2 antes de chamar). Mesmos registradores da funcao 58. Nao suporta segmentos VRAM nem o 255.

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco da rotina
- `p(2)` a `p(11)` = registradores de entrada

## Saida
- `p(2)` a `p(14)` = registradores de saida + A + Cy + Z (igual a funcao 58)

## Erros
-1 = segmento invalido.

### 60 - Imprimir uma string em modo grafico

**Wrapper Dignified:** `.NB_PrintGraphic`

**Como chamar:**
- `erro = .NB_PrintGraphic(texto$)`

So funciona em SCREEN 5 a 11 - equivalente a `PRINT#1,texto$` com `OPEN"GRP:"AS#1` ja feito, mas compativel com TurboBASIC. Fora dessas SCREENs nao faz nada, sem erro. Maximo 80 caracteres; nao pode ter o caractere 0 (`chr$(0)`).

## Entrada
- `f$(0)` = string a imprimir

### 61 - Guardar uma string num segmento

**Wrapper Dignified:** `.NB_StoreString`

**Como chamar:**
- `novoEndereco, erro = .NB_StoreString(texto$, segmento, endereco, incrementar)`

Termina com um byte 0. Maximo 80 caracteres; nao pode ter o caractere 0.

## Entrada
- `f$(0)` = string
- `p(0)` = segmento
- `p(1)` = endereco
- `p(2)` = <>0 avanca `p(1)`

## Saida
- `p(1)` = `p(1)+len(f$(0))+1` se `p(2)<>0`

### 62 - Ler uma string guardada num segmento

**Wrapper Dignified:** `.NB_RestoreString`

**Como chamar:**
- `texto$, novoEndereco, erro = .NB_RestoreString(segmento, endereco, incrementar)`

Le ate achar um byte 0, ou 80 caracteres. Fora do TurboBASIC, um caractere 255 na string vira 34 (aspas) por causa de como o BASIC classico atribui strings.

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco
- `p(2)` = <>0 avanca `p(1)`

## Saida
- `f$(1)` = string lida
- `p(1)` = `p(1)+len(f$(1))+1` se `p(2)<>0`

### 63 - Inicializar o modo piscante da SCREEN 0

**Wrapper Dignified:** `.NB_InitBlink`

**Como chamar:**
- `erro = .NB_InitBlink(corFrente, corFundo, tempoLigado, tempoDesligado)`

Habilita cores e tempos, e limpa a area de VRAM do blink. `tempoLigado`/`tempoDesligado` (0 a 15) ambos 0 so limpa a area, sem mudar cores/tempos. So funciona em SCREEN 0 com pelo menos 41 colunas (senao erro -1, sem fazer nada).

## Entrada
- `p(0)` = cor de frente do texto piscante
- `p(1)` = cor de fundo
- `p(2)` = tempo ligado (0-15)
- `p(3)` = tempo desligado (0-15)

### 64 - Criar ou apagar um bloco piscante

**Wrapper Dignified:** `.NB_SetBlinkBlock`

**Como chamar:**
- `novaColuna, novaLinha, erro = .NB_SetBlinkBlock(criar, coluna, linha, largura, altura, incColuna, incLinha)`

Chame .NB_InitBlink antes. So funciona em SCREEN 0 com pelo menos 41 colunas (nao faz nada, sem erro, fora disso; mas da erro -1 se coluna/linha passarem de 79/27).

## Entrada
- `p(0)` = 0 apaga / <>0 cria
- `p(1)` = coluna inicial (0-79)
- `p(2)` = linha inicial (0-27)
- `p(3)` = largura em colunas
- `p(4)` = altura em linhas
- `p(5)` = <>0 avanca `p(1)`
- `p(6)` = <>0 avanca `p(2)`

## Saida
- `p(1)` = `p(1)+p(3)` se `p(5)<>0`
- `p(2)` = `p(2)+p(4)` se `p(6)<>0`

### 65 - Obter informacoes sobre interrupcoes

**Wrapper Dignified:** `.NB_GetInterruptInfo`

**Como chamar:**
- `algumAtivo, interrupcaoAtiva, sfxTocando, musicaTocando, erro = .NB_GetInterruptInfo()`

## Saida
- `p(0)` = -1 se algum processo de interrupcao esta ativo
- `p(1)` = -1 se a interrupcao do usuario esta ativa
- `p(2)`/`p(3)` = segmento/endereco da interrupcao do usuario (validos mesmo parada)
- `p(4)` = -1 se um efeito PSG esta tocando
- `p(5)` = -1 se uma musica esta tocando

### 66 - Definir ou parar a interrupcao do usuario

**Wrapper Dignified:** `.NB_SetUserInterrupt`

**Como chamar:**
- `erro = .NB_SetUserInterrupt(acao, segmento, endereco)`

A rotina roda a 50/60Hz e precisa estar montada em `&H8000`-`&HBFFF` do segmento indicado.

## Entrada
- `p(0)` = 0 para / 1 define e ativa / -1 inverte o estado atual
- `p(1)` = segmento (ignorado se `p(0)<>1`)
- `p(2)` = endereco (ignorado se `p(0)<>1`)

## Erros
7 = valor invalido em `p(0)`.
-1 = segmento invalido/VRAM/255.

## Efeitos sonoros PSG

Efeitos sonoros criados no editor SEE v3.xx, de Fuzzy Logic (uso comercial tem uma pequena taxa aos autores - ver manual original, apendice 4). Funcoes 67 a 70.

### 67 - Obter informacoes sobre os efeitos PSG

**Wrapper Dignified:** `.NB_GetSfxInfo`

**Como chamar:**
- `tocando, numeroEfeito, volumeMaximoAtual, erro = .NB_GetSfxInfo(volumeMaximo)`

So valido depois de .NB_InitSfxSet. Nunca retorna erro.

## Entrada
- `p(0)` = novo volume maximo (-1 = nao muda; >15 vira 15)

## Saida
- `p(1)` = -1 se algum efeito esta tocando
- `p(2)`/`p(3)` = numero/prioridade do efeito tocando (ou do ultimo tocado)
- `p(4)`/`p(5)` = segmento/endereco do conjunto de efeitos
- `p(6)` = numero do maior efeito definido
- `p(7)` = volume maximo

### 68 - Inicializar um conjunto de efeitos PSG

**Wrapper Dignified:** `.NB_InitSfxSet`

**Como chamar:**
- `erro = .NB_InitSfxSet(segmento, endereco)`

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco

## Erros
8 = formato invalido (nao criado pelo editor SEE v3.xx).
-1 = segmento invalido/VRAM/255.

### 69 - Tocar um efeito sonoro PSG

**Wrapper Dignified:** `.NB_PlaySfx`

**Como chamar:**
- `erro = .NB_PlaySfx(efeito, prioridade)`

Se ja tiver outro efeito tocando: prioridade igual, ou o novo com prioridade alta, o antigo para e o novo toca; o antigo com prioridade alta e o novo baixa, o antigo continua (erro 11).

## Entrada
- `p(0)` = numero do efeito
- `p(1)` = prioridade (0=baixa, <>0=alta)

## Erros
9 = efeito nao definido (trilha OFF no editor).
10 = efeito nao existe (numero maior que o maximo).
11 = outro efeito de prioridade maior ja esta tocando.

### 70 - Parar o efeito sonoro PSG

**Wrapper Dignified:** `.NB_StopSfx`

**Como chamar:**
- `erro = .NB_StopSfx()`

Para o efeito em execucao e silencia o PSG. Nunca retorna erro.

## Tocador Moonblaster

NestorBASIC inclui os tocadores Moonblaster 1.4 e Moonblaster Wave 1.05 (funcoes 71 a 79). O tocador precisa ser carregado explicitamente (nao acontece sozinho ao instalar o NestorBASIC) e ocupa o segmento 5 (so existe se o segmento 5 existir e for do mapper primario).

### 71 - Carregar/inicializar ou desinstalar o tocador (S4)

**Wrapper Dignified:** `.NB_LoadPlayer`

**Como chamar:**
- `tocadorCarregado, arquivoAberto, erro = .NB_LoadPlayer(acao)`

acao 3 (autodetectar) carrega o Wave se achar Moonsound, senao o 1.4. Num Turbo-R, se trocar de processador (Z80/R800) depois de carregado, chame de novo pra carregar a versao certa.

## Entrada
- `p(0)` = 0 Moonblaster 1.4 / 1 Moonblaster Wave 1.05 / 3 autodetectar / -1 desinstalar

## Saida
- `p(0)` = tocador carregado (0, 1 ou -1)
- `p(1)` = -1 se nao deu erro; senao, numero do arquivo NBASIC.BIN (ainda aberto) onde ocorreu o erro de disco - feche com .NB_CloseFile antes de tentar de novo

## Erros
-1 = segmento 5 nao existe ou nao e do mapper primario.

### 72 - Obter informacoes sobre a musica tocando

**Wrapper Dignified:** `.NB_GetMusicInfo`

**Como chamar:**
- `tocando, pausada, nomeMusica$, erro = .NB_GetMusicInfo()`

`p(12)=0` se nenhum tocador foi carregado (os demais resultados, exceto deteccao de chips de som, ficam invalidos nesse caso). `f$(0)`/`f$(1)` so valem se `p(0)<>0`. Nunca retorna erro.

## Saida
- `p(0)` = -1 se uma musica esta tocando ou pausada
- `p(1)`/`p(2)` = -1 se e Moonblaster 1.4 / Moonblaster Wave
- `p(4)` = -1 se pausada
- `p(5)`/`p(6)` = segmento/endereco da musica tocando (ou da ultima tocada)
- `p(7)`/`p(8)` = posicao/passo atual (0-15)
- `p(9)`/`p(10)`/`p(11)` = -1 se detectou MSX-MUSIC/MSX-AUDIO/OPL4
- `p(12)` = -1 se ha um tocador inicializado
- `p(13)` = tocador instalado (0=Moonblaster 1.4, 1=Wave - so vale se `p(12)=-1`)
- `f$(0)` = nome da musica (sempre 40 caracteres na 1.4, 50 na Wave)
- `f$(1)` = samplekit/wavekit carregado quando a musica foi salva (maiusculas, sem extensao; NONE se nao tinha nenhum)

### 73 - Habilitar/desabilitar os chips de som

**Wrapper Dignified:** `.NB_SetSoundChips`

**Como chamar:**
- `statusMsxMusic, statusMsxAudio, statusOpl4, erro = .NB_SetSoundChips(acao, msxMusica, msxAudio, opl4)`

So tem efeito na proxima musica tocada ou apos parar/reiniciar a atual.

## Entrada
- `p(0)` = 0 so consultar / 1 aplicar `p(1)`-`p(3)` / 2 habilitar todos os encontrados
- `p(1)`/`p(2)`/`p(3)` = MSX-MUSIC/MSX-AUDIO/OPL4: 0=nao mexe, 1=desabilita, 2=habilita, -1=inverte

## Saida
- `p(4)`/`p(5)`/`p(6)` = MSX-MUSIC/MSX-AUDIO/OPL4: 0=nao encontrado, 1=encontrado mas desabilitado, 2=habilitado

## Erros
7 = parametro invalido.
12 = tocador nao instalado.

### 74 - Comecar a tocar uma musica Moonblaster

**Wrapper Dignified:** `.NB_PlayMusic`

**Como chamar:**
- `erro = .NB_PlayMusic(segmento, endereco)`

Moonblaster Wave pode ocupar ate 3 segmentos consecutivos.

## Entrada
- `p(0)` = segmento
- `p(1)` = endereco inicial

## Erros
-1 = segmento invalido/VRAM/255.
12 = tocador nao inicializado.
13 = musica salva em modo EDIT (nao da pra tocar), ou sem musica Moonblaster Wave valida no endereco.
14 = ja tem outra musica tocando.

### 75 - Parar a musica

**Wrapper Dignified:** `.NB_StopMusic`

**Como chamar:**
- `erro = .NB_StopMusic()`

Para a musica tocando e silencia os chips de som. Nunca retorna erro (nao faz nada se nao tiver musica tocando/tocador nao inicializado).

### 76 - Pausar/continuar a musica

**Wrapper Dignified:** `.NB_PauseMusic`

**Como chamar:**
- `erro = .NB_PauseMusic(acao)`

## Entrada
- `p(0)` = 0 pausa / 1 continua / -1 inverte o estado atual

## Erros
7 = parametro invalido (nao faz nada, sem erro, se nao tiver musica tocando/pausada ou tocador nao inicializado).

### 77 - Fade-out da musica

**Wrapper Dignified:** `.NB_FadeMusic`

**Como chamar:**
- `fazendoFade, delayAtual, erro = .NB_FadeMusic(delay)`

Delay = ciclos de 1/50 ou 1/60s entre passos do fade - quanto menor, mais rapido. Ao terminar (volume chega a zero), a musica para sozinha. Nunca retorna erro.

## Entrada
- `p(0)` = 0 so consultar / -1 pausa o fade / 1..254 inicia/continua com esse delay

## Saida
- `p(1)` = -1 se esta fazendo fade
- `p(2)` = delay atual (-1 se pausado)

### 78 - Carregar um samplekit Music Module (S4)

**Wrapper Dignified:** `.NB_LoadSamplekit`

**Como chamar:**
- `bytesLidos, erro = .NB_LoadSamplekit(numeroArquivo)`

Formato Moonblaster: 56 bytes de cabecalho + 32K de amostras. Le de um arquivo ja aberto, na posicao atual do ponteiro. Se o retorno vier maior que 16K, so os primeiros 16K foram pra RAM de amostras; 32824 nao cabe em inteiro e volta como -32712 (limite do BASIC). Nao faz nada (sem erro) se o tocador nao foi inicializado ou nao ha Music Module.

## Entrada
- `p(0)` = numero do arquivo (ja aberto)

## Saida
- `p(7)` = numero de bytes lidos

### 79 - Carregar um wavekit Moonsound (S4)

**Wrapper Dignified:** `.NB_LoadWavekit`

**Como chamar:**
- `bytesAlto, bytesBaixo, erro = .NB_LoadWavekit(numeroArquivo)`

Precisa estar salvo em modo USER (senao erro 15). Le de um arquivo ja aberto, na posicao atual do ponteiro. Nao faz nada (sem erro) se o tocador Wave nao foi inicializado ou nao ha Moonsound.

## Entrada
- `p(0)` = numero do arquivo (ja aberto)

## Saida
- `p(6)`/`p(7)` = numero de bytes lidos (32 bits: `p(6)*65536+p(7)`)

## Erros
15 = sem wavekit valido nessa posicao do arquivo, ou nao esta em modo USER.

## Controle de uso de segmentos

Consultar/limitar quantos segmentos o proprio NestorBASIC reserva pra si (funcao 80) - importante quando outros programas residentes (RAM disk do DOS 2, NestorMan, InterNestor Suite) tambem precisam alocar segmentos.

### 80 - Obter/definir o numero de segmentos alocados

**Wrapper Dignified:** `.NB_SetSegmentCount`

**Como chamar:**
- `segmentosAlocados, segmentosMaximo, erro = .NB_SetSegmentCount(numSegmentos)`

Se pedir menos de 6, o NestorBASIC usa 5 mesmo assim (ou 6 se o tocador Moonblaster estiver carregado); se pedir mais que o disponivel, aloca o maximo possivel (ate 247). Funciona no DOS 1 e no DOS 2, mas so faz sentido de verdade no DOS 2 (no DOS 1 so mexe em variaveis internas, sem liberar/reservar nada de fato). Nunca retorna erro.

## Entrada
- `p(0)` = numero de segmentos pedido (0 = so consultar, sem mudar nada)

## Saida
- `p(0)` = numero de segmentos alocados apos a chamada
- `p(1)` = numero maximo de segmentos que podem ser alocados

## NestorMan e InterNestor Suite/Lite

Interacao com o NestorMan (gerenciador dinamico de memoria residente do MSX-DOS 2), InterNestor Suite (pilha TCP/IP do MSX-DOS 2) e InterNestor Lite (pilha TCP/IP do MSX-DOS 1/2), se estiverem instalados (funcoes 81 a 86). Cada um tem manual proprio, disponivel em http://msx.konamiman.com - o NestorBASIC so da o meio de chamar/trocar dados com eles.

### 81 - Informacoes sobre NestorMan/InterNestor Suite

**Wrapper Dignified:** `.NB_GetNestorManInfo`

**Como chamar:**
- `status, segmentoNestorManSeg4, erro = .NB_GetNestorManInfo()`

Nunca retorna erro.

## Saida
- `p(0)` = 0 NestorMan nao instalado / 1 NestorMan instalado / 3 NestorMan e InterNestor Suite instalados
- `p(1)` a `p(4)` = segmento NestorMan de cada modulo do InterNestor Suite 1 a 4 (so validos se `p(0)=3`)
- `p(5)` = segmento NestorMan do segmento 4 do NestorBASIC (usado como buffer intermediario em transferencias - so valido se `p(0)=1` ou `3`)

### 82 - Executar uma funcao do NestorMan

**Wrapper Dignified:** `.NB_CallNestorMan`

**Como chamar:**
- `af, bc, de, hl, ix, iy, af2, bc2, de2, hl2, a, cy, z, erro = .NB_CallNestorMan(funcao, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)`

Chamada indireta via hook estendido da BIOS - equivalente a .NB_ExecCode com endereco `&HFFCA`. Mesmos registradores de entrada/saida de .NB_ExecCode.

## Entrada
- `p(0)` = numero da funcao NestorMan
- `p(2)` a `p(11)` = registradores de entrada (AF,BC,DE,HL,IX,IY,AF',BC',DE',HL')

## Saida
- `p(2)` a `p(14)` = registradores de saida + A + Cy + Z

## Erros
**Atencao:** o manual original se contradiz aqui - a secao de erros gerais diz que as funcoes 80, 81 e 82 nunca retornam erro, mas a descricao desta funcao especifica diz -1 se o NestorMan nao estiver instalado. Teste na pratica se depender disso. De qualquer forma, nao verifica se a funcao pedida realmente existe no NestorMan.

### 83 - Copiar dados do NestorMan pro NestorBASIC

**Wrapper Dignified:** `.NB_CopyFromNestorMan`

**Como chamar:**
- `novoEndOrigem, novoEndDestino, erro = .NB_CopyFromNestorMan(segOrigemNestorMan, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)`

segmento de destino nao pode ser o 1 (TurboBASIC) - copie primeiro pra outro segmento (ex.: o 4) se precisar.

## Entrada
- `p(0)` = segmento de origem (NestorMan)
- `p(1)` = endereco de origem
- `p(2)` = segmento de destino (NestorBASIC)
- `p(3)` = endereco de destino
- `p(4)` = tamanho
- `p(5)` = <>0 avanca origem
- `p(6)` = <>0 avanca destino

## Saida
- `p(1)` = `p(1)+p(4)` se `p(5)<>0`
- `p(3)` = `p(3)+p(4)` se `p(6)<>0`

## Erros
-1 = segmento invalido.

### 84 - Copiar dados do NestorBASIC pro NestorMan

**Wrapper Dignified:** `.NB_CopyToNestorMan`

**Como chamar:**
- `novoEndOrigem, novoEndDestino, erro = .NB_CopyToNestorMan(segOrigem, endOrigem, segDestinoNestorMan, endDestino, tamanho, incOrigem, incDestino)`

segmento de origem nao pode ser o 1 (TurboBASIC).

## Entrada
- `p(0)` = segmento de origem (NestorBASIC)
- `p(1)` = endereco de origem
- `p(2)` = segmento de destino (NestorMan)
- `p(3)` = endereco de destino
- `p(4)` = tamanho
- `p(5)` = <>0 avanca origem
- `p(6)` = <>0 avanca destino

## Saida
- `p(1)` = `p(1)+p(4)` se `p(5)<>0`
- `p(3)` = `p(3)+p(4)` se `p(6)<>0`

## Erros
-1 = segmento invalido.

### 85 - Executar uma rotina do InterNestor Suite

**Wrapper Dignified:** `.NB_CallInterNestorSuite`

**Como chamar:**
- `af, bc, de, hl, ix, iy, af2, bc2, de2, hl2, a, cy, z, erro = .NB_CallInterNestorSuite(modulo, endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)`

Pra ler/escrever as constantes/variaveis de configuracao dos modulos, use .NB_GetNestorManInfo (segmento NestorMan de cada modulo) e depois .NB_CopyFromNestorMan/.NB_CopyToNestorMan. Mesmos registradores de .NB_ExecCode.

## Entrada
- `p(0)` = numero do modulo (1 a 4)
- `p(1)` = endereco da rotina
- `p(2)` a `p(11)` = registradores de entrada

## Saida
- `p(2)` a `p(14)` = registradores de saida + A + Cy + Z

## Erros
-1 = InterNestor Suite nao instalado, ou numero de modulo invalido.

### 86 - Executar uma rotina do InterNestor Lite

**Wrapper Dignified:** `.NB_CallInterNestorLite`

**Como chamar:**
- `af, bc, de, hl, ix, iy, af2, bc2, de2, hl2, a, cy, z, erro = .NB_CallInterNestorLite(endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)`

So existe uma instancia (sem selecao de modulo). Pra checar se esta instalado sem chamar essa rotina: `p(0)=0:p(1)=&Hffca:p(2)=0:p(4)=&H2203:e=usr(58):if p(12)=0 then` (nao instalado) - equivalente a usar .NB_ExecCode direto e olhar o registrador A devolvido. Mesmos registradores de .NB_ExecCode.

## Entrada
- `p(1)` = endereco da rotina (ver o manual do InterNestor Lite pra lista)
- `p(2)` a `p(11)` = registradores de entrada

## Saida
- `p(2)` a `p(14)` = registradores de saida + A + Cy + Z

## Erros
-1 = InterNestor Lite nao instalado.

