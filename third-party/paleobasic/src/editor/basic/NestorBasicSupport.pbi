;
; ------------------------------------------------------------
;  Arquivo -> Novo Nestor Basic...: gera o texto inicial (template) de um
;  programa Basic Dignified com suporte ao NestorBASIC 1.11 (by Nestor
;  Soriano / Konami Man) - rotinas em codigo de maquina, carregadas uma vez
;  com BLOAD"NBASIC.BIN",R, que dao acesso a memoria mapeada, VRAM, disco,
;  compressao grafica, tocador Moonblaster, efeitos PSG etc., tudo atraves
;  de um unico USR(numero) e dos arrays P() e F$(). Ver
;  nestor/SRC/NBASIC/nbas111e.txt (manual original) para a lista completa
;  de funcoes.
;
;  NestorBasicLibraryText() cobre a "Tier 1" combinada com o usuario:
;  funcoes gerais (0-1), acesso a segmentos RAM (2-12), acesso a VRAM
;  (13-25) e acesso a disco (26-52) - wrappers .NB_* nomeados, ao inves de
;  numero de funcao/USR() cru. NestorBasicLibraryTier2Text() cobre a
;  "Tier 2": compressao/descompressao grafica (53-54), execucao de
;  programas BASIC guardados em RAM (55-57), execucao de codigo de
;  maquina/rotinas diversas (58-66), efeitos PSG (67-70) e tocador
;  Moonblaster (71-79). NestorBasicLibraryTier3Text() cobre a "Tier 3":
;  controle de quantos segmentos o NestorBASIC aloca pra si (80) e
;  interacao com NestorMan/InterNestor Suite/Lite (81-86) - wrappers
;  completos tambem (acabou nao precisando ficar so em constantes como o
;  plano original previa).
;
;  Decisao de entrega (confirmada com o usuario): o texto inteiro (loader +
;  biblioteca) e colado direto em cada "Novo Nestor Basic" - sem INCLUDE
;  separado, ja que INCLUDE aqui so resolve caminho relativo ao arquivo
;  salvo (ou absoluto; ver Dig_ResolveIncludePath em DignifiedPreprocessor.pbi)
;  e uma aba nova ainda sem salvar (Path="") nao teria de onde puxar um
;  "nestorbasic.dmx" externo.
;
;  IMPORTANTE: o carregador do NBASIC.BIN (dentro de NestorBasicTemplateText,
;  rotulos {NBasicLoad}/{VoltaNBasicLoad}) usa GOTO, nunca func/ret - achado
;  do usuario: BLOAD"NBASIC.BIN",R mexe na pilha do BASIC, entao um
;  GOSUB/RETURN em volta dessa chamada especifica quebra (RETURN sem saber
;  pra onde voltar). Os wrappers .NB_* de NestorBasicLibraryText() usam
;  usr() puro (sem BLOAD), esses continuam seguros com func/ret normal.
; ------------------------------------------------------------
;

; Corpo dos wrappers .NB_* (Tier 1: geral, RAM, VRAM, disco) + o tradutor de
; codigo de erro .NB_ErrorText - tudo com func/ret (unico jeito de devolver
; valor pro chamador em Basic Dignified). Convencao: cada .NB_* devolve so
; o(s) valor(es) "principal(is)" da chamada, sempre com o codigo de erro por
; ultimo; os demais resultados documentados no manual continuam disponiveis
; direto em p()/f$() logo apos a chamada (sao os mesmos arrays globais que o
; NestorBASIC usa, o wrapper nao faz copia - por isso "menos retornos que a
; definicao" nunca perde informacao, so preferencia por brevidade no uso
; comum). (S4) = a funcao usa o segmento 4 (buffer interno do NestorBASIC).
Procedure.s NestorBasicLibraryText()
  Protected Text.s = ""

  Text + "' --- Biblioteca NestorBASIC (Tier 1: geral, RAM, VRAM, disco) ---" + #CRLF$
  Text + "' Convencao: cada .NB_* devolve so o(s) valor(es) principal(is) da" + #CRLF$
  Text + "' chamada, sempre com o codigo de erro por ultimo (0 = sem erro; use" + #CRLF$
  Text + "' .NB_ErrorText(codigo) pra mensagem). Os demais resultados documentados" + #CRLF$
  Text + "' no manual continuam em p()/f$() logo apos a chamada." + #CRLF$
  Text + #CRLF$

  ; --- 10.2 Funcoes gerais ---
  Text + "' --- 10.2 Funcoes gerais ---" + #CRLF$
  Text + #CRLF$
  Text + "' Desinstala o NestorBASIC. liberarRam<>0 libera tambem a RAM ocupada" + #CRLF$
  Text + "' pela rotina de salto (~500 bytes), voltando FRE(0) ao valor de antes" + #CRLF$
  Text + "' de instalar. (S4)" + #CRLF$
  Text + "func .NB_Uninstall(liberarRam)" + #CRLF$
  Text + "  p(0) = liberarRam" + #CRLF$
  Text + "  erro = usr(0)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Informacoes gerais sobre o NestorBASIC e sobre o segmento indicado." + #CRLF$
  Text + "' Devolve o numero de segmentos de RAM disponiveis; outros resultados" + #CRLF$
  Text + "' (versao, DOS, VRAM em K, arquivos abertos, slot/segmento fisico," + #CRLF$
  Text + "' caminho do NBASIC.BIN em f$(0) etc. - ver secao 10.2 do manual)" + #CRLF$
  Text + "' continuam em p()/f$()." + #CRLF$
  Text + "func .NB_GetInfo(segmento)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  erro = usr(1)" + #CRLF$
  Text + "ret p(0), erro" + #CRLF$
  Text + #CRLF$

  ; --- 10.3 Acesso a segmentos (RAM) ---
  Text + "' --- 10.3 Acesso a segmentos (RAM) ---" + #CRLF$
  Text + #CRLF$
  Text + "' Le um byte do segmento/endereco indicado." + #CRLF$
  Text + "func .NB_ReadByte(segmento, endereco)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(2)" + #CRLF$
  Text + "ret p(2), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le um byte e devolve o endereco seguinte (pra percorrer sequencialmente:" + #CRLF$
  Text + "' byte, endereco = .NB_ReadByteInc(segmento, endereco))." + #CRLF$
  Text + "func .NB_ReadByteInc(segmento, endereco)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(3)" + #CRLF$
  Text + "ret p(2), p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le um inteiro (2 bytes, low+high) do segmento/endereco indicado." + #CRLF$
  Text + "func .NB_ReadInt(segmento, endereco)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(4)" + #CRLF$
  Text + "ret p(2), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le um inteiro e devolve o endereco seguinte." + #CRLF$
  Text + "func .NB_ReadIntInc(segmento, endereco)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(5)" + #CRLF$
  Text + "ret p(2), p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve um byte no segmento/endereco indicado." + #CRLF$
  Text + "func .NB_WriteByte(segmento, endereco, valor)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = valor" + #CRLF$
  Text + "  erro = usr(6)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve um byte e devolve o endereco seguinte." + #CRLF$
  Text + "func .NB_WriteByteInc(segmento, endereco, valor)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = valor" + #CRLF$
  Text + "  erro = usr(7)" + #CRLF$
  Text + "ret p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve um inteiro (2 bytes) no segmento/endereco indicado." + #CRLF$
  Text + "func .NB_WriteInt(segmento, endereco, valor)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = valor" + #CRLF$
  Text + "  erro = usr(8)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve um inteiro e devolve o endereco seguinte." + #CRLF$
  Text + "func .NB_WriteIntInc(segmento, endereco, valor)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = valor" + #CRLF$
  Text + "  erro = usr(9)" + #CRLF$
  Text + "ret p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Copia um bloco de dados entre dois segmentos. incOrigem/incDestino<>0" + #CRLF$
  Text + "' avancam o endereco de origem/destino correspondente (util em loop)." + #CRLF$
  Text + "func .NB_CopySegToSeg(segOrigem, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)" + #CRLF$
  Text + "  p(0) = segOrigem" + #CRLF$
  Text + "  p(1) = endOrigem" + #CRLF$
  Text + "  p(2) = segDestino" + #CRLF$
  Text + "  p(3) = endDestino" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(5) = incOrigem" + #CRLF$
  Text + "  p(6) = incDestino" + #CRLF$
  Text + "  erro = usr(10)" + #CRLF$
  Text + "ret p(1), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Preenche uma area de um segmento com um byte fixo." + #CRLF$
  Text + "func .NB_FillRam(segmento, endereco, byte, tamanho)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = byte" + #CRLF$
  Text + "  p(3) = tamanho" + #CRLF$
  Text + "  erro = usr(11)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Preenche uma area de um segmento com um byte fixo e devolve o" + #CRLF$
  Text + "' endereco seguinte a area preenchida." + #CRLF$
  Text + "func .NB_FillRamInc(segmento, endereco, byte, tamanho)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = byte" + #CRLF$
  Text + "  p(3) = tamanho" + #CRLF$
  Text + "  erro = usr(12)" + #CRLF$
  Text + "ret p(1), erro" + #CRLF$
  Text + #CRLF$

  ; --- 10.4 Acesso a VRAM ---
  Text + "' --- 10.4 Acesso a VRAM ---" + #CRLF$
  Text + "' bloco = 0 (64K VRAM baixa) ou 1 (64K VRAM alta, so em maquinas com" + #CRLF$
  Text + "' 128K) - endereco 0-&HFFFF; se um autoincremento passar de &HFFFF," + #CRLF$
  Text + "' o endereco volta a 0 e o bloco se inverte (0<->1)." + #CRLF$
  Text + #CRLF$
  Text + "' Le um byte da VRAM." + #CRLF$
  Text + "func .NB_VReadByte(bloco, endereco)" + #CRLF$
  Text + "  p(0) = bloco" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(13)" + #CRLF$
  Text + "ret p(2), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le um byte da VRAM e devolve bloco/endereco seguintes." + #CRLF$
  Text + "func .NB_VReadByteInc(bloco, endereco)" + #CRLF$
  Text + "  p(0) = bloco" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(14)" + #CRLF$
  Text + "ret p(2), p(0), p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le um inteiro (2 bytes) da VRAM." + #CRLF$
  Text + "func .NB_VReadInt(bloco, endereco)" + #CRLF$
  Text + "  p(0) = bloco" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(15)" + #CRLF$
  Text + "ret p(2), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le um inteiro da VRAM e devolve bloco/endereco seguintes." + #CRLF$
  Text + "func .NB_VReadIntInc(bloco, endereco)" + #CRLF$
  Text + "  p(0) = bloco" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(16)" + #CRLF$
  Text + "ret p(2), p(0), p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve um byte na VRAM." + #CRLF$
  Text + "func .NB_VWriteByte(bloco, endereco, valor)" + #CRLF$
  Text + "  p(0) = bloco" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = valor" + #CRLF$
  Text + "  erro = usr(17)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve um byte na VRAM e devolve bloco/endereco seguintes." + #CRLF$
  Text + "func .NB_VWriteByteInc(bloco, endereco, valor)" + #CRLF$
  Text + "  p(0) = bloco" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = valor" + #CRLF$
  Text + "  erro = usr(18)" + #CRLF$
  Text + "ret p(0), p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve um inteiro (2 bytes) na VRAM." + #CRLF$
  Text + "func .NB_VWriteInt(bloco, endereco, valor)" + #CRLF$
  Text + "  p(0) = bloco" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = valor" + #CRLF$
  Text + "  erro = usr(19)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve um inteiro na VRAM e devolve bloco/endereco seguintes." + #CRLF$
  Text + "func .NB_VWriteIntInc(bloco, endereco, valor)" + #CRLF$
  Text + "  p(0) = bloco" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = valor" + #CRLF$
  Text + "  erro = usr(20)" + #CRLF$
  Text + "ret p(0), p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Copia um bloco de dados da VRAM pra um segmento de RAM." + #CRLF$
  Text + "func .NB_CopyVramToRam(blocoOrigem, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)" + #CRLF$
  Text + "  p(0) = blocoOrigem" + #CRLF$
  Text + "  p(1) = endOrigem" + #CRLF$
  Text + "  p(2) = segDestino" + #CRLF$
  Text + "  p(3) = endDestino" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(5) = incOrigem" + #CRLF$
  Text + "  p(6) = incDestino" + #CRLF$
  Text + "  erro = usr(21)" + #CRLF$
  Text + "ret p(0), p(1), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Copia um bloco de dados de um segmento de RAM pra VRAM." + #CRLF$
  Text + "func .NB_CopyRamToVram(segOrigem, endOrigem, blocoDestino, endDestino, tamanho, incOrigem, incDestino)" + #CRLF$
  Text + "  p(0) = segOrigem" + #CRLF$
  Text + "  p(1) = endOrigem" + #CRLF$
  Text + "  p(2) = blocoDestino" + #CRLF$
  Text + "  p(3) = endDestino" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(5) = incOrigem" + #CRLF$
  Text + "  p(6) = incDestino" + #CRLF$
  Text + "  erro = usr(22)" + #CRLF$
  Text + "ret p(1), p(2), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Copia um bloco de dados entre duas areas da VRAM (maximo &H4000" + #CRLF$
  Text + "' bytes por chamada - pra blocos maiores repita a chamada, ver secao" + #CRLF$
  Text + "' 10.4 do manual)." + #CRLF$
  Text + "func .NB_CopyVramToVram(blocoOrigem, endOrigem, blocoDestino, endDestino, tamanho, incOrigem, incDestino)" + #CRLF$
  Text + "  p(0) = blocoOrigem" + #CRLF$
  Text + "  p(1) = endOrigem" + #CRLF$
  Text + "  p(2) = blocoDestino" + #CRLF$
  Text + "  p(3) = endDestino" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(5) = incOrigem" + #CRLF$
  Text + "  p(6) = incDestino" + #CRLF$
  Text + "  erro = usr(23)" + #CRLF$
  Text + "ret p(0), p(1), p(2), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Preenche uma area da VRAM com um byte fixo (maximo 16K por chamada)." + #CRLF$
  Text + "func .NB_FillVram(bloco, endereco, byte, tamanho)" + #CRLF$
  Text + "  p(0) = bloco" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = byte" + #CRLF$
  Text + "  p(3) = tamanho" + #CRLF$
  Text + "  erro = usr(24)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Preenche uma area da VRAM com um byte fixo e devolve bloco/endereco" + #CRLF$
  Text + "' seguintes (maximo 16K por chamada)." + #CRLF$
  Text + "func .NB_FillVramInc(bloco, endereco, byte, tamanho)" + #CRLF$
  Text + "  p(0) = bloco" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = byte" + #CRLF$
  Text + "  p(3) = tamanho" + #CRLF$
  Text + "  erro = usr(25)" + #CRLF$
  Text + "ret p(0), p(1), erro" + #CRLF$
  Text + #CRLF$

  ; --- 10.5 Acesso a disco ---
  Text + "' --- 10.5 Acesso a disco ---" + #CRLF$
  Text + "' atributos: R+2*H+4*S+8*V+16*D+32*A (Somente leitura+Oculto+Sistema+" + #CRLF$
  Text + "' Volume+Diretorio+Arquivo). unidade normalmente 0=A:,1=B:,...,7=H: -" + #CRLF$
  Text + "' EXCETO em .NB_GetDiskSpace e .NB_GetDir, onde e 0=unidade padrao," + #CRLF$
  Text + "' 1=A:,...,8=H: (assim mesmo no manual original, secao 10.5)." + #CRLF$
  Text + #CRLF$
  Text + "' Procura o primeiro arquivo (buscarProximo=0) ou o proximo" + #CRLF$
  Text + "' (buscarProximo=1) que bate com a mascara (vazia = " + Chr(34) + "*.*" + Chr(34) + "). f$(0)" + #CRLF$
  Text + "' devolve so o nome encontrado; hora/data/cluster/unidade/tamanho/" + #CRLF$
  Text + "' contador ficam em p(2) a p(11) - ver secao 10.5 do manual. (S4)" + #CRLF$
  Text + "func .NB_FindFile(mascara$, buscarProximo, atributosBusca)" + #CRLF$
  Text + "  f$(1) = mascara$" + #CRLF$
  Text + "  p(0) = buscarProximo" + #CRLF$
  Text + "  p(1) = atributosBusca" + #CRLF$
  Text + "  erro = usr(26)" + #CRLF$
  Text + "ret f$(0), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Renomeia um arquivo. (S4)" + #CRLF$
  Text + "func .NB_RenameFile(nome$, novoNome$)" + #CRLF$
  Text + "  f$(0) = nome$" + #CRLF$
  Text + "  f$(1) = novoNome$" + #CRLF$
  Text + "  erro = usr(27)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Apaga um arquivo. (S4)" + #CRLF$
  Text + "func .NB_DeleteFile(nome$)" + #CRLF$
  Text + "  f$(0) = nome$" + #CRLF$
  Text + "  erro = usr(28)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Move um arquivo/diretorio pra outro local (so DOS 2; novoLocal$ nao" + #CRLF$
  Text + "' pode ter nome de arquivo nem letra de unidade, so o caminho novo)." + #CRLF$
  Text + "func .NB_MoveFile(nome$, novoLocal$)" + #CRLF$
  Text + "  f$(0) = nome$" + #CRLF$
  Text + "  f$(1) = novoLocal$" + #CRLF$
  Text + "  erro = usr(29)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Cria um arquivo vazio ou subdiretorio." + #CRLF$
  Text + "func .NB_CreateFile(nome$, atributos)" + #CRLF$
  Text + "  f$(0) = nome$" + #CRLF$
  Text + "  p(0) = atributos" + #CRLF$
  Text + "  erro = usr(30)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Abre um arquivo e devolve o numero atribuido a ele." + #CRLF$
  Text + "func .NB_OpenFile(nome$)" + #CRLF$
  Text + "  f$(0) = nome$" + #CRLF$
  Text + "  erro = usr(31)" + #CRLF$
  Text + "ret p(0), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Fecha um arquivo aberto - sempre feche arquivos que nao vai mais usar." + #CRLF$
  Text + "func .NB_CloseFile(numeroArquivo)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  erro = usr(32)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le do arquivo (a partir da posicao atual do ponteiro) pra um segmento" + #CRLF$
  Text + "' de RAM. incrementar<>0 avanca enderecoDestino pelo numero de bytes" + #CRLF$
  Text + "' lidos. (S4)" + #CRLF$
  Text + "func .NB_ReadFile(numeroArquivo, segDestino, enderecoDestino, tamanho, incrementar)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  p(2) = segDestino" + #CRLF$
  Text + "  p(3) = enderecoDestino" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(6) = incrementar" + #CRLF$
  Text + "  erro = usr(33)" + #CRLF$
  Text + "ret p(7), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le do arquivo pra VRAM (maximo &H4000 bytes por chamada). (S4)" + #CRLF$
  Text + "func .NB_ReadFileToVram(numeroArquivo, blocoDestino, enderecoDestino, tamanho, incrementar)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  p(2) = blocoDestino" + #CRLF$
  Text + "  p(3) = enderecoDestino" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(6) = incrementar" + #CRLF$
  Text + "  erro = usr(34)" + #CRLF$
  Text + "ret p(7), p(2), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le setores do disco (bruto, sem passar por arquivo) pra um segmento" + #CRLF$
  Text + "' de RAM (maximo 32 setores = 16K por chamada). (S4)" + #CRLF$
  Text + "func .NB_ReadSectors(unidade, primeiroSetor, segDestino, enderecoDestino, numSetores, incrementar)" + #CRLF$
  Text + "  p(0) = unidade" + #CRLF$
  Text + "  p(1) = primeiroSetor" + #CRLF$
  Text + "  p(2) = segDestino" + #CRLF$
  Text + "  p(3) = enderecoDestino" + #CRLF$
  Text + "  p(4) = numSetores" + #CRLF$
  Text + "  p(6) = incrementar" + #CRLF$
  Text + "  erro = usr(35)" + #CRLF$
  Text + "ret p(7), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le setores do disco (bruto) pra VRAM (maximo 32 setores = 16K por" + #CRLF$
  Text + "' chamada). (S4)" + #CRLF$
  Text + "func .NB_ReadSectorsToVram(unidade, primeiroSetor, blocoDestino, enderecoDestino, numSetores, incrementar)" + #CRLF$
  Text + "  p(0) = unidade" + #CRLF$
  Text + "  p(1) = primeiroSetor" + #CRLF$
  Text + "  p(2) = blocoDestino" + #CRLF$
  Text + "  p(3) = enderecoDestino" + #CRLF$
  Text + "  p(4) = numSetores" + #CRLF$
  Text + "  p(6) = incrementar" + #CRLF$
  Text + "  erro = usr(36)" + #CRLF$
  Text + "ret p(7), p(2), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve no arquivo (a partir da posicao atual do ponteiro) a partir" + #CRLF$
  Text + "' de um segmento de RAM. (S4)" + #CRLF$
  Text + "func .NB_WriteFile(numeroArquivo, segOrigem, enderecoOrigem, tamanho, incrementar)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  p(2) = segOrigem" + #CRLF$
  Text + "  p(3) = enderecoOrigem" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(6) = incrementar" + #CRLF$
  Text + "  erro = usr(37)" + #CRLF$
  Text + "ret p(7), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve no arquivo a partir da VRAM (maximo &H4000 bytes por" + #CRLF$
  Text + "' chamada). (S4)" + #CRLF$
  Text + "func .NB_WriteFileFromVram(numeroArquivo, blocoOrigem, enderecoOrigem, tamanho, incrementar)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  p(2) = blocoOrigem" + #CRLF$
  Text + "  p(3) = enderecoOrigem" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(6) = incrementar" + #CRLF$
  Text + "  erro = usr(38)" + #CRLF$
  Text + "ret p(7), p(2), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve setores do disco (bruto) a partir de um segmento de RAM" + #CRLF$
  Text + "' (maximo 32 setores = 16K por chamada). (S4)" + #CRLF$
  Text + "func .NB_WriteSectors(unidade, primeiroSetor, segOrigem, enderecoOrigem, numSetores, incrementar)" + #CRLF$
  Text + "  p(0) = unidade" + #CRLF$
  Text + "  p(1) = primeiroSetor" + #CRLF$
  Text + "  p(2) = segOrigem" + #CRLF$
  Text + "  p(3) = enderecoOrigem" + #CRLF$
  Text + "  p(4) = numSetores" + #CRLF$
  Text + "  p(6) = incrementar" + #CRLF$
  Text + "  erro = usr(39)" + #CRLF$
  Text + "ret p(7), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Escreve setores do disco (bruto) a partir da VRAM (maximo 32" + #CRLF$
  Text + "' setores = 16K por chamada). (S4)" + #CRLF$
  Text + "func .NB_WriteSectorsFromVram(unidade, primeiroSetor, blocoOrigem, enderecoOrigem, numSetores, incrementar)" + #CRLF$
  Text + "  p(0) = unidade" + #CRLF$
  Text + "  p(1) = primeiroSetor" + #CRLF$
  Text + "  p(2) = blocoOrigem" + #CRLF$
  Text + "  p(3) = enderecoOrigem" + #CRLF$
  Text + "  p(4) = numSetores" + #CRLF$
  Text + "  p(6) = incrementar" + #CRLF$
  Text + "  erro = usr(40)" + #CRLF$
  Text + "ret p(7), p(2), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Preenche um arquivo inteiro com um byte fixo (maximo &H4000 por" + #CRLF$
  Text + "' chamada). (S4)" + #CRLF$
  Text + "func .NB_FillFile(numeroArquivo, byte, tamanho)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  p(1) = byte" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  erro = usr(41)" + #CRLF$
  Text + "ret p(7), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Move o ponteiro do arquivo. metodo: 0=a partir do inicio, 1=a partir" + #CRLF$
  Text + "' da posicao atual, 2=a partir do fim. offsetBaixo/offsetAlto: deslocamento" + #CRLF$
  Text + "' com sinal, dividido em 2 partes de 16 bits (formula na secao 10.5 do" + #CRLF$
  Text + "' manual pra deslocamentos fora de -32768..32767). Pra saber a posicao" + #CRLF$
  Text + "' atual sem mover: metodo=1, offsetBaixo=0, offsetAlto=0." + #CRLF$
  Text + "func .NB_SeekFile(numeroArquivo, metodo, offsetBaixo, offsetAlto)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  p(1) = metodo" + #CRLF$
  Text + "  p(2) = offsetBaixo" + #CRLF$
  Text + "  p(3) = offsetAlto" + #CRLF$
  Text + "  erro = usr(42)" + #CRLF$
  Text + "ret p(4), p(5), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Devolve a unidade padrao e o vetor de unidades disponiveis (bit N = 1" + #CRLF$
  Text + "' se a unidade N existe, bit 0 = A:)." + #CRLF$
  Text + "func .NB_GetDrives()" + #CRLF$
  Text + "  erro = usr(43)" + #CRLF$
  Text + "ret p(0), p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Define a unidade padrao." + #CRLF$
  Text + "func .NB_SetDrive(unidade)" + #CRLF$
  Text + "  p(0) = unidade" + #CRLF$
  Text + "  erro = usr(44)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Informacoes de espaco em disco (unidade: 0=padrao,1=A:,...,8=H:," + #CRLF$
  Text + "' ver nota no topo da secao). Espaco livre em bytes = setoresPorCluster" + #CRLF$
  Text + "' * clustersLivres * 512." + #CRLF$
  Text + "func .NB_GetDiskSpace(unidade)" + #CRLF$
  Text + "  p(0) = unidade" + #CRLF$
  Text + "  erro = usr(45)" + #CRLF$
  Text + "ret p(1), p(2), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Devolve o diretorio padrao (so DOS 2; unidade: 0=padrao,1=A:,...,8=H:," + #CRLF$
  Text + "' ver nota no topo da secao). Sem letra de unidade nem barras nas pontas -" + #CRLF$
  Text + "' raiz = string vazia." + #CRLF$
  Text + "func .NB_GetDir(unidade)" + #CRLF$
  Text + "  p(0) = unidade" + #CRLF$
  Text + "  erro = usr(46)" + #CRLF$
  Text + "ret f$(0), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Define o diretorio padrao (so DOS 2; nao muda a unidade padrao, use" + #CRLF$
  Text + "' .NB_SetDrive pra isso)." + #CRLF$
  Text + "func .NB_SetDir(caminho$)" + #CRLF$
  Text + "  f$(0) = caminho$" + #CRLF$
  Text + "  erro = usr(47)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Devolve o tamanho do RAM disk em segmentos de 16K (0 = nao existe;" + #CRLF$
  Text + "' so DOS 2). Tamanho em K = resultado*16." + #CRLF$
  Text + "func .NB_GetRamDiskSize()" + #CRLF$
  Text + "  erro = usr(48)" + #CRLF$
  Text + "ret p(0), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Cria o RAM disk com o tamanho pedido, em segmentos de 16K (so DOS 2;" + #CRLF$
  Text + "' o NestorBASIC toma pra si todos os segmentos livres ao instalar - ver" + #CRLF$
  Text + "' funcao 80 do manual pra liberar segmentos antes de criar o RAM disk)." + #CRLF$
  Text + "' Devolve o tamanho realmente criado (pode ser menor que o pedido)." + #CRLF$
  Text + "func .NB_CreateRamDisk(tamanho16k)" + #CRLF$
  Text + "  p(0) = tamanho16k" + #CRLF$
  Text + "  erro = usr(49)" + #CRLF$
  Text + "ret p(0), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Devolve os atributos de um arquivo ja aberto (so DOS 2)." + #CRLF$
  Text + "func .NB_GetAttrByHandle(numeroArquivo)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  erro = usr(50)" + #CRLF$
  Text + "ret p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Devolve os atributos de um arquivo pelo nome, sem precisar abri-lo" + #CRLF$
  Text + "' (so DOS 2)." + #CRLF$
  Text + "func .NB_GetAttrByName(nome$)" + #CRLF$
  Text + "  p(0) = 255" + #CRLF$
  Text + "  f$(0) = nome$" + #CRLF$
  Text + "  erro = usr(50)" + #CRLF$
  Text + "ret p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Define os atributos de um arquivo ja aberto (so DOS 2; nao da pra" + #CRLF$
  Text + "' mudar atributo de arquivo aberto pelo nome, por isso o numero aqui)." + #CRLF$
  Text + "func .NB_SetAttrByHandle(numeroArquivo, atributos)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  p(1) = atributos" + #CRLF$
  Text + "  erro = usr(51)" + #CRLF$
  Text + "ret p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Define os atributos de um arquivo pelo nome, sem precisar abri-lo" + #CRLF$
  Text + "' (so DOS 2; nao pode ser um arquivo ja aberto)." + #CRLF$
  Text + "func .NB_SetAttrByName(nome$, atributos)" + #CRLF$
  Text + "  p(0) = 255" + #CRLF$
  Text + "  f$(0) = nome$" + #CRLF$
  Text + "  p(1) = atributos" + #CRLF$
  Text + "  erro = usr(51)" + #CRLF$
  Text + "ret p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Interpreta um caminho (so DOS 2, nao acessa o disco): devolve o" + #CRLF$
  Text + "' ultimo item (arquivo/diretorio) do caminho e a unidade logica; os" + #CRLF$
  Text + "' demais resultados (contem diretorio/unidade/nome/extensao, item" + #CRLF$
  Text + "' ambiguo, se e " + Chr(34) + "." + Chr(34) + " ou " + Chr(34) + ".." + Chr(34) + " etc., todos -1/0) ficam em p(0) a p(7)." + #CRLF$
  Text + "func .NB_ParsePath(caminho$, ehVolume)" + #CRLF$
  Text + "  f$(0) = caminho$" + #CRLF$
  Text + "  p(10) = ehVolume" + #CRLF$
  Text + "  erro = usr(52)" + #CRLF$
  Text + "ret f$(1), p(8), erro" + #CRLF$
  Text + #CRLF$

  ; --- Tradutor de codigo de erro ---
  Text + "' Traduz um codigo de erro (devolvido por usr()/pelos .NB_* acima) pra" + #CRLF$
  Text + "' uma mensagem. Cobre o erro generico -1, os erros de disco (secao 4 do" + #CRLF$
  Text + "' manual) e os erros especificos de compressao grafica/codigo de" + #CRLF$
  Text + "' maquina/PSG/Moonblaster (Tier 2)." + #CRLF$
  Text + "func .NB_ErrorText(codigo)" + #CRLF$
  Text + "  msg$ = " + Chr(34) + "Erro desconhecido" + Chr(34) + #CRLF$
  Text + "  if codigo = 0 then msg$ = " + Chr(34) + "Sem erro" + Chr(34) + #CRLF$
  Text + "  if codigo = -2 then msg$ = " + Chr(34) + "RAM principal do BASIC insuficiente pro novo programa" + Chr(34) + #CRLF$
  Text + "  if codigo = -1 then msg$ = " + Chr(34) + "Segmento ou endereco VRAM invalido" + Chr(34) + #CRLF$
  Text + "  if codigo = 1 then msg$ = " + Chr(34) + "Erro geral de disco (DOS 1)" + Chr(34) + #CRLF$
  Text + "  if codigo = 2 then msg$ = " + Chr(34) + "Numero de arquivo invalido" + Chr(34) + #CRLF$
  Text + "  if codigo = 3 then msg$ = " + Chr(34) + "Excesso de arquivos abertos (DOS 1)" + Chr(34) + #CRLF$
  Text + "  if codigo = 5 then msg$ = " + Chr(34) + "Erro ao comprimir: segmentos esgotados antes de terminar" + Chr(34) + #CRLF$
  Text + "  if codigo = 6 then msg$ = " + Chr(34) + "Erro ao descomprimir: dado invalido ou segmentos esgotados" + Chr(34) + #CRLF$
  Text + "  if codigo = 7 then msg$ = " + Chr(34) + "Parametro invalido" + Chr(34) + #CRLF$
  Text + "  if codigo = 8 then msg$ = " + Chr(34) + "Formato de efeitos sonoros invalido" + Chr(34) + #CRLF$
  Text + "  if codigo = 9 then msg$ = " + Chr(34) + "Efeito sonoro nao definido" + Chr(34) + #CRLF$
  Text + "  if codigo = 10 then msg$ = " + Chr(34) + "Efeito sonoro nao existe" + Chr(34) + #CRLF$
  Text + "  if codigo = 11 then msg$ = " + Chr(34) + "Outro efeito de prioridade maior ja esta tocando" + Chr(34) + #CRLF$
  Text + "  if codigo = 12 then msg$ = " + Chr(34) + "Tocador nao instalado/inicializado" + Chr(34) + #CRLF$
  Text + "  if codigo = 13 then msg$ = " + Chr(34) + "Musica salva em modo EDIT, ou sem musica valida no endereco" + Chr(34) + #CRLF$
  Text + "  if codigo = 14 then msg$ = " + Chr(34) + "Outra musica ja esta tocando" + Chr(34) + #CRLF$
  Text + "  if codigo = 15 then msg$ = " + Chr(34) + "Sem wavekit valido nessa posicao do arquivo, ou nao esta em modo USER" + Chr(34) + #CRLF$
  Text + "  if codigo = 60 then msg$ = " + Chr(34) + "FAT invalida" + Chr(34) + #CRLF$
  Text + "  if codigo = 62 then msg$ = " + Chr(34) + "Unidade invalida" + Chr(34) + #CRLF$
  Text + "  if codigo = 68 then msg$ = " + Chr(34) + "Disco protegido contra gravacao" + Chr(34) + #CRLF$
  Text + "  if codigo = 69 then msg$ = " + Chr(34) + "Erro fisico de disco" + Chr(34) + #CRLF$
  Text + "  if codigo = 70 then msg$ = " + Chr(34) + "Disco offline" + Chr(34) + #CRLF$
  Text + "  if codigo = 187 then msg$ = " + Chr(34) + "RAM disk nao existe" + Chr(34) + #CRLF$
  Text + "  if codigo = 188 then msg$ = " + Chr(34) + "RAM disk ja existe" + Chr(34) + #CRLF$
  Text + "  if codigo = 194 then msg$ = " + Chr(34) + "Numero de arquivo invalido (nao atribuido)" + Chr(34) + #CRLF$
  Text + "  if codigo = 195 then msg$ = " + Chr(34) + "Numero de arquivo invalido (maior que 63)" + Chr(34) + #CRLF$
  Text + "  if codigo = 196 then msg$ = " + Chr(34) + "Excesso de arquivos abertos" + Chr(34) + #CRLF$
  Text + "  if codigo = 199 then msg$ = " + Chr(34) + "Fim de arquivo encontrado" + Chr(34) + #CRLF$
  Text + "  if codigo = 202 then msg$ = " + Chr(34) + "Arquivo esta aberto" + Chr(34) + #CRLF$
  Text + "  if codigo = 203 then msg$ = " + Chr(34) + "Arquivo ja existe (criar diretorio)" + Chr(34) + #CRLF$
  Text + "  if codigo = 204 then msg$ = " + Chr(34) + "Diretorio ja existe" + Chr(34) + #CRLF$
  Text + "  if codigo = 205 then msg$ = " + Chr(34) + "Arquivo de sistema existe" + Chr(34) + #CRLF$
  Text + "  if codigo = 206 then msg$ = " + Chr(34) + "Operacao invalida com . ou .." + Chr(34) + #CRLF$
  Text + "  if codigo = 207 then msg$ = " + Chr(34) + "Atributos invalidos" + Chr(34) + #CRLF$
  Text + "  if codigo = 208 then msg$ = " + Chr(34) + "Diretorio nao esta vazio" + Chr(34) + #CRLF$
  Text + "  if codigo = 209 then msg$ = " + Chr(34) + "Arquivo somente leitura" + Chr(34) + #CRLF$
  Text + "  if codigo = 210 then msg$ = " + Chr(34) + "Movimento de diretorio invalido" + Chr(34) + #CRLF$
  Text + "  if codigo = 211 then msg$ = " + Chr(34) + "Arquivo ja existe (renomear/mover)" + Chr(34) + #CRLF$
  Text + "  if codigo = 212 then msg$ = " + Chr(34) + "Disco cheio" + Chr(34) + #CRLF$
  Text + "  if codigo = 213 then msg$ = " + Chr(34) + "Diretorio raiz cheio" + Chr(34) + #CRLF$
  Text + "  if codigo = 214 then msg$ = " + Chr(34) + "Diretorio nao encontrado" + Chr(34) + #CRLF$
  Text + "  if codigo = 215 then msg$ = " + Chr(34) + "Arquivo nao encontrado" + Chr(34) + #CRLF$
  Text + "  if codigo = 217 then msg$ = " + Chr(34) + "Caminho invalido" + Chr(34) + #CRLF$
  Text + "  if codigo = 218 then msg$ = " + Chr(34) + "Nome de arquivo invalido" + Chr(34) + #CRLF$
  Text + "  if codigo = 219 then msg$ = " + Chr(34) + "Unidade invalida" + Chr(34) + #CRLF$
  Text + "  if codigo = 222 then msg$ = " + Chr(34) + "Memoria interna do DOS 2 insuficiente" + Chr(34) + #CRLF$
  Text + "ret msg$" + #CRLF$

  ProcedureReturn Text
EndProcedure

; Corpo dos wrappers .NB_* de Tier 2: compressao/descompressao grafica
; (53-54), execucao de programas BASIC guardados em RAM (55-57), execucao
; de codigo de maquina/rotinas diversas (58-66), efeitos PSG (67-70) e
; tocador Moonblaster (71-79). Mesma convencao de Tier 1 (NestorBasicLibraryText):
; devolve so o(s) valor(es) principal(is) + erro por ultimo, resto fica em
; p()/f$(). Nenhuma destas funcoes faz BLOAD - todas sao usr() puro, entao
; func/ret (GOSUB/RETURN) e seguro em todas elas (ver nota no topo do
; arquivo sobre o unico caso onde isso nao vale: BLOAD"...",R).
Procedure.s NestorBasicLibraryTier2Text()
  Protected Text.s = ""

  ; --- 10.6 Compressao e descompressao grafica ---
  Text + "' --- 10.6 Compressao e descompressao grafica (formato Sunrise) ---" + #CRLF$
  Text + #CRLF$
  Text + "' Comprime dados graficos da VRAM pra um ou mais segmentos consecutivos" + #CRLF$
  Text + "' de RAM. Se a compressao encher um segmento, continua sozinha no" + #CRLF$
  Text + "' proximo (por isso segDestino/endDestino podem voltar diferentes do" + #CRLF$
  Text + "' que foi passado). Nao suporta segmentos VRAM nem o 255 como destino." + #CRLF$
  Text + "func .NB_CompressGraphics(blocoOrigem, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)" + #CRLF$
  Text + "  p(0) = blocoOrigem" + #CRLF$
  Text + "  p(1) = endOrigem" + #CRLF$
  Text + "  p(2) = segDestino" + #CRLF$
  Text + "  p(3) = endDestino" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(5) = incOrigem" + #CRLF$
  Text + "  p(6) = incDestino" + #CRLF$
  Text + "  erro = usr(53)" + #CRLF$
  Text + "ret p(7), p(8), p(0), p(1), p(2), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Descomprime dados de um ou mais segmentos consecutivos de RAM pra" + #CRLF$
  Text + "' VRAM (mesma logica de continuar sozinha no proximo segmento). Nao" + #CRLF$
  Text + "' suporta segmentos VRAM nem o 255 como origem." + #CRLF$
  Text + "func .NB_DecompressGraphics(blocoDestino, endDestino, segOrigem, endOrigem, incDestino, incOrigem)" + #CRLF$
  Text + "  p(0) = blocoDestino" + #CRLF$
  Text + "  p(1) = endDestino" + #CRLF$
  Text + "  p(2) = segOrigem" + #CRLF$
  Text + "  p(3) = endOrigem" + #CRLF$
  Text + "  p(5) = incDestino" + #CRLF$
  Text + "  p(6) = incOrigem" + #CRLF$
  Text + "  erro = usr(54)" + #CRLF$
  Text + "ret p(7), p(8), p(0), p(1), p(2), p(3), erro" + #CRLF$
  Text + #CRLF$

  ; --- 10.7 Execucao de programas BASIC guardados em RAM ---
  Text + "' --- 10.7 Execucao de programas BASIC guardados em RAM ---" + #CRLF$
  Text + "' ATENCAO: pra usar as 3 funcoes desta secao, o endereco inicial dos" + #CRLF$
  Text + "' programas BASIC precisa ter sido trocado de &H8000 pra &H8003 ANTES" + #CRLF$
  Text + "' de instalar o NestorBASIC (poke &Hf676,4:poke &H8003,0:new - so uma" + #CRLF$
  Text + "' vez, no programa que faz isso e depois carrega o NestorBASIC - ver" + #CRLF$
  Text + "' secao 6 do manual)." + #CRLF$
  Text + #CRLF$
  Text + "' Executa um programa BASIC guardado no segmento/endereco indicado" + #CRLF$
  Text + "' (formato especial - ver .NB_SaveBasicProgram). Se der certo, o" + #CRLF$
  Text + "' programa atual NUNCA retorna daqui (o novo programa roda da linha 1," + #CRLF$
  Text + "' com as variaveis do programa atual preservadas); so retorna em caso" + #CRLF$
  Text + "' de erro. (S4)" + #CRLF$
  Text + "func .NB_RunBasicProgram(segmento, endereco)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(55)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Igual a .NB_RunBasicProgram, mas ao inves de rodar da linha 1, larga" + #CRLF$
  Text + "' no modo direto (programa carregado e pronto, mas parado). Se der" + #CRLF$
  Text + "' certo tambem nunca retorna daqui. (S4)" + #CRLF$
  Text + "func .NB_ActivateBasicProgram(segmento, endereco)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(56)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Salva o programa BASIC ativo num arquivo, com o cabecalho especial" + #CRLF$
  Text + "' que .NB_RunBasicProgram/.NB_ActivateBasicProgram esperam (depois so" + #CRLF$
  Text + "' carregar esse arquivo num segmento com .NB_ReadFile e chamar uma das" + #CRLF$
  Text + "' duas). p(1) devolve -1 se nao deu erro, ou o numero do arquivo (ainda" + #CRLF$
  Text + "' aberto) se deu erro de disco - feche com .NB_CloseFile(p(1)) nesse" + #CRLF$
  Text + "' caso. (S4)" + #CRLF$
  Text + "func .NB_SaveBasicProgram(byteCabecalho, nome$)" + #CRLF$
  Text + "  p(0) = byteCabecalho" + #CRLF$
  Text + "  f$(0) = nome$" + #CRLF$
  Text + "  erro = usr(57)" + #CRLF$
  Text + "ret p(1), erro" + #CRLF$
  Text + #CRLF$

  ; --- 10.8 Funcoes diversas ---
  Text + "' --- 10.8 Funcoes diversas ---" + #CRLF$
  Text + #CRLF$
  Text + "' Executa uma rotina de codigo de maquina na BIOS/SUB-BIOS/RAM" + #CRLF$
  Text + "' principal do BASIC/area de trabalho do sistema. subBios=0 executa" + #CRLF$
  Text + "' direto (BIOS, RAM principal via BLOAD, ou area de sistema como o" + #CRLF$
  Text + "' hook &HFFCA); subBios<>0 chama via EXTROM (so enderecos ate &H3FFF)." + #CRLF$
  Text + "' Registradores de entrada default 0 - so preencha os que a rotina" + #CRLF$
  Text + "' precisar. Devolve os registradores de saida (af,bc,de,hl,ix,iy e os" + #CRLF$
  Text + "' pares linha), mais a e as flags Cy/Z ja separadas de af (mais" + #CRLF$
  Text + "' conveniente que decompor af na mao)." + #CRLF$
  Text + "func .NB_ExecCode(subBios, endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)" + #CRLF$
  Text + "  p(0) = subBios" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = regAf" + #CRLF$
  Text + "  p(3) = regBc" + #CRLF$
  Text + "  p(4) = regDe" + #CRLF$
  Text + "  p(5) = regHl" + #CRLF$
  Text + "  p(6) = regIx" + #CRLF$
  Text + "  p(7) = regIy" + #CRLF$
  Text + "  p(8) = regAf2" + #CRLF$
  Text + "  p(9) = regBc2" + #CRLF$
  Text + "  p(10) = regDe2" + #CRLF$
  Text + "  p(11) = regHl2" + #CRLF$
  Text + "  erro = usr(58)" + #CRLF$
  Text + "ret p(2), p(3), p(4), p(5), p(6), p(7), p(8), p(9), p(10), p(11), p(12), p(13), p(14), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Executa uma rotina de codigo de maquina guardada num segmento de RAM" + #CRLF$
  Text + "' (precisa estar montada no intervalo &H8000-&HBFFF - o segmento e" + #CRLF$
  Text + "' trocado pra pagina 2 antes de chamar). Mesmos registradores de" + #CRLF$
  Text + "' .NB_ExecCode. Nao suporta segmentos VRAM nem o 255." + #CRLF$
  Text + "func .NB_ExecCodeInSegment(segmento, endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = regAf" + #CRLF$
  Text + "  p(3) = regBc" + #CRLF$
  Text + "  p(4) = regDe" + #CRLF$
  Text + "  p(5) = regHl" + #CRLF$
  Text + "  p(6) = regIx" + #CRLF$
  Text + "  p(7) = regIy" + #CRLF$
  Text + "  p(8) = regAf2" + #CRLF$
  Text + "  p(9) = regBc2" + #CRLF$
  Text + "  p(10) = regDe2" + #CRLF$
  Text + "  p(11) = regHl2" + #CRLF$
  Text + "  erro = usr(59)" + #CRLF$
  Text + "ret p(2), p(3), p(4), p(5), p(6), p(7), p(8), p(9), p(10), p(11), p(12), p(13), p(14), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Imprime uma string em modo grafico (SCREEN 5 a 11) - equivalente a" + #CRLF$
  Text + "' PRINT#1,texto$ com OPEN " + Chr(34) + "GRP:" + Chr(34) + "AS#1 ja feito, mas compativel com" + #CRLF$
  Text + "' TurboBASIC. Nao faz nada (sem erro) fora dessas SCREENs. Maximo 80" + #CRLF$
  Text + "' caracteres; nao pode conter o caractere 0 (chr$(0))." + #CRLF$
  Text + "func .NB_PrintGraphic(texto$)" + #CRLF$
  Text + "  f$(0) = texto$" + #CRLF$
  Text + "  erro = usr(60)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Guarda uma string num segmento (termina com um byte 0). Maximo 80" + #CRLF$
  Text + "' caracteres; nao pode conter o caractere 0." + #CRLF$
  Text + "func .NB_StoreString(texto$, segmento, endereco, incrementar)" + #CRLF$
  Text + "  f$(0) = texto$" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = incrementar" + #CRLF$
  Text + "  erro = usr(61)" + #CRLF$
  Text + "ret p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le uma string guardada num segmento (ate achar um byte 0, ou 80" + #CRLF$
  Text + "' caracteres). Fora de TurboBASIC, um caractere 255 na string vira 34" + #CRLF$
  Text + "' (aspas) por causa de como o BASIC classico atribui strings." + #CRLF$
  Text + "func .NB_RestoreString(segmento, endereco, incrementar)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = incrementar" + #CRLF$
  Text + "  erro = usr(62)" + #CRLF$
  Text + "ret f$(1), p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Inicializa o modo de " + Chr(34) + "piscar" + Chr(34) + " texto na SCREEN 0 (habilita cores e" + #CRLF$
  Text + "' tempos, e limpa a area de VRAM do blink). tempoLigado/tempoDesligado" + #CRLF$
  Text + "' (0 a 15) ambos 0 so limpa a area, sem mudar cores/tempos. So funciona" + #CRLF$
  Text + "' em SCREEN 0 com pelo menos 41 colunas." + #CRLF$
  Text + "func .NB_InitBlink(corFrente, corFundo, tempoLigado, tempoDesligado)" + #CRLF$
  Text + "  p(0) = corFrente" + #CRLF$
  Text + "  p(1) = corFundo" + #CRLF$
  Text + "  p(2) = tempoLigado" + #CRLF$
  Text + "  p(3) = tempoDesligado" + #CRLF$
  Text + "  erro = usr(63)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Cria (criar<>0) ou apaga (criar=0) um bloco de texto piscando, na" + #CRLF$
  Text + "' coluna/linha indicada (0-79/0-27) - chame .NB_InitBlink antes. So" + #CRLF$
  Text + "' funciona em SCREEN 0 com pelo menos 41 colunas (nao faz nada, sem" + #CRLF$
  Text + "' erro, fora disso)." + #CRLF$
  Text + "func .NB_SetBlinkBlock(criar, coluna, linha, largura, altura, incColuna, incLinha)" + #CRLF$
  Text + "  p(0) = criar" + #CRLF$
  Text + "  p(1) = coluna" + #CRLF$
  Text + "  p(2) = linha" + #CRLF$
  Text + "  p(3) = largura" + #CRLF$
  Text + "  p(4) = altura" + #CRLF$
  Text + "  p(5) = incColuna" + #CRLF$
  Text + "  p(6) = incLinha" + #CRLF$
  Text + "  erro = usr(64)" + #CRLF$
  Text + "ret p(1), p(2), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Informacoes sobre os processos de interrupcao ativos (interrupcao do" + #CRLF$
  Text + "' usuario, efeito PSG, musica). p(2)/p(3) (segmento/endereco da" + #CRLF$
  Text + "' interrupcao do usuario, validos mesmo se ela estiver parada) ficam" + #CRLF$
  Text + "' em p()." + #CRLF$
  Text + "func .NB_GetInterruptInfo()" + #CRLF$
  Text + "  erro = usr(65)" + #CRLF$
  Text + "ret p(0), p(1), p(4), p(5), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Define/ativa (acao=1, com segmento+endereco), para (acao=0) ou" + #CRLF$
  Text + "' inverte o estado atual (acao=-1) de uma rotina de interrupcao do" + #CRLF$
  Text + "' usuario (roda a 50/60Hz). A rotina precisa estar montada em" + #CRLF$
  Text + "' &H8000-&HBFFF do segmento indicado. Erro 7 = acao invalida; erro -1" + #CRLF$
  Text + "' = segmento invalido/VRAM/255." + #CRLF$
  Text + "func .NB_SetUserInterrupt(acao, segmento, endereco)" + #CRLF$
  Text + "  p(0) = acao" + #CRLF$
  Text + "  p(1) = segmento" + #CRLF$
  Text + "  p(2) = endereco" + #CRLF$
  Text + "  erro = usr(66)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$

  ; --- 10.9 Efeitos sonoros PSG ---
  Text + "' --- 10.9 Efeitos sonoros PSG ---" + #CRLF$
  Text + #CRLF$
  Text + "' Informacoes sobre os efeitos sonoros PSG (o conjunto precisa ter" + #CRLF$
  Text + "' sido inicializado com .NB_InitSfxSet). volumeMaximo novo (-1 = nao" + #CRLF$
  Text + "' muda; >15 vira 15). Nunca retorna erro." + #CRLF$
  Text + "func .NB_GetSfxInfo(volumeMaximo)" + #CRLF$
  Text + "  p(0) = volumeMaximo" + #CRLF$
  Text + "  erro = usr(67)" + #CRLF$
  Text + "ret p(1), p(2), p(7), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Inicializa um conjunto de efeitos sonoros PSG (criado no editor SEE" + #CRLF$
  Text + "' v3.xx) guardado no segmento/endereco indicado, deixando pronto pra" + #CRLF$
  Text + "' usar com .NB_PlaySfx. Erro 8 = formato invalido; erro -1 = segmento" + #CRLF$
  Text + "' invalido/VRAM/255." + #CRLF$
  Text + "func .NB_InitSfxSet(segmento, endereco)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(68)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Toca o efeito sonoro PSG indicado. Erro 9 = efeito nao definido" + #CRLF$
  Text + "' (trilha em OFF no editor); erro 10 = efeito nao existe (numero maior" + #CRLF$
  Text + "' que o maximo); erro 11 = outro efeito de prioridade maior ja esta" + #CRLF$
  Text + "' tocando." + #CRLF$
  Text + "func .NB_PlaySfx(efeito, prioridade)" + #CRLF$
  Text + "  p(0) = efeito" + #CRLF$
  Text + "  p(1) = prioridade" + #CRLF$
  Text + "  erro = usr(69)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Para o efeito sonoro PSG em execucao e silencia o PSG. Nunca retorna" + #CRLF$
  Text + "' erro." + #CRLF$
  Text + "func .NB_StopSfx()" + #CRLF$
  Text + "  erro = usr(70)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$

  ; --- 10.10 Tocador Moonblaster ---
  Text + "' --- 10.10 Tocador Moonblaster ---" + #CRLF$
  Text + #CRLF$
  Text + "' Carrega e inicializa (ou desinstala, acao=-1) o tocador Moonblaster" + #CRLF$
  Text + "' no segmento 5 (so existe se o segmento 5 existir e for do mapper" + #CRLF$
  Text + "' primario - senao erro -1). acao: 0=Moonblaster 1.4, 1=Moonblaster" + #CRLF$
  Text + "' Wave 1.05, 3=autodetectar (Wave se achar Moonsound, senao 1.4)." + #CRLF$
  Text + "' p(1) devolve -1 se nao deu erro, ou o numero do arquivo NBASIC.BIN" + #CRLF$
  Text + "' (ainda aberto) se deu erro de disco - feche com" + #CRLF$
  Text + "' .NB_CloseFile(p(1)) nesse caso. (S4)" + #CRLF$
  Text + "func .NB_LoadPlayer(acao)" + #CRLF$
  Text + "  p(0) = acao" + #CRLF$
  Text + "  erro = usr(71)" + #CRLF$
  Text + "ret p(0), p(1), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Informacoes sobre a musica Moonblaster em execucao/pausada e sobre o" + #CRLF$
  Text + "' tocador. p(12)=0 se nenhum tocador foi carregado (os demais" + #CRLF$
  Text + "' resultados, exceto deteccao de chips de som, ficam invalidos nesse" + #CRLF$
  Text + "' caso); f$(0)/f$(1) (nome da musica/samplekit ou wavekit) so valem se" + #CRLF$
  Text + "' p(0)<>0. Nunca retorna erro." + #CRLF$
  Text + "func .NB_GetMusicInfo()" + #CRLF$
  Text + "  erro = usr(72)" + #CRLF$
  Text + "ret p(0), p(4), f$(0), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Habilita/desabilita os chips de som (MSX-MUSIC/MSX-AUDIO/OPL4)." + #CRLF$
  Text + "' acao: 0=so consultar, 1=aplicar msxMusica/msxAudio/opl4 (cada um:" + #CRLF$
  Text + "' 0=nao mexe,1=desabilita,2=habilita,-1=inverte), 2=habilitar todos os" + #CRLF$
  Text + "' encontrados. So tem efeito na proxima musica tocada" + #CRLF$
  Text + "' (.NB_PlayMusic) ou apos parar/reiniciar a atual. Erro 7 = parametro" + #CRLF$
  Text + "' invalido; erro 12 = tocador nao instalado." + #CRLF$
  Text + "func .NB_SetSoundChips(acao, msxMusica, msxAudio, opl4)" + #CRLF$
  Text + "  p(0) = acao" + #CRLF$
  Text + "  p(1) = msxMusica" + #CRLF$
  Text + "  p(2) = msxAudio" + #CRLF$
  Text + "  p(3) = opl4" + #CRLF$
  Text + "  erro = usr(73)" + #CRLF$
  Text + "ret p(4), p(5), p(6), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Comeca a tocar uma musica Moonblaster guardada no segmento/endereco" + #CRLF$
  Text + "' indicado (Moonblaster Wave pode ocupar ate 3 segmentos" + #CRLF$
  Text + "' consecutivos). Erro -1 = segmento invalido/VRAM/255; erro 12 =" + #CRLF$
  Text + "' tocador nao inicializado; erro 13 = musica salva em modo EDIT (nao" + #CRLF$
  Text + "' da pra tocar) ou endereco sem musica Moonblaster Wave valida; erro" + #CRLF$
  Text + "' 14 = ja tem outra musica tocando." + #CRLF$
  Text + "func .NB_PlayMusic(segmento, endereco)" + #CRLF$
  Text + "  p(0) = segmento" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  erro = usr(74)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Para a musica Moonblaster em execucao e silencia os chips de som." + #CRLF$
  Text + "' Nunca retorna erro (nao faz nada se nao tiver musica tocando/tocador" + #CRLF$
  Text + "' nao inicializado)." + #CRLF$
  Text + "func .NB_StopMusic()" + #CRLF$
  Text + "  erro = usr(75)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Pausa (acao=0), continua (acao=1) ou inverte (acao=-1) a musica" + #CRLF$
  Text + "' Moonblaster em execucao/pausada. Erro 7 = parametro invalido; nao" + #CRLF$
  Text + "' faz nada (sem erro) se nao tiver musica tocando/pausada ou tocador" + #CRLF$
  Text + "' nao inicializado." + #CRLF$
  Text + "func .NB_PauseMusic(acao)" + #CRLF$
  Text + "  p(0) = acao" + #CRLF$
  Text + "  erro = usr(76)" + #CRLF$
  Text + "ret erro" + #CRLF$
  Text + #CRLF$
  Text + "' Inicia/continua (delay 1-254, quanto menor mais rapido) ou pausa" + #CRLF$
  Text + "' (delay=-1) o fade-out da musica Moonblaster em execucao - ao" + #CRLF$
  Text + "' completar, a musica para sozinha. delay=0 so consulta o estado" + #CRLF$
  Text + "' atual. Nunca retorna erro (nao faz nada se nao tiver musica" + #CRLF$
  Text + "' tocando/tocador nao inicializado)." + #CRLF$
  Text + "func .NB_FadeMusic(delay)" + #CRLF$
  Text + "  p(0) = delay" + #CRLF$
  Text + "  erro = usr(77)" + #CRLF$
  Text + "ret p(1), p(2), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le um samplekit Music Module (formato Moonblaster: 56 bytes de" + #CRLF$
  Text + "' cabecalho + 32K de amostras) de um arquivo ja aberto, na posicao" + #CRLF$
  Text + "' atual do ponteiro. Se o retorno vier maior que 16K, so os primeiros" + #CRLF$
  Text + "' 16K foram transferidos pra RAM de amostras; se vier exatamente" + #CRLF$
  Text + "' 32824, o valor verdadeiro nao cabe em inteiro e volta como -32712" + #CRLF$
  Text + "' (limite do BASIC). Nao faz nada (sem erro) se o tocador nao foi" + #CRLF$
  Text + "' inicializado ou nao ha Music Module." + #CRLF$
  Text + "func .NB_LoadSamplekit(numeroArquivo)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  erro = usr(78)" + #CRLF$
  Text + "ret p(7), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Le um wavekit Moonsound (formato Moonblaster Wave, precisa estar" + #CRLF$
  Text + "' salvo em modo USER - senao erro 15) de um arquivo ja aberto, na" + #CRLF$
  Text + "' posicao atual do ponteiro. Tamanho lido = bytesAlto*65536+bytesBaixo" + #CRLF$
  Text + "' (ver formula de conversao na secao 10.10 do manual se precisar" + #CRLF$
  Text + "' imprimir esse valor). Nao faz nada (sem erro) se o tocador Wave nao" + #CRLF$
  Text + "' foi inicializado ou nao ha Moonsound." + #CRLF$
  Text + "func .NB_LoadWavekit(numeroArquivo)" + #CRLF$
  Text + "  p(0) = numeroArquivo" + #CRLF$
  Text + "  erro = usr(79)" + #CRLF$
  Text + "ret p(6), p(7), erro" + #CRLF$

  ProcedureReturn Text
EndProcedure

; Corpo dos wrappers .NB_* de Tier 3: controle de quantos segmentos o
; NestorBASIC aloca pra si (80) e interacao com NestorMan/InterNestor
; Suite/Lite (81-86). Ao contrario do planejado (so constantes de numero de
; funcao, por parecerem "variaveis demais"), acabou sendo tao direto quanto
; Tier 1/2: 80/81/83/84 sao chamadas p()-simples iguais as de Tier 1, e
; 82/85/86 reaproveitam o mesmo formato de 10 registradores de entrada/13 de
; saida que .NB_ExecCode ja resolveu em Tier 2 - por isso wrappers
; completos em vez de so constantes. Mesma convencao de erro por ultimo;
; nenhuma faz BLOAD, entao func/ret e seguro em todas.
Procedure.s NestorBasicLibraryTier3Text()
  Protected Text.s = ""

  ; --- 10.11 Controle de uso de segmentos ---
  Text + "' --- 10.11 Controle de uso de segmentos ---" + #CRLF$
  Text + #CRLF$
  Text + "' Consulta (numSegmentos=0) ou define quantos segmentos o NestorBASIC" + #CRLF$
  Text + "' vai usar pra si mesmo - o resto fica livre pra outros programas que" + #CRLF$
  Text + "' tambem alocam segmentos (RAM disk do DOS 2, NestorMan, InterNestor" + #CRLF$
  Text + "' Suite). Se pedir menos de 6, o NestorBASIC usa 5 (ou 6 se o tocador" + #CRLF$
  Text + "' Moonblaster estiver carregado) mesmo assim; se pedir mais que o" + #CRLF$
  Text + "' disponivel, aloca o maximo possivel (ate 247). Nunca retorna erro." + #CRLF$
  Text + "func .NB_SetSegmentCount(numSegmentos)" + #CRLF$
  Text + "  p(0) = numSegmentos" + #CRLF$
  Text + "  erro = usr(80)" + #CRLF$
  Text + "ret p(0), p(1), erro" + #CRLF$
  Text + #CRLF$

  ; --- 10.12 Interacao com NestorMan e InterNestor Suite/Lite ---
  Text + "' --- 10.12 Interacao com NestorMan e InterNestor Suite/Lite ---" + #CRLF$
  Text + #CRLF$
  Text + "' Informacoes sobre a presenca do NestorMan e do InterNestor Suite." + #CRLF$
  Text + "' status: 0=NestorMan nao instalado, 1=NestorMan instalado," + #CRLF$
  Text + "' 3=NestorMan e InterNestor Suite instalados. Os segmentos NestorMan" + #CRLF$
  Text + "' de cada modulo do InterNestor Suite (1 a 4) ficam em p(1) a p(4) (so" + #CRLF$
  Text + "' validos se status=3); o segmento NestorMan do segmento 4 do" + #CRLF$
  Text + "' NestorBASIC (usado como buffer intermediario por" + #CRLF$
  Text + "' .NB_CopyFromNestorMan/.NB_CopyToNestorMan) e devolvido aqui - so" + #CRLF$
  Text + "' valido se status=1 ou 3. Nunca retorna erro." + #CRLF$
  Text + "func .NB_GetNestorManInfo()" + #CRLF$
  Text + "  erro = usr(81)" + #CRLF$
  Text + "ret p(0), p(5), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Executa a funcao do NestorMan indicada (numero de funcao - ver o" + #CRLF$
  Text + "' manual do NestorMan) por chamada indireta (hook estendido da BIOS)." + #CRLF$
  Text + "' Mesmos registradores de .NB_ExecCode. NOTA: a secao 9.5 do manual diz" + #CRLF$
  Text + "' que esta funcao nunca retorna erro, mas a descricao dela propria (secao" + #CRLF$
  Text + "' 10.12) diz erro -1 se o NestorMan nao estiver instalado - o manual" + #CRLF$
  Text + "' original se contradiz aqui; teste na pratica se depender disso. De" + #CRLF$
  Text + "' qualquer forma, nao verifica se a funcao pedida realmente existe no" + #CRLF$
  Text + "' NestorMan." + #CRLF$
  Text + "func .NB_CallNestorMan(funcao, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)" + #CRLF$
  Text + "  p(0) = funcao" + #CRLF$
  Text + "  p(2) = regAf" + #CRLF$
  Text + "  p(3) = regBc" + #CRLF$
  Text + "  p(4) = regDe" + #CRLF$
  Text + "  p(5) = regHl" + #CRLF$
  Text + "  p(6) = regIx" + #CRLF$
  Text + "  p(7) = regIy" + #CRLF$
  Text + "  p(8) = regAf2" + #CRLF$
  Text + "  p(9) = regBc2" + #CRLF$
  Text + "  p(10) = regDe2" + #CRLF$
  Text + "  p(11) = regHl2" + #CRLF$
  Text + "  erro = usr(82)" + #CRLF$
  Text + "ret p(2), p(3), p(4), p(5), p(6), p(7), p(8), p(9), p(10), p(11), p(12), p(13), p(14), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Copia um bloco de dados de um segmento do NestorMan pro NestorBASIC." + #CRLF$
  Text + "' segDestino nao pode ser o segmento 1 (TurboBASIC) - copie primeiro" + #CRLF$
  Text + "' pra outro segmento (ex.: o 4) se precisar. Erro -1 = segmento" + #CRLF$
  Text + "' invalido." + #CRLF$
  Text + "func .NB_CopyFromNestorMan(segOrigemNestorMan, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)" + #CRLF$
  Text + "  p(0) = segOrigemNestorMan" + #CRLF$
  Text + "  p(1) = endOrigem" + #CRLF$
  Text + "  p(2) = segDestino" + #CRLF$
  Text + "  p(3) = endDestino" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(5) = incOrigem" + #CRLF$
  Text + "  p(6) = incDestino" + #CRLF$
  Text + "  erro = usr(83)" + #CRLF$
  Text + "ret p(1), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Copia um bloco de dados do NestorBASIC pra um segmento do NestorMan." + #CRLF$
  Text + "' segOrigem nao pode ser o segmento 1 (TurboBASIC). Erro -1 = segmento" + #CRLF$
  Text + "' invalido." + #CRLF$
  Text + "func .NB_CopyToNestorMan(segOrigem, endOrigem, segDestinoNestorMan, endDestino, tamanho, incOrigem, incDestino)" + #CRLF$
  Text + "  p(0) = segOrigem" + #CRLF$
  Text + "  p(1) = endOrigem" + #CRLF$
  Text + "  p(2) = segDestinoNestorMan" + #CRLF$
  Text + "  p(3) = endDestino" + #CRLF$
  Text + "  p(4) = tamanho" + #CRLF$
  Text + "  p(5) = incOrigem" + #CRLF$
  Text + "  p(6) = incDestino" + #CRLF$
  Text + "  erro = usr(84)" + #CRLF$
  Text + "ret p(1), p(3), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Executa uma rotina de qualquer modulo do InterNestor Suite (1 a 4)." + #CRLF$
  Text + "' Mesmos registradores de .NB_ExecCode. Pra ler/escrever as" + #CRLF$
  Text + "' constantes/variaveis de configuracao dos modulos, use" + #CRLF$
  Text + "' .NB_GetNestorManInfo (segmentos NestorMan de cada modulo) e depois" + #CRLF$
  Text + "' .NB_CopyFromNestorMan/.NB_CopyToNestorMan. Erro -1 = InterNestor" + #CRLF$
  Text + "' Suite nao instalado, ou numero de modulo invalido." + #CRLF$
  Text + "func .NB_CallInterNestorSuite(modulo, endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)" + #CRLF$
  Text + "  p(0) = modulo" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = regAf" + #CRLF$
  Text + "  p(3) = regBc" + #CRLF$
  Text + "  p(4) = regDe" + #CRLF$
  Text + "  p(5) = regHl" + #CRLF$
  Text + "  p(6) = regIx" + #CRLF$
  Text + "  p(7) = regIy" + #CRLF$
  Text + "  p(8) = regAf2" + #CRLF$
  Text + "  p(9) = regBc2" + #CRLF$
  Text + "  p(10) = regDe2" + #CRLF$
  Text + "  p(11) = regHl2" + #CRLF$
  Text + "  erro = usr(85)" + #CRLF$
  Text + "ret p(2), p(3), p(4), p(5), p(6), p(7), p(8), p(9), p(10), p(11), p(12), p(13), p(14), erro" + #CRLF$
  Text + #CRLF$
  Text + "' Executa uma rotina do InterNestor Lite (endereco da rotina - ver o" + #CRLF$
  Text + "' manual do InterNestor Lite pra lista de rotinas). Mesmos" + #CRLF$
  Text + "' registradores de .NB_ExecCode (sem selecao de modulo - so existe uma" + #CRLF$
  Text + "' instancia). Erro -1 = InterNestor Lite nao instalado - pra checar" + #CRLF$
  Text + "' antes, sem chamar esta funcao: p(0)=0:p(1)=&Hffca:p(2)=0:p(4)=&H2203:" + #CRLF$
  Text + "' e=usr(58):if p(12)=0 then (nao instalado) - ver .NB_ExecCode/funcao" + #CRLF$
  Text + "' 58 do manual (registrador A na saida)." + #CRLF$
  Text + "func .NB_CallInterNestorLite(endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)" + #CRLF$
  Text + "  p(1) = endereco" + #CRLF$
  Text + "  p(2) = regAf" + #CRLF$
  Text + "  p(3) = regBc" + #CRLF$
  Text + "  p(4) = regDe" + #CRLF$
  Text + "  p(5) = regHl" + #CRLF$
  Text + "  p(6) = regIx" + #CRLF$
  Text + "  p(7) = regIy" + #CRLF$
  Text + "  p(8) = regAf2" + #CRLF$
  Text + "  p(9) = regBc2" + #CRLF$
  Text + "  p(10) = regDe2" + #CRLF$
  Text + "  p(11) = regHl2" + #CRLF$
  Text + "  erro = usr(86)" + #CRLF$
  Text + "ret p(2), p(3), p(4), p(5), p(6), p(7), p(8), p(9), p(10), p(11), p(12), p(13), p(14), erro" + #CRLF$

  ProcedureReturn Text
EndProcedure

Procedure.s NestorBasicTemplateText()
  Protected Text.s = ""

  Text + "' ------------------------------------------------------------" + #CRLF$
  Text + "'  Suporte ao NestorBASIC 1.11 (by Nestor Soriano / Konami Man)" + #CRLF$
  Text + "'" + #CRLF$
  Text + "'  NestorBASIC da acesso a memoria mapeada, VRAM, disco, compressao" + #CRLF$
  Text + "'  grafica, tocador Moonblaster, efeitos PSG e mais, tudo atraves de" + #CRLF$
  Text + "'  usr(numero_funcao) e dos arrays p() (parametros/retornos inteiros)" + #CRLF$
  Text + "'  e f$() (nomes de arquivo/strings, quando a funcao usa)." + #CRLF$
  Text + "'" + #CRLF$
  Text + "'  NBASIC.BIN precisa estar no disco/pasta do programa em tempo de" + #CRLF$
  Text + "'  execucao. O carregador logo abaixo (via GOTO, ver comentario perto" + #CRLF$
  Text + "'  de {NBasicLoad} - NAO pode ser func/ret) carrega e mostra o erro" + #CRLF$
  Text + "'  (se houver)." + #CRLF$
  Text + "'  Os wrappers .NB_* (mais abaixo) dao nome as funcoes mais comuns do" + #CRLF$
  Text + "'  NestorBASIC (geral, RAM, VRAM, disco) - use-os ao inves de usr()" + #CRLF$
  Text + "'  cru sempre que possivel." + #CRLF$
  Text + "' ------------------------------------------------------------" + #CRLF$
  Text + #CRLF$

  Text + "{inicio}" + #CRLF$
  Text + "defint p" + #CRLF$
  Text + "dim p(15)" + #CRLF$
  Text + "dim f$(1)" + #CRLF$
  Text + #CRLF$
  Text + "goto {NBasicLoad}" + #CRLF$
  Text + "{VoltaNBasicLoad}" + #CRLF$
  Text + #CRLF$
  Text + "' NestorBASIC instalado - p(0) tem o numero de segmentos de RAM" + #CRLF$
  Text + "' disponiveis (sempre >=5 se chegou ate aqui). Use os wrappers .NB_*" + #CRLF$
  Text + "' abaixo (ou usr(numero_funcao) direto) para chamar as funcoes do" + #CRLF$
  Text + "' NestorBASIC." + #CRLF$
  Text + #CRLF$

  Text + "end" + #CRLF$
  Text + #CRLF$

  ; O carregador usa GOTO/label, NUNCA func/ret (que vira GOSUB/RETURN no
  ; MSX-BASIC): BLOAD"NBASIC.BIN",R roda o codigo de maquina do
  ; NestorBASIC, que mexe na pilha do BASIC - o endereco de retorno que um
  ; GOSUB tivesse empilhado antes da chamada fica invalido, entao um
  ; RETURN depois do BLOAD,R nao sabe mais pra onde voltar (trava ou pula
  ; pro lugar errado). GOTO nao usa a pilha, entao nao tem esse problema -
  ; "goto {NBasicLoad}" acima pula pra ca, e o "goto {VoltaNBasicLoad}" no
  ; caminho de sucesso volta pro ponto logo apos a chamada.
  Text + "{NBasicLoad}" + #CRLF$
  Text + "bload " + Chr(34) + "nbasic.bin" + Chr(34) + ",r" + #CRLF$
  Text + "if p(0) >= 5 then goto {VoltaNBasicLoad}" + #CRLF$
  Text + "print " + Chr(34) + "Erro ao carregar o NestorBASIC: " + Chr(34) + ";" + #CRLF$
  Text + "if p(0) = 0 then print " + Chr(34) + "computador sem RAM mapeada (minimo 128K)." + Chr(34) + #CRLF$
  Text + "if p(0) = 1 then print " + Chr(34) + "erro de disco ao ler NBASIC.BIN." + Chr(34) + #CRLF$
  Text + "if p(0) = 2 then print " + Chr(34) + "sem segmentos livres no mapper primario (DOS 2)." + Chr(34) + #CRLF$
  Text + "if p(0) = 3 then print " + Chr(34) + "o NestorBASIC ja estava instalado." + Chr(34) + #CRLF$
  Text + "if p(0) = 4 then print " + Chr(34) + "erro nao definido nesta versao." + Chr(34) + #CRLF$
  Text + "end" + #CRLF$
  Text + #CRLF$

  Text + NestorBasicLibraryText()
  Text + NestorBasicLibraryTier2Text()
  Text + NestorBasicLibraryTier3Text()

  ProcedureReturn Text
EndProcedure
