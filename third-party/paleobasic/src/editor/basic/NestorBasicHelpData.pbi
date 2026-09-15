;
; ------------------------------------------------------------
;  Ajuda -> Nestor Basic...: base de dados dos topicos de ajuda (grupos +
;  87 funcoes 0-86 + introducao), fonte unica usada tanto pela janela de
;  ajuda navegavel/pesquisavel (NestorBasicHelpGui.pbi) quanto pela
;  exportacao pra docs/reference/nestorbasic.md (NBHelp_ExportMarkdown) -
;  editar o conteudo aqui atualiza os dois ao mesmo tempo, sem duplicar
;  texto em dois lugares que podem divergir.
;
;  Corpo.s usa uma marcacao Markdown bem pequena e deliberadamente limitada
;  (so o que NBHelpGui_RenderMarkdown, em NestorBasicHelpGui.pbi, sabe
;  desenhar): linhas "## " (subtitulo em negrito), linhas "- " (item de
;  lista, mostrado como esta), "**texto**" (negrito inline) e "`texto`"
;  (codigo inline, cor destacada) - nada alem disso. Isso mantem
;  NBHelp_ExportMarkdown() gerando um .md de verdade, valido, sem precisar
;  de um parser Markdown completo pra mostrar dentro do editor.
;
;  Wrapper.s + Chamada.s: nome do wrapper .NB_* e um exemplo pronto de
;  chamada (com nomes de variavel de retorno, nao so p(n) cru) - montados
;  pra bater exatamente com o corpo real gerado por
;  NestorBasicSupport.pbi (NestorBasicLibraryText/Tier2/Tier3). Exibidos
;  juntos, antes do resto do corpo, por NBHelp_FullBody() - assim o usuario
;  ve de cara "essa funcao vira NB_Tal, e chama-se assim" sem precisar
;  decorar/repetir a tabela p()/f$() na cabeca.
; ------------------------------------------------------------
;

Structure NBHelpTopic
  Numero.i     ; numero da funcao NestorBASIC (0-86); -1 para topicos que nao sao funcao (introducao/grupo)
  Titulo.s
  Grupo.s      ; nome do grupo/secao (usado tambem na arvore e na busca)
  Wrapper.s    ; nome do wrapper .NB_* correspondente ("" se nao ha - ex.: topicos de introducao/grupo)
  Chamada.s    ; exemplo de chamada pronto ("var, erro = .NB_Xxx(args)"); varias linhas
               ; separadas por #CRLF$ quando a funcao vira mais de um wrapper (ex.: 50/51)
  Corpo.s      ; corpo em Markdown leve, ver nota acima
EndStructure

Global NewList NBHelp_Topics.NBHelpTopic()

Declare NBHelp_BuildDataDisk()
Declare NBHelp_BuildDataTier2()
Declare NBHelp_BuildDataTier3()

Procedure NBHelp_Add(Numero.i, Titulo.s, Grupo.s, Wrapper.s, Corpo.s, Chamada.s = "")
  AddElement(NBHelp_Topics())
  NBHelp_Topics()\Numero = Numero
  NBHelp_Topics()\Titulo = Titulo
  NBHelp_Topics()\Grupo = Grupo
  NBHelp_Topics()\Wrapper = Wrapper
  NBHelp_Topics()\Corpo = Corpo
  NBHelp_Topics()\Chamada = Chamada
EndProcedure

; Texto usado pra filtrar (busca por nome, numero ou grupo) - tudo em
; minusculas, um campo so por topico.
Procedure.s NBHelp_SearchKey(*Topic.NBHelpTopic)
  Protected Key.s = LCase(*Topic\Titulo + " " + *Topic\Grupo + " " + *Topic\Wrapper)
  If *Topic\Numero >= 0
    Key + " " + Str(*Topic\Numero)
  EndIf
  ProcedureReturn Key
EndProcedure

; Corpo completo mostrado (janela de ajuda e exportacao .md): nome do
; wrapper + exemplo(s) de chamada primeiro (se houver), depois o Corpo.s
; normal (Entrada/Saida/Erros/notas). Chamada.s pode ter varias linhas
; (#CRLF$) quando um topico vira mais de um wrapper (ex.: funcoes 50/51,
; que tem uma variante "ByHandle" e uma "ByName") - cada linha vira um
; item de lista com codigo inline proprio.
Procedure.s NBHelp_FullBody(*Topic.NBHelpTopic)
  Protected Text.s = ""
  If *Topic\Wrapper <> ""
    Text + "**Wrapper Dignified:** `" + *Topic\Wrapper + "`" + #CRLF$ + #CRLF$
  EndIf
  If *Topic\Chamada <> ""
    Text + "**Como chamar:**" + #CRLF$
    Protected NLines = CountString(*Topic\Chamada, #CRLF$) + 1
    Protected LineIdx
    For LineIdx = 1 To NLines
      Text + "- `" + StringField(*Topic\Chamada, LineIdx, #CRLF$) + "`" + #CRLF$
    Next
    Text + #CRLF$
  EndIf
  Text + *Topic\Corpo
  ProcedureReturn Text
EndProcedure

Procedure NBHelp_BuildData()
  If ListSize(NBHelp_Topics()) > 0
    ProcedureReturn ; ja construido - so monta uma vez por sessao
  EndIf

  ; --- Introducao ---
  NBHelp_Add(-1, "Introducao ao NestorBASIC", "Introducao", "",
    "NestorBASIC (by Nestor Soriano / Konami Man, 2004) e um conjunto de rotinas em codigo de " +
    "maquina que da acesso, direto do MSX-BASIC, a memoria mapeada (ate 4Mb), VRAM inteira, " +
    "disco/setores fisicos, compressao grafica, execucao de programas BASIC guardados em RAM, " +
    "tocador Moonblaster, efeitos sonoros PSG e mais - tudo TurboBASIC-compativel." + #CRLF$ + #CRLF$ +
    "## Carregamento" + #CRLF$ +
    "Uma unica vez por programa: `bload " + Chr(34) + "nbasic.bin" + Chr(34) + ",r`. Depois disso:" + #CRLF$ +
    "- `p(0)` = numero de segmentos de RAM disponiveis (sempre >=5), ou codigo de erro (0 a 4) se a instalacao falhou" + #CRLF$ +
    "- O primeiro `usr()` (ou `usr0()`) fica reservado pro NestorBASIC - `usr1` a `usr9` continuam livres" + #CRLF$ + #CRLF$ +
    "**IMPORTANTE:** o carregamento NUNCA pode ser feito dentro de `func`/`ret` (GOSUB/RETURN) - o " +
    "`bload...,r` mexe na pilha do BASIC, entao um RETURN depois quebra. Use GOTO/rotulo (ver o " +
    "template gerado por Arquivo -> Novo Nestor Basic..., que ja faz isso certo)." + #CRLF$ + #CRLF$ +
    "## Modelo de chamada" + #CRLF$ +
    "Toda funcao usa `usr(numero)`, parametros/retornos no array inteiro `p()` (`defint p:dim p(15)` " +
    "no minimo) e, quando a funcao mexe com nomes de arquivo ou texto, o array de strings `f$()` " +
    "(`dim f$(1)` se precisar de duas strings ao mesmo tempo, `dim f$(0)` senao). O valor devolvido " +
    "por `usr()` e sempre o codigo de erro (0 = sem erro). Cada topico de funcao aqui mostra o nome " +
    "do wrapper Dignified `.NB_*` correspondente (gerado em Arquivo -> Novo Nestor Basic...) e um " +
    "exemplo pronto de como chama-lo - use-os ao inves de montar `p()`/`usr()` na mao sempre que " +
    "possivel." + #CRLF$ + #CRLF$ +
    "## Segmentos logicos" + #CRLF$ +
    "A RAM mapeada e organizada em segmentos logicos de 16K (endereco `&H0000` a `&H3FFF` dentro de " +
    "cada um), numerados de forma uniforme independente de slot/segmento fisico real:" + #CRLF$ +
    "- `0` = o proprio NestorBASIC" + #CRLF$ +
    "- `1` = TurboBASIC (so sobrescreva se nao for usar o compilador)" + #CRLF$ +
    "- `2` = RAM principal do BASIC, pagina 2 (`&H8000`-`&HBFFF`)" + #CRLF$ +
    "- `3` = RAM principal do BASIC, pagina 3 (`&HC000`-`&HFFFF`)" + #CRLF$ +
    "- `4` = buffer interno (usado pelas funcoes marcadas **(S4)** - nao guarde dados la enquanto usa-las)" + #CRLF$ +
    "- `5` a `p(0)-1` = livres pro programa (o `5` vira o tocador Moonblaster se `.NB_LoadPlayer` for chamado)" + #CRLF$ +
    "- `255` = alias especial pra RAM principal do BASIC (`&H8000`-`&HFFFF` direto, sem converter endereco)" + #CRLF$ +
    "- Acima de `p(0)-1`: segmentos de VRAM (ver .NB_VReadByte e funcoes de VRAM) - so nas funcoes que aceitam" + #CRLF$ + #CRLF$ +
    "## Sobre esta ajuda" + #CRLF$ +
    "Navegue pela arvore a esquerda (grupos = secoes do manual original) ou digite na caixa de busca " +
    "pra filtrar por nome, numero de funcao ou grupo.")

  ; --- Grupo: Funcoes gerais ---
  NBHelp_Add(-1, "Funcoes gerais", "Funcoes gerais", "",
    "Instalacao/desinstalacao do NestorBASIC e informacoes gerais sobre ele e sobre um segmento.")

  NBHelp_Add(0, "Desinstalar o NestorBASIC (S4)", "Funcoes gerais", ".NB_Uninstall",
    "Desinstala o NestorBASIC: libera o `usr()` e, no DOS 2, desaloca todos os segmentos. Tambem " +
    "para qualquer interrupcao do usuario, efeito PSG ou musica em execucao. Sempre desinstale " +
    "antes de voltar ao DOS - senao os segmentos alocados ficam presos ate reiniciar o computador." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = 0 para NAO liberar a area de RAM principal do BASIC reservada pela rotina de salto " +
    "(~500 bytes) - um CLEAR feito depois da instalacao continua valido; <>0 pra liberar (faz um " +
    "CLEAR automatico, FRE(0) volta ao valor de antes de instalar - as variaveis sao reinicializadas)" + #CRLF$ + #CRLF$ +
    "Nunca retorna erro.",
    "erro = .NB_Uninstall(liberarRam)")

  NBHelp_Add(1, "Informacoes gerais e sobre um segmento", "Funcoes gerais", ".NB_GetInfo",
    "Devolve informacoes gerais sobre o NestorBASIC instalado e sobre um segmento especifico." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = segmento logico a investigar" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(0)` = numero de segmentos de RAM disponiveis" + #CRLF$ +
    "- `p(1)` = versao principal do NestorBASIC" + #CRLF$ +
    "- `p(2)` = versao secundaria (BCD, mostrar em hexadecimal)" + #CRLF$ +
    "- `p(3)` = versao principal do MSX-DOS" + #CRLF$ +
    "- `p(4)` = versao secundaria do MSX-DOS (BCD, mostrar em hexadecimal)" + #CRLF$ +
    "- `p(5)` = tamanho ocupado na RAM principal pela rotina de salto do NestorBASIC" + #CRLF$ +
    "- `p(6)` = tamanho da VRAM em K (64 ou 128)" + #CRLF$ +
    "- `p(7)` = endereco inicial da area livre no segmento 0 (maximo `&H3DA8`; ha um bug documentado " +
    "no manual original - o valor volta pertencendo a pagina 1, ex. `&H7C60`, e precisa ser ajustado " +
    "pro intervalo `&H0000`-`&H4000` antes de usar)" + #CRLF$ +
    "- `p(8)` = numero da ultima funcao chamada (esta funcao 1 nao conta)" + #CRLF$ +
    "- `p(9)` = numero de arquivos abertos no momento" + #CRLF$ +
    "- `p(10)` = numero maximo de arquivos simultaneos (so vale sob DOS 1)" + #CRLF$ +
    "- `p(11)` = slot do segmento pedido em `p(0)` (255 se nao existir ou for VRAM)" + #CRLF$ +
    "- `p(12)` = segmento fisico do segmento pedido em `p(0)`" + #CRLF$ +
    "- `f$(0)` = caminho completo do arquivo NBASIC.BIN" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ +
    "-1 = o segmento pedido em `p(0)` nao existe, e VRAM ou e o 255 (mesmo assim, `p(0)` a `p(10)` " +
    "continuam validos).",
    "numSegmentos, erro = .NB_GetInfo(segmento)")

  ; --- Grupo: Acesso a segmentos (RAM) ---
  NBHelp_Add(-1, "Acesso a segmentos (RAM)", "Acesso a segmentos (RAM)", "",
    "Leitura, escrita, copia e preenchimento de bytes/inteiros dentro dos segmentos logicos de RAM " +
    "(funcoes 2 a 12). Endereco sempre no intervalo `&H0000`-`&H3FFF` dentro do segmento.")

  NBHelp_Add(2, "Ler um byte de um segmento", "Acesso a segmentos (RAM)", ".NB_ReadByte",
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` = byte lido",
    "byte, erro = .NB_ReadByte(segmento, endereco)")

  NBHelp_Add(3, "Ler um byte de um segmento (com autoincremento)", "Acesso a segmentos (RAM)", ".NB_ReadByteInc",
    "Igual a funcao 2, mas devolve o endereco seguinte - util pra ler sequencialmente em loop." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` = byte lido" + #CRLF$ + "- `p(1)` = `p(1)+1`",
    "byte, novoEndereco, erro = .NB_ReadByteInc(segmento, endereco)")

  NBHelp_Add(4, "Ler um inteiro de um segmento", "Acesso a segmentos (RAM)", ".NB_ReadInt",
    "Le 2 bytes (byte baixo no endereco, byte alto no endereco+1)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` = inteiro lido",
    "valor, erro = .NB_ReadInt(segmento, endereco)")

  NBHelp_Add(5, "Ler um inteiro de um segmento (com autoincremento)", "Acesso a segmentos (RAM)", ".NB_ReadIntInc",
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` = inteiro lido" + #CRLF$ + "- `p(1)` = `p(1)+2`",
    "valor, novoEndereco, erro = .NB_ReadIntInc(segmento, endereco)")

  NBHelp_Add(6, "Escrever um byte num segmento", "Acesso a segmentos (RAM)", ".NB_WriteByte",
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + "- `p(2)` = byte a escrever",
    "erro = .NB_WriteByte(segmento, endereco, valor)")

  NBHelp_Add(7, "Escrever um byte num segmento (com autoincremento)", "Acesso a segmentos (RAM)", ".NB_WriteByteInc",
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + "- `p(2)` = byte a escrever" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = `p(1)+1`",
    "novoEndereco, erro = .NB_WriteByteInc(segmento, endereco, valor)")

  NBHelp_Add(8, "Escrever um inteiro num segmento", "Acesso a segmentos (RAM)", ".NB_WriteInt",
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + "- `p(2)` = inteiro a escrever",
    "erro = .NB_WriteInt(segmento, endereco, valor)")

  NBHelp_Add(9, "Escrever um inteiro num segmento (com autoincremento)", "Acesso a segmentos (RAM)", ".NB_WriteIntInc",
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + "- `p(2)` = inteiro a escrever" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = `p(1)+2`",
    "novoEndereco, erro = .NB_WriteIntInc(segmento, endereco, valor)")

  NBHelp_Add(10, "Copiar um bloco entre segmentos", "Acesso a segmentos (RAM)", ".NB_CopySegToSeg",
    "`p(3)+p(4)` precisa ficar abaixo de `&H4000`, senao o resultado e imprevisivel." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = segmento de origem" + #CRLF$ + "- `p(1)` = endereco de origem" + #CRLF$ +
    "- `p(2)` = segmento de destino" + #CRLF$ + "- `p(3)` = endereco de destino" + #CRLF$ +
    "- `p(4)` = tamanho" + #CRLF$ + "- `p(5)` = <>0 autoincrementa `p(1)`" + #CRLF$ +
    "- `p(6)` = <>0 autoincrementa `p(3)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = `p(1)+p(4)` se `p(5)<>0`" + #CRLF$ + "- `p(3)` = `p(3)+p(4)` se `p(6)<>0`",
    "novoEndOrigem, novoEndDestino, erro = .NB_CopySegToSeg(segOrigem, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)")

  NBHelp_Add(11, "Preencher uma area de RAM com um byte", "Acesso a segmentos (RAM)", ".NB_FillRam",
    "`p(1)+p(3)` precisa ficar abaixo de `&H4000`." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco inicial" + #CRLF$ +
    "- `p(2)` = byte" + #CRLF$ + "- `p(3)` = tamanho da area",
    "erro = .NB_FillRam(segmento, endereco, byte, tamanho)")

  NBHelp_Add(12, "Preencher uma area de RAM com um byte (com autoincremento)", "Acesso a segmentos (RAM)", ".NB_FillRamInc",
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco inicial" + #CRLF$ +
    "- `p(2)` = byte" + #CRLF$ + "- `p(3)` = tamanho da area" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = `p(1)+p(3)`",
    "novoEndereco, erro = .NB_FillRamInc(segmento, endereco, byte, tamanho)")

  ; --- Grupo: Acesso a VRAM ---
  NBHelp_Add(-1, "Acesso a VRAM", "Acesso a VRAM", "",
    "Leitura, escrita, copia e preenchimento na VRAM inteira (funcoes 13 a 25). `bloco` = 0 (64K VRAM " +
    "baixa) ou 1 (64K VRAM alta, so em maquinas com 128K); endereco `&H0000`-`&HFFFF`. Se um " +
    "autoincremento passar de `&HFFFF`, o endereco volta a 0 e o bloco se inverte (0<->1).")

  NBHelp_Add(13, "Ler um byte da VRAM", "Acesso a VRAM", ".NB_VReadByte",
    "## Entrada" + #CRLF$ + "- `p(0)` = bloco" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` = byte lido",
    "byte, erro = .NB_VReadByte(bloco, endereco)")

  NBHelp_Add(14, "Ler um byte da VRAM (com autoincremento)", "Acesso a VRAM", ".NB_VReadByteInc",
    "## Entrada" + #CRLF$ + "- `p(0)` = bloco" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` = byte lido" + #CRLF$ + "- `p(0):p(1)` = `p(0):p(1)+1` (pode virar o bloco)",
    "byte, novoBloco, novoEndereco, erro = .NB_VReadByteInc(bloco, endereco)")

  NBHelp_Add(15, "Ler um inteiro da VRAM", "Acesso a VRAM", ".NB_VReadInt",
    "## Entrada" + #CRLF$ + "- `p(0)` = bloco" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` = inteiro lido",
    "valor, erro = .NB_VReadInt(bloco, endereco)")

  NBHelp_Add(16, "Ler um inteiro da VRAM (com autoincremento)", "Acesso a VRAM", ".NB_VReadIntInc",
    "## Entrada" + #CRLF$ + "- `p(0)` = bloco" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` = inteiro lido" + #CRLF$ + "- `p(0):p(1)` = `p(0):p(1)+2`",
    "valor, novoBloco, novoEndereco, erro = .NB_VReadIntInc(bloco, endereco)")

  NBHelp_Add(17, "Escrever um byte na VRAM", "Acesso a VRAM", ".NB_VWriteByte",
    "## Entrada" + #CRLF$ + "- `p(0)` = bloco" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + "- `p(2)` = byte a escrever",
    "erro = .NB_VWriteByte(bloco, endereco, valor)")

  NBHelp_Add(18, "Escrever um byte na VRAM (com autoincremento)", "Acesso a VRAM", ".NB_VWriteByteInc",
    "## Entrada" + #CRLF$ + "- `p(0)` = bloco" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + "- `p(2)` = byte a escrever" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(0):p(1)` = `p(0):p(1)+1`",
    "novoBloco, novoEndereco, erro = .NB_VWriteByteInc(bloco, endereco, valor)")

  NBHelp_Add(19, "Escrever um inteiro na VRAM", "Acesso a VRAM", ".NB_VWriteInt",
    "## Entrada" + #CRLF$ + "- `p(0)` = bloco" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + "- `p(2)` = inteiro a escrever",
    "erro = .NB_VWriteInt(bloco, endereco, valor)")

  NBHelp_Add(20, "Escrever um inteiro na VRAM (com autoincremento)", "Acesso a VRAM", ".NB_VWriteIntInc",
    "## Entrada" + #CRLF$ + "- `p(0)` = bloco" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + "- `p(2)` = inteiro a escrever" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(0):p(1)` = `p(0):p(1)+2`",
    "novoBloco, novoEndereco, erro = .NB_VWriteIntInc(bloco, endereco, valor)")

  NBHelp_Add(21, "Copiar um bloco da VRAM pra RAM", "Acesso a VRAM", ".NB_CopyVramToRam",
    "`p(3)+p(4)` precisa ficar abaixo de `&H4000`." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = bloco de origem (VRAM)" + #CRLF$ + "- `p(1)` = endereco de origem (VRAM)" + #CRLF$ +
    "- `p(2)` = segmento de destino" + #CRLF$ + "- `p(3)` = endereco de destino" + #CRLF$ +
    "- `p(4)` = tamanho" + #CRLF$ + "- `p(5)` = <>0 autoincrementa origem" + #CRLF$ +
    "- `p(6)` = <>0 autoincrementa destino" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = `p(1)+p(4)` se `p(5)<>0`" + #CRLF$ + "- `p(2):p(3)` = `p(2):p(3)+p(4)` se `p(6)<>0`",
    "novoBlocoOrigem, novoEndOrigem, novoEndDestino, erro = .NB_CopyVramToRam(blocoOrigem, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)")

  NBHelp_Add(22, "Copiar um bloco da RAM pra VRAM", "Acesso a VRAM", ".NB_CopyRamToVram",
    "## Entrada" + #CRLF$ +
    "- `p(0)` = segmento de origem" + #CRLF$ + "- `p(1)` = endereco de origem" + #CRLF$ +
    "- `p(2)` = bloco de destino (VRAM)" + #CRLF$ + "- `p(3)` = endereco de destino (VRAM)" + #CRLF$ +
    "- `p(4)` = tamanho" + #CRLF$ + "- `p(5)` = <>0 autoincrementa origem" + #CRLF$ +
    "- `p(6)` = <>0 autoincrementa destino" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = `p(1)+p(4)` se `p(5)<>0`" + #CRLF$ + "- `p(2):p(3)` = `p(2):p(3)+p(4)` se `p(6)<>0`",
    "novoEndOrigem, novoBlocoDestino, novoEndDestino, erro = .NB_CopyRamToVram(segOrigem, endOrigem, blocoDestino, endDestino, tamanho, incOrigem, incDestino)")

  NBHelp_Add(23, "Copiar um bloco entre duas areas da VRAM", "Acesso a VRAM", ".NB_CopyVramToVram",
    "Tamanho maximo `&H4000` bytes por chamada - pra blocos maiores (ate 64K), repita a chamada " +
    "incrementando os enderecos a cada volta." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = bloco de origem" + #CRLF$ + "- `p(1)` = endereco de origem" + #CRLF$ +
    "- `p(2)` = bloco de destino" + #CRLF$ + "- `p(3)` = endereco de destino" + #CRLF$ +
    "- `p(4)` = tamanho (maximo `&H4000`)" + #CRLF$ + "- `p(5)` = <>0 autoincrementa origem" + #CRLF$ +
    "- `p(6)` = <>0 autoincrementa destino" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(0):p(1)` = `p(0):p(1)+p(4)` se `p(5)<>0`" + #CRLF$ + "- `p(2):p(3)` = `p(2):p(3)+p(4)` se `p(6)<>0`",
    "novoBlocoOrigem, novoEndOrigem, novoBlocoDestino, novoEndDestino, erro = .NB_CopyVramToVram(blocoOrigem, endOrigem, blocoDestino, endDestino, tamanho, incOrigem, incDestino)")

  NBHelp_Add(24, "Preencher uma area de VRAM com um byte", "Acesso a VRAM", ".NB_FillVram",
    "Maximo 16K por chamada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = bloco" + #CRLF$ + "- `p(1)` = endereco inicial" + #CRLF$ +
    "- `p(2)` = byte" + #CRLF$ + "- `p(3)` = tamanho da area (maximo 16K)",
    "erro = .NB_FillVram(bloco, endereco, byte, tamanho)")

  NBHelp_Add(25, "Preencher uma area de VRAM com um byte (com autoincremento)", "Acesso a VRAM", ".NB_FillVramInc",
    "Maximo 16K por chamada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = bloco" + #CRLF$ + "- `p(1)` = endereco inicial" + #CRLF$ +
    "- `p(2)` = byte" + #CRLF$ + "- `p(3)` = tamanho da area (maximo 16K)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(0):p(1)` = `p(0):p(1)+p(3)`",
    "novoBloco, novoEndereco, erro = .NB_FillVramInc(bloco, endereco, byte, tamanho)")

  NBHelp_BuildDataDisk()
  NBHelp_BuildDataTier2()
  NBHelp_BuildDataTier3()
EndProcedure

; --- Grupo: Acesso a disco (funcoes 26-52) ---
Procedure NBHelp_BuildDataDisk()
  NBHelp_Add(-1, "Acesso a disco", "Acesso a disco", "",
    "Arquivos, diretorios, setores fisicos, unidades e RAM disk (funcoes 26 a 52). Atributos: " +
    "`R+2*H+4*S+8*V+16*D+32*A` (Somente leitura+Oculto+Sistema+Volume+Diretorio+Arquivo). Unidade " +
    "normalmente `0=A:,1=B:,...,7=H:` - EXCETO em .NB_GetDiskSpace e .NB_GetDir, onde e " +
    "`0=unidade padrao,1=A:,...,8=H:` (assim mesmo no manual original).")

  NBHelp_Add(26, "Procurar arquivos (S4)", "Acesso a disco", ".NB_FindFile",
    "`buscarProximo=0` procura o primeiro arquivo que bate com a mascara (vazia = `*.*`); deixe " +
    "`1` pras buscas seguintes (a propria funcao mantem isso em `p(0)`)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `f$(1)` = mascara de busca (pode ter unidade e, no DOS 2, caminho)" + #CRLF$ +
    "- `p(0)` = 0 primeira busca / 1 proxima busca" + #CRLF$ +
    "- `p(1)` = atributos de busca: `2*H+4*S+8*V+16*D` (incluir Ocultos/Sistema/so Volume/Diretorios)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `f$(0)` = nome do arquivo encontrado" + #CRLF$ + "- `p(0)` = 1" + #CRLF$ +
    "- `p(1)` = atributos do arquivo (sempre 0 no DOS 1): `R+2*H+4*S+8*V+16*D+32*A`" + #CRLF$ +
    "- `p(2)` a `p(6)` = hora, minuto, dia, mes, ano da ultima modificacao" + #CRLF$ +
    "- `p(7)` = primeiro cluster (2 a 4095)" + #CRLF$ + "- `p(8)` = unidade logica (0=A:,...,7=H:)" + #CRLF$ +
    "- `p(9)`/`p(10)` = tamanho do arquivo, parte baixa/alta (`p(9)+65536*p(10)`)" + #CRLF$ +
    "- `p(11)` = contador de resultados (0 se nao achou na primeira busca; incrementa a cada busca seguinte)" + #CRLF$ + #CRLF$ +
    "Erro quando nao ha mais arquivos batendo com a mascara (erro de arquivo nao encontrado).",
    "nomeArquivo$, erro = .NB_FindFile(mascara$, buscarProximo, atributosBusca)")

  NBHelp_Add(27, "Renomear um arquivo (S4)", "Acesso a disco", ".NB_RenameFile",
    "No DOS 1 aceita curingas e renomeia varios de uma vez; no DOS 2 so um arquivo por chamada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `f$(0)` = nome atual" + #CRLF$ + "- `f$(1)` = nome novo (so o nome, sem unidade/caminho)",
    "erro = .NB_RenameFile(nome$, novoNome$)")

  NBHelp_Add(28, "Apagar um arquivo (S4)", "Acesso a disco", ".NB_DeleteFile",
    "No DOS 1 aceita curingas (apaga varios de uma vez); no DOS 2 so um arquivo, e da erro se estiver aberto." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `f$(0)` = nome do arquivo (pode ter unidade e, no DOS 2, caminho)",
    "erro = .NB_DeleteFile(nome$)")

  NBHelp_Add(29, "Mover um arquivo (DOS 2)", "Acesso a disco", ".NB_MoveFile",
    "So existe no DOS 2 (no DOS 1 sempre da erro 1). Move uma pasta inteira move tambem seu conteudo." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `f$(0)` = nome/caminho atual" + #CRLF$ +
    "- `f$(1)` = novo local (so o caminho, sem nome de arquivo nem letra de unidade - so pode mover " +
    "dentro da mesma unidade)",
    "erro = .NB_MoveFile(nome$, novoLocal$)")

  NBHelp_Add(30, "Criar um arquivo ou diretorio", "Acesso a disco", ".NB_CreateFile",
    "O arquivo criado fica com 0 bytes e fechado (abra depois com .NB_OpenFile). No DOS 1 so cria " +
    "arquivos e `p(0)` e ignorado; no DOS 2 sempre cria com o atributo Archive alem dos pedidos." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `f$(0)` = nome do arquivo/subdiretorio (pode ter unidade e caminho)" + #CRLF$ +
    "- `p(0)` = atributos de criacao (ignorado no DOS 1): `R+2*H+4*S` (arquivo) ou `2*H+16` (diretorio)",
    "erro = .NB_CreateFile(nome$, atributos)")

  NBHelp_Add(31, "Abrir um arquivo", "Acesso a disco", ".NB_OpenFile",
    "## Entrada" + #CRLF$ + "- `f$(0)` = nome do arquivo (pode ter unidade e, no DOS 2, caminho)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(0)` = numero atribuido ao arquivo (use nas demais funcoes de arquivo)" + #CRLF$ + #CRLF$ +
    "No DOS 1, erro 3 = ja tem arquivos demais abertos (o maximo sai de .NB_GetInfo).",
    "numeroArquivo, erro = .NB_OpenFile(nome$)")

  NBHelp_Add(32, "Fechar um arquivo", "Acesso a disco", ".NB_CloseFile",
    "Sempre feche um arquivo que nao vai mais usar - senao dados escritos podem ficar presos nos " +
    "buffers internos do DOS, e a entrada de diretorio pode nao ser atualizada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = numero do arquivo",
    "erro = .NB_CloseFile(numeroArquivo)")

  NBHelp_Add(33, "Ler de um arquivo (S4)", "Acesso a disco", ".NB_ReadFile",
    "Le a partir da posicao atual do ponteiro do arquivo (avanca sozinho depois). Pra ler ate o " +
    "fim (ou o arquivo inteiro, se for menor que 16K), peca 16K (`tamanho=&H4000`) e ignore erro " +
    "1/199 (so significam fim de arquivo)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = numero do arquivo" + #CRLF$ + "- `p(2)` = segmento de destino" + #CRLF$ +
    "- `p(3)` = endereco de destino" + #CRLF$ + "- `p(4)` = numero de bytes a ler" + #CRLF$ +
    "- `p(6)` = <>0 avanca `p(3)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(7)` = bytes realmente lidos" + #CRLF$ + "- `p(3)` = `p(3)+p(4)` se `p(6)<>0`",
    "bytesLidos, novoEnderecoDestino, erro = .NB_ReadFile(numeroArquivo, segDestino, enderecoDestino, tamanho, incrementar)")

  NBHelp_Add(34, "Ler de um arquivo pra VRAM (S4)", "Acesso a disco", ".NB_ReadFileToVram",
    "Maximo `&H4000` bytes por chamada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = numero do arquivo" + #CRLF$ + "- `p(2)` = bloco de destino (VRAM)" + #CRLF$ +
    "- `p(3)` = endereco de destino" + #CRLF$ + "- `p(4)` = numero de bytes a ler (maximo `&H4000`)" + #CRLF$ +
    "- `p(6)` = <>0 avanca `p(3)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(7)` = bytes realmente lidos" + #CRLF$ + "- `p(2):p(3)` = `p(2):p(3)+p(4)` se `p(6)<>0`",
    "bytesLidos, novoBlocoDestino, novoEnderecoDestino, erro = .NB_ReadFileToVram(numeroArquivo, blocoDestino, enderecoDestino, tamanho, incrementar)")

  NBHelp_Add(35, "Ler setores do disco (S4)", "Acesso a disco", ".NB_ReadSectors",
    "Leitura bruta, direto por setor fisico (nao passa por arquivo). Sem leitura parcial: erro = " +
    "`p(7)` volta 0; sem erro = `p(7)` = `p(4)*512`. Maximo 32 setores (16K) por chamada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = unidade (0=A:,...,7=H:)" + #CRLF$ + "- `p(1)` = primeiro setor" + #CRLF$ +
    "- `p(2)` = segmento de destino" + #CRLF$ + "- `p(3)` = endereco de destino" + #CRLF$ +
    "- `p(4)` = numero de setores (maximo 32)" + #CRLF$ + "- `p(6)` = <>0 avanca `p(3)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(7)` = `p(4)*512` (0 se deu erro)" + #CRLF$ + "- `p(3)` = `p(3)+p(4)*512` se `p(6)<>0`",
    "bytesLidos, novoEnderecoDestino, erro = .NB_ReadSectors(unidade, primeiroSetor, segDestino, enderecoDestino, numSetores, incrementar)")

  NBHelp_Add(36, "Ler setores do disco pra VRAM (S4)", "Acesso a disco", ".NB_ReadSectorsToVram",
    "Maximo 32 setores (16K) por chamada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = unidade" + #CRLF$ + "- `p(1)` = primeiro setor" + #CRLF$ +
    "- `p(2)` = bloco de destino (VRAM)" + #CRLF$ + "- `p(3)` = endereco de destino" + #CRLF$ +
    "- `p(4)` = numero de setores (maximo 32)" + #CRLF$ + "- `p(6)` = <>0 avanca `p(3)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(7)` = `p(4)*512` (0 se deu erro)" + #CRLF$ + "- `p(2):p(3)` = `p(2):p(3)+p(4)*512` se `p(6)<>0`",
    "bytesLidos, novoBlocoDestino, novoEnderecoDestino, erro = .NB_ReadSectorsToVram(unidade, primeiroSetor, blocoDestino, enderecoDestino, numSetores, incrementar)")

  NBHelp_Add(37, "Escrever num arquivo (S4)", "Acesso a disco", ".NB_WriteFile",
    "Escreve a partir da posicao atual do ponteiro (avanca sozinho depois)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = numero do arquivo" + #CRLF$ + "- `p(2)` = segmento de origem" + #CRLF$ +
    "- `p(3)` = endereco de origem" + #CRLF$ + "- `p(4)` = numero de bytes a escrever" + #CRLF$ +
    "- `p(6)` = <>0 avanca `p(3)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(7)` = bytes realmente escritos" + #CRLF$ + "- `p(3)` = `p(3)+p(4)` se `p(6)<>0`",
    "bytesEscritos, novoEnderecoOrigem, erro = .NB_WriteFile(numeroArquivo, segOrigem, enderecoOrigem, tamanho, incrementar)")

  NBHelp_Add(38, "Escrever num arquivo a partir da VRAM (S4)", "Acesso a disco", ".NB_WriteFileFromVram",
    "Maximo `&H4000` bytes por chamada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = numero do arquivo" + #CRLF$ + "- `p(2)` = bloco de origem (VRAM)" + #CRLF$ +
    "- `p(3)` = endereco de origem" + #CRLF$ + "- `p(4)` = numero de bytes (maximo `&H4000`)" + #CRLF$ +
    "- `p(6)` = <>0 avanca `p(3)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(7)` = bytes realmente escritos" + #CRLF$ + "- `p(2):p(3)` = `p(2):p(3)+p(4)` se `p(6)<>0`",
    "bytesEscritos, novoBlocoOrigem, novoEnderecoOrigem, erro = .NB_WriteFileFromVram(numeroArquivo, blocoOrigem, enderecoOrigem, tamanho, incrementar)")

  NBHelp_Add(39, "Escrever setores do disco (S4)", "Acesso a disco", ".NB_WriteSectors",
    "Sem escrita parcial. Maximo 32 setores (16K) por chamada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = unidade" + #CRLF$ + "- `p(1)` = primeiro setor" + #CRLF$ +
    "- `p(2)` = segmento de origem" + #CRLF$ + "- `p(3)` = endereco de origem" + #CRLF$ +
    "- `p(4)` = numero de setores (maximo 32)" + #CRLF$ + "- `p(6)` = <>0 avanca `p(3)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(7)` = `p(4)*512` (0 se deu erro)" + #CRLF$ + "- `p(3)` = `p(3)+p(4)*512` se `p(6)<>0`",
    "bytesEscritos, novoEnderecoOrigem, erro = .NB_WriteSectors(unidade, primeiroSetor, segOrigem, enderecoOrigem, numSetores, incrementar)")

  NBHelp_Add(40, "Escrever setores do disco a partir da VRAM (S4)", "Acesso a disco", ".NB_WriteSectorsFromVram",
    "Maximo 32 setores (16K) por chamada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = unidade" + #CRLF$ + "- `p(1)` = primeiro setor" + #CRLF$ +
    "- `p(2)` = bloco de origem (VRAM)" + #CRLF$ + "- `p(3)` = endereco de origem" + #CRLF$ +
    "- `p(4)` = numero de setores (maximo 32)" + #CRLF$ + "- `p(6)` = <>0 avanca `p(3)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(7)` = `p(4)*512` (0 se deu erro)" + #CRLF$ + "- `p(2):p(3)` = `p(2):p(3)+p(4)*512` se `p(6)<>0`",
    "bytesEscritos, novoBlocoOrigem, novoEnderecoOrigem, erro = .NB_WriteSectorsFromVram(unidade, primeiroSetor, blocoOrigem, enderecoOrigem, numSetores, incrementar)")

  NBHelp_Add(41, "Preencher um arquivo com um byte (S4)", "Acesso a disco", ".NB_FillFile",
    "Maximo `&H4000` por chamada." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = numero do arquivo" + #CRLF$ + "- `p(1)` = byte" + #CRLF$ +
    "- `p(4)` = tamanho (maximo `&H4000`)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(7)` = bytes realmente escritos",
    "bytesEscritos, erro = .NB_FillFile(numeroArquivo, byte, tamanho)")

  NBHelp_Add(42, "Mover o ponteiro de um arquivo", "Acesso a disco", ".NB_SeekFile",
    "Pra saber a posicao atual sem mover: `metodo=1, offsetBaixo=0, offsetAlto=0`. Pro tamanho do " +
    "arquivo: `metodo=2, offsetBaixo=0, offsetAlto=0`." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = numero do arquivo" + #CRLF$ +
    "- `p(1)` = metodo: 0=a partir do inicio, 1=a partir da posicao atual, 2=a partir do fim" + #CRLF$ +
    "- `p(2)`/`p(3)` = deslocamento com sinal, parte baixa/alta (16 bits cada)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(4)`/`p(5)` = nova posicao do ponteiro, parte baixa/alta",
    "novaPosBaixa, novaPosAlta, erro = .NB_SeekFile(numeroArquivo, metodo, offsetBaixo, offsetAlto)")

  NBHelp_Add(43, "Obter a unidade padrao e as disponiveis", "Acesso a disco", ".NB_GetDrives",
    "## Saida" + #CRLF$ +
    "- `p(0)` = unidade padrao (0=A:,...,7=H:)" + #CRLF$ +
    "- `p(1)` = vetor de bits das unidades disponiveis (bit 0 = A:, bit mais alto = H:)",
    "unidadePadrao, vetorUnidades, erro = .NB_GetDrives()")

  NBHelp_Add(44, "Definir a unidade padrao", "Acesso a disco", ".NB_SetDrive",
    "## Entrada" + #CRLF$ + "- `p(0)` = unidade a definir (0=A:,...,7=H:)" + #CRLF$ + #CRLF$ +
    "Erro 62 = unidade invalida (nao existe ou maior que 7).",
    "erro = .NB_SetDrive(unidade)")

  NBHelp_Add(45, "Obter informacoes de espaco em disco", "Acesso a disco", ".NB_GetDiskSpace",
    "Espaco livre em bytes = `p(1)*p(3)*512`; em K = `p(1)*p(3)/2` (e o mesmo trocando `p(3)` por " +
    "`p(2)` pro total)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = unidade (0=padrao,1=A:,...,8=H: - reparar que aqui e diferente!)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(1)` = setores por cluster" + #CRLF$ + "- `p(2)` = total de clusters (maximo 4096)" + #CRLF$ +
    "- `p(3)` = clusters livres",
    "setoresPorCluster, totalClusters, clustersLivres, erro = .NB_GetDiskSpace(unidade)")

  NBHelp_Add(46, "Obter o diretorio padrao (DOS 2)", "Acesso a disco", ".NB_GetDir",
    "So existe no DOS 2 (no DOS 1 sempre da erro 1). String devolvida nao tem letra de unidade nem " +
    "barra no inicio/fim; raiz = string vazia." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = unidade (0=padrao,1=A:,...,8=H: - reparar que aqui e diferente!)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `f$(0)` = diretorio padrao",
    "diretorio$, erro = .NB_GetDir(unidade)")

  NBHelp_Add(47, "Definir o diretorio padrao (DOS 2)", "Acesso a disco", ".NB_SetDir",
    "So existe no DOS 2. Nao muda a unidade padrao (use .NB_SetDrive pra isso)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `f$(0)` = unidade (opcional) + diretorio",
    "erro = .NB_SetDir(caminho$)")

  NBHelp_Add(48, "Obter o tamanho do RAM disk (DOS 2)", "Acesso a disco", ".NB_GetRamDiskSize",
    "So existe no DOS 2. Tamanho em K = resultado*16; 0 = RAM disk nao existe." + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(0)` = tamanho em segmentos de 16K",
    "tamanho16k, erro = .NB_GetRamDiskSize()")

  NBHelp_Add(49, "Criar o RAM disk (DOS 2)", "Acesso a disco", ".NB_CreateRamDisk",
    "So existe no DOS 2. Por padrao o NestorBASIC ja pegou todos os segmentos livres pra si ao " +
    "instalar - use .NB_SetSegmentCount pra liberar segmentos antes de chamar esta funcao. Se nao " +
    "houver o tamanho pedido mas der pra criar um menor, cria e nao da erro (so retorna o tamanho " +
    "real criado); se nao houver segmento nenhum, da erro." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = tamanho pedido em segmentos de 16K" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(0)` = tamanho realmente criado",
    "tamanhoCriado, erro = .NB_CreateRamDisk(tamanho16k)")

  NBHelp_Add(50, "Obter os atributos de um arquivo (DOS 2)", "Acesso a disco", ".NB_GetAttrByHandle / .NB_GetAttrByName",
    "So existe no DOS 2. No manual original e uma unica funcao (`p(0)=255` + `f$(0)` = nome pra " +
    "consultar por nome, ao inves de numero de arquivo ja aberto) - aqui virou dois wrappers " +
    "separados pra nao precisar lembrar do valor magico 255." + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = atributos: `R+2*H+4*S+8*V+16*D+32*A`",
    "atributos, erro = .NB_GetAttrByHandle(numeroArquivo)" + #CRLF$ +
    "atributos, erro = .NB_GetAttrByName(nome$)")

  NBHelp_Add(51, "Definir os atributos de um arquivo (DOS 2)", "Acesso a disco", ".NB_SetAttrByHandle / .NB_SetAttrByName",
    "So existe no DOS 2. So da pra mudar Sistema/Oculto/Somente leitura/Archive num arquivo (Oculto " +
    "num diretorio); tentar mudar qualquer outro atributo da erro. Nao da pra mudar pelo nome um " +
    "arquivo que ja esta aberto - use a versao por numero nesse caso." + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = atributos realmente definidos",
    "atributosFinal, erro = .NB_SetAttrByHandle(numeroArquivo, atributos)" + #CRLF$ +
    "atributosFinal, erro = .NB_SetAttrByName(nome$, atributos)")

  NBHelp_Add(52, "Interpretar um caminho (DOS 2)", "Acesso a disco", ".NB_ParsePath",
    "So existe no DOS 2. So trata a string (nao acessa o disco, nao muda unidade/diretorio padrao)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `f$(0)` = caminho a interpretar" + #CRLF$ +
    "- `p(10)` = <>0 se o caminho se refere a um rotulo de volume" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `f$(1)` = ultimo item do caminho" + #CRLF$ +
    "- `p(8)` = unidade logica (1=A:,...,8=H:)" + #CRLF$ +
    "- `p(9)` = posicao do ultimo item na string (0 se nao ha ultimo item)" + #CRLF$ +
    "- `p(0)` a `p(7)` = varios booleanos -1/0 (contem caracteres alem da unidade, tem diretorio, " +
    "tem unidade, tem nome de arquivo, tem extensao, ultimo item ambiguo, ultimo item e ponto/ponto-ponto, " +
    "ultimo item e ponto-ponto - todos 0 se `p(10)<>0`)",
    "ultimoItem$, unidadeLogica, erro = .NB_ParsePath(caminho$, ehVolume)")
EndProcedure

; --- Grupos: compressao grafica (53-54), execucao de programas BASIC em RAM
; (55-57), funcoes diversas (58-66), efeitos PSG (67-70), Moonblaster (71-79) ---
Procedure NBHelp_BuildDataTier2()
  NBHelp_Add(-1, "Compressao e descompressao grafica", "Compressao e descompressao grafica", "",
    "Formato de compressao Sunrise (o mesmo usado no logo da Sunrise): bytes nao repetidos " +
    "(`&B00nnnnnn` + n bytes), byte repetido ate 63 vezes (`&B01nnnnnn` + 1 byte), byte repetido " +
    "ate 16383 vezes (`&B10nnnnnn nnnnnnnn` + 1 byte) e marca de fim (`&HC0`). A (des)compressao " +
    "continua sozinha no proximo segmento quando enche o atual (funcoes 53/54).")

  NBHelp_Add(53, "Comprimir dados graficos", "Compressao e descompressao grafica", ".NB_CompressGraphics",
    "Comprime da VRAM pra um ou mais segmentos consecutivos de RAM - se encher um segmento, " +
    "continua sozinha no proximo (por isso segmento/endereco de destino podem voltar diferentes " +
    "do que foi passado). Nao suporta segmentos VRAM nem o 255 como destino." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = bloco de origem (VRAM)" + #CRLF$ + "- `p(1)` = endereco de origem" + #CRLF$ +
    "- `p(2)` = primeiro segmento de destino" + #CRLF$ + "- `p(3)` = endereco de destino" + #CRLF$ +
    "- `p(4)` = tamanho dos dados a comprimir" + #CRLF$ + "- `p(5)` = <>0 avanca origem" + #CRLF$ +
    "- `p(6)` = <>0 avanca destino" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(7)` = tamanho comprimido em RAM" + #CRLF$ + "- `p(8)` = numero de segmentos de RAM usados" + #CRLF$ +
    "- `p(0):p(1)` = `p(0):p(1)+p(4)` se `p(5)<>0`" + #CRLF$ + "- `p(2):p(3)` = endereco seguinte ao ultimo usado, se `p(6)<>0`" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ +
    "5 = os segmentos acabaram antes de terminar de comprimir todos os dados pedidos.",
    "tamanhoComprimido, segmentosUsados, novoBlocoOrigem, novoEndOrigem, novoSegDestino, novoEndDestino, erro = .NB_CompressGraphics(blocoOrigem, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)")

  NBHelp_Add(54, "Descomprimir dados graficos", "Compressao e descompressao grafica", ".NB_DecompressGraphics",
    "Descomprime de um ou mais segmentos consecutivos de RAM pra VRAM (mesma logica de continuar " +
    "sozinha no proximo segmento). Nao suporta segmentos VRAM nem o 255 como origem." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = bloco de destino (VRAM)" + #CRLF$ + "- `p(1)` = endereco de destino" + #CRLF$ +
    "- `p(2)` = primeiro segmento de origem" + #CRLF$ + "- `p(3)` = endereco de origem" + #CRLF$ +
    "- `p(5)` = <>0 avanca destino" + #CRLF$ + "- `p(6)` = <>0 avanca origem" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(7)` = tamanho descomprimido em VRAM" + #CRLF$ + "- `p(8)` = numero de segmentos de RAM usados" + #CRLF$ +
    "- `p(0):p(1)` = `p(0):p(1)+p(7)` se `p(5)<>0`" + #CRLF$ + "- `p(2):p(3)` = endereco seguinte ao ultimo usado, se `p(6)<>0`" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ +
    "6 = dado invalido encontrado, ou os segmentos acabaram sem achar a marca de fim.",
    "tamanhoDescomprimido, segmentosUsados, novoBlocoDestino, novoEndDestino, novoSegOrigem, novoEndOrigem, erro = .NB_DecompressGraphics(blocoDestino, endDestino, segOrigem, endOrigem, incDestino, incOrigem)")

  NBHelp_Add(-1, "Execucao de programas BASIC guardados em RAM", "Execucao de programas BASIC guardados em RAM", "",
    "Guardar programas BASIC inteiros num segmento e trocar de programa preservando variaveis " +
    "(funcoes 55 a 57). **Pre-requisito obrigatorio:** o endereco inicial dos programas BASIC " +
    "precisa ter sido trocado de `&H8000` pra `&H8003` ANTES de instalar o NestorBASIC - uma unica " +
    "vez, com `poke &Hf676,4:poke &H8003,0:new` (o ideal e fazer isso logo na primeira linha do " +
    "programa que tambem carrega o NestorBASIC, testando `if peek(&Hf676)<>4 then ...`).")

  NBHelp_Add(55, "Executar um programa BASIC guardado em RAM (S4)", "Execucao de programas BASIC guardados em RAM", ".NB_RunBasicProgram",
    "Se der certo, o programa atual NUNCA retorna daqui - o novo programa roda da linha 1, com as " +
    "variaveis numericas do programa atual preservadas (strings tambem, desde que estejam na area " +
    "de strings do BASIC - force isso com `c$=c$+" + Chr(34) + Chr(34) + "` antes de chamar, se precisar). So retorna " +
    "em caso de erro." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco inicial" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ +
    "-1 = segmento nao existe (ou e o 255)." + #CRLF$ +
    "-2 = RAM principal do BASIC insuficiente pro novo programa + variaveis existentes.",
    "erro = .NB_RunBasicProgram(segmento, endereco)")

  NBHelp_Add(56, "Ativar um programa BASIC guardado em RAM (S4)", "Execucao de programas BASIC guardados em RAM", ".NB_ActivateBasicProgram",
    "Igual a funcao 55, mas ao inves de rodar da linha 1, larga no modo direto (programa carregado " +
    "e pronto, mas parado). Se der certo tambem nunca retorna daqui; mesmos erros de 55." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco inicial",
    "erro = .NB_ActivateBasicProgram(segmento, endereco)")

  NBHelp_Add(57, "Salvar o programa BASIC ativo com cabecalho especial (S4)", "Execucao de programas BASIC guardados em RAM", ".NB_SaveBasicProgram",
    "Salva com o cabecalho que as funcoes 55/56 esperam pra depois carregar (com .NB_ReadFile, por " +
    "exemplo) num segmento e ativar/executar." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = byte salvo na primeira posicao do cabecalho (o NestorBASIC nao usa, livre pro programa)" + #CRLF$ +
    "- `f$(0)` = caminho + nome do arquivo" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(1)` = -1 se nao deu erro; senao, o numero do arquivo (ainda aberto) onde ocorreu o erro de " +
    "disco - feche com .NB_CloseFile antes de tentar de novo",
    "arquivoAberto, erro = .NB_SaveBasicProgram(byteCabecalho, nome$)")

  NBHelp_Add(-1, "Funcoes diversas", "Funcoes diversas", "",
    "Execucao de codigo de maquina (BIOS/SUB-BIOS/RAM/segmento), strings em segmento, modo piscante " +
    "da SCREEN 0 e interrupcao definida pelo usuario (funcoes 58 a 66).")

  NBHelp_Add(58, "Executar codigo de maquina (BIOS/SUB-BIOS/RAM/area de sistema)", "Funcoes diversas", ".NB_ExecCode",
    "`subBios=0` executa direto (BIOS, RAM principal via BLOAD, ou area de sistema como o hook " +
    "`&HFFCA`); `subBios<>0` chama via EXTROM (so enderecos ate `&H3FFF`). Devolve o registrador A e " +
    "as flags Cy/Z ja separadas do par AF de saida (mais convenientes que decompor na mao)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = 0 direto / <>0 via SUB-BIOS" + #CRLF$ + "- `p(1)` = endereco da rotina" + #CRLF$ +
    "- `p(2)` a `p(11)` = registradores de entrada: AF,BC,DE,HL,IX,IY,AF',BC',DE',HL'" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(2)` a `p(11)` = registradores de saida (mesma ordem)" + #CRLF$ +
    "- `p(12)` = registrador A" + #CRLF$ + "- `p(13)` = flag Cy (-1 se ligada)" + #CRLF$ +
    "- `p(14)` = flag Z (-1 se ligada)",
    "af, bc, de, hl, ix, iy, af2, bc2, de2, hl2, a, cy, z, erro = .NB_ExecCode(subBios, endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)")

  NBHelp_Add(59, "Executar codigo de maquina guardado num segmento de RAM", "Funcoes diversas", ".NB_ExecCodeInSegment",
    "A rotina precisa estar montada no intervalo `&H8000`-`&HBFFF` (o segmento e trocado pra " +
    "pagina 2 antes de chamar). Mesmos registradores da funcao 58. Nao suporta segmentos VRAM nem " +
    "o 255." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco da rotina" + #CRLF$ +
    "- `p(2)` a `p(11)` = registradores de entrada" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` a `p(14)` = registradores de saida + A + Cy + Z (igual a funcao 58)" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "-1 = segmento invalido.",
    "af, bc, de, hl, ix, iy, af2, bc2, de2, hl2, a, cy, z, erro = .NB_ExecCodeInSegment(segmento, endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)")

  NBHelp_Add(60, "Imprimir uma string em modo grafico", "Funcoes diversas", ".NB_PrintGraphic",
    "So funciona em SCREEN 5 a 11 - equivalente a `PRINT#1,texto$` com `OPEN" + Chr(34) + "GRP:" + Chr(34) + "AS#1` ja " +
    "feito, mas compativel com TurboBASIC. Fora dessas SCREENs nao faz nada, sem erro. Maximo 80 " +
    "caracteres; nao pode ter o caractere 0 (`chr$(0)`)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `f$(0)` = string a imprimir",
    "erro = .NB_PrintGraphic(texto$)")

  NBHelp_Add(61, "Guardar uma string num segmento", "Funcoes diversas", ".NB_StoreString",
    "Termina com um byte 0. Maximo 80 caracteres; nao pode ter o caractere 0." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `f$(0)` = string" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ +
    "- `p(2)` = <>0 avanca `p(1)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = `p(1)+len(f$(0))+1` se `p(2)<>0`",
    "novoEndereco, erro = .NB_StoreString(texto$, segmento, endereco, incrementar)")

  NBHelp_Add(62, "Ler uma string guardada num segmento", "Funcoes diversas", ".NB_RestoreString",
    "Le ate achar um byte 0, ou 80 caracteres. Fora do TurboBASIC, um caractere 255 na string vira " +
    "34 (aspas) por causa de como o BASIC classico atribui strings." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + "- `p(2)` = <>0 avanca `p(1)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `f$(1)` = string lida" + #CRLF$ + "- `p(1)` = `p(1)+len(f$(1))+1` se `p(2)<>0`",
    "texto$, novoEndereco, erro = .NB_RestoreString(segmento, endereco, incrementar)")

  NBHelp_Add(63, "Inicializar o modo piscante da SCREEN 0", "Funcoes diversas", ".NB_InitBlink",
    "Habilita cores e tempos, e limpa a area de VRAM do blink. `tempoLigado`/`tempoDesligado` (0 a " +
    "15) ambos 0 so limpa a area, sem mudar cores/tempos. So funciona em SCREEN 0 com pelo menos 41 " +
    "colunas (senao erro -1, sem fazer nada)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = cor de frente do texto piscante" + #CRLF$ + "- `p(1)` = cor de fundo" + #CRLF$ +
    "- `p(2)` = tempo ligado (0-15)" + #CRLF$ + "- `p(3)` = tempo desligado (0-15)",
    "erro = .NB_InitBlink(corFrente, corFundo, tempoLigado, tempoDesligado)")

  NBHelp_Add(64, "Criar ou apagar um bloco piscante", "Funcoes diversas", ".NB_SetBlinkBlock",
    "Chame .NB_InitBlink antes. So funciona em SCREEN 0 com pelo menos 41 colunas (nao faz nada, " +
    "sem erro, fora disso; mas da erro -1 se coluna/linha passarem de 79/27)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = 0 apaga / <>0 cria" + #CRLF$ + "- `p(1)` = coluna inicial (0-79)" + #CRLF$ +
    "- `p(2)` = linha inicial (0-27)" + #CRLF$ + "- `p(3)` = largura em colunas" + #CRLF$ +
    "- `p(4)` = altura em linhas" + #CRLF$ + "- `p(5)` = <>0 avanca `p(1)`" + #CRLF$ +
    "- `p(6)` = <>0 avanca `p(2)`" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = `p(1)+p(3)` se `p(5)<>0`" + #CRLF$ + "- `p(2)` = `p(2)+p(4)` se `p(6)<>0`",
    "novaColuna, novaLinha, erro = .NB_SetBlinkBlock(criar, coluna, linha, largura, altura, incColuna, incLinha)")

  NBHelp_Add(65, "Obter informacoes sobre interrupcoes", "Funcoes diversas", ".NB_GetInterruptInfo",
    "## Saida" + #CRLF$ +
    "- `p(0)` = -1 se algum processo de interrupcao esta ativo" + #CRLF$ +
    "- `p(1)` = -1 se a interrupcao do usuario esta ativa" + #CRLF$ +
    "- `p(2)`/`p(3)` = segmento/endereco da interrupcao do usuario (validos mesmo parada)" + #CRLF$ +
    "- `p(4)` = -1 se um efeito PSG esta tocando" + #CRLF$ + "- `p(5)` = -1 se uma musica esta tocando",
    "algumAtivo, interrupcaoAtiva, sfxTocando, musicaTocando, erro = .NB_GetInterruptInfo()")

  NBHelp_Add(66, "Definir ou parar a interrupcao do usuario", "Funcoes diversas", ".NB_SetUserInterrupt",
    "A rotina roda a 50/60Hz e precisa estar montada em `&H8000`-`&HBFFF` do segmento indicado." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = 0 para / 1 define e ativa / -1 inverte o estado atual" + #CRLF$ +
    "- `p(1)` = segmento (ignorado se `p(0)<>1`)" + #CRLF$ + "- `p(2)` = endereco (ignorado se `p(0)<>1`)" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "7 = valor invalido em `p(0)`." + #CRLF$ + "-1 = segmento invalido/VRAM/255.",
    "erro = .NB_SetUserInterrupt(acao, segmento, endereco)")

  NBHelp_Add(-1, "Efeitos sonoros PSG", "Efeitos sonoros PSG", "",
    "Efeitos sonoros criados no editor SEE v3.xx, de Fuzzy Logic (uso comercial tem uma pequena " +
    "taxa aos autores - ver manual original, apendice 4). Funcoes 67 a 70.")

  NBHelp_Add(67, "Obter informacoes sobre os efeitos PSG", "Efeitos sonoros PSG", ".NB_GetSfxInfo",
    "So valido depois de .NB_InitSfxSet. Nunca retorna erro." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = novo volume maximo (-1 = nao muda; >15 vira 15)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(1)` = -1 se algum efeito esta tocando" + #CRLF$ +
    "- `p(2)`/`p(3)` = numero/prioridade do efeito tocando (ou do ultimo tocado)" + #CRLF$ +
    "- `p(4)`/`p(5)` = segmento/endereco do conjunto de efeitos" + #CRLF$ +
    "- `p(6)` = numero do maior efeito definido" + #CRLF$ + "- `p(7)` = volume maximo",
    "tocando, numeroEfeito, volumeMaximoAtual, erro = .NB_GetSfxInfo(volumeMaximo)")

  NBHelp_Add(68, "Inicializar um conjunto de efeitos PSG", "Efeitos sonoros PSG", ".NB_InitSfxSet",
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "8 = formato invalido (nao criado pelo editor SEE v3.xx)." + #CRLF$ + "-1 = segmento invalido/VRAM/255.",
    "erro = .NB_InitSfxSet(segmento, endereco)")

  NBHelp_Add(69, "Tocar um efeito sonoro PSG", "Efeitos sonoros PSG", ".NB_PlaySfx",
    "Se ja tiver outro efeito tocando: prioridade igual, ou o novo com prioridade alta, o antigo " +
    "para e o novo toca; o antigo com prioridade alta e o novo baixa, o antigo continua (erro 11)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = numero do efeito" + #CRLF$ + "- `p(1)` = prioridade (0=baixa, <>0=alta)" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ +
    "9 = efeito nao definido (trilha OFF no editor)." + #CRLF$ +
    "10 = efeito nao existe (numero maior que o maximo)." + #CRLF$ +
    "11 = outro efeito de prioridade maior ja esta tocando.",
    "erro = .NB_PlaySfx(efeito, prioridade)")

  NBHelp_Add(70, "Parar o efeito sonoro PSG", "Efeitos sonoros PSG", ".NB_StopSfx",
    "Para o efeito em execucao e silencia o PSG. Nunca retorna erro.",
    "erro = .NB_StopSfx()")

  NBHelp_Add(-1, "Tocador Moonblaster", "Tocador Moonblaster", "",
    "NestorBASIC inclui os tocadores Moonblaster 1.4 e Moonblaster Wave 1.05 (funcoes 71 a 79). O " +
    "tocador precisa ser carregado explicitamente (nao acontece sozinho ao instalar o NestorBASIC) " +
    "e ocupa o segmento 5 (so existe se o segmento 5 existir e for do mapper primario).")

  NBHelp_Add(71, "Carregar/inicializar ou desinstalar o tocador (S4)", "Tocador Moonblaster", ".NB_LoadPlayer",
    "acao 3 (autodetectar) carrega o Wave se achar Moonsound, senao o 1.4. Num Turbo-R, se trocar " +
    "de processador (Z80/R800) depois de carregado, chame de novo pra carregar a versao certa." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = 0 Moonblaster 1.4 / 1 Moonblaster Wave 1.05 / 3 autodetectar / -1 desinstalar" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(0)` = tocador carregado (0, 1 ou -1)" + #CRLF$ +
    "- `p(1)` = -1 se nao deu erro; senao, numero do arquivo NBASIC.BIN (ainda aberto) onde ocorreu " +
    "o erro de disco - feche com .NB_CloseFile antes de tentar de novo" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "-1 = segmento 5 nao existe ou nao e do mapper primario.",
    "tocadorCarregado, arquivoAberto, erro = .NB_LoadPlayer(acao)")

  NBHelp_Add(72, "Obter informacoes sobre a musica tocando", "Tocador Moonblaster", ".NB_GetMusicInfo",
    "`p(12)=0` se nenhum tocador foi carregado (os demais resultados, exceto deteccao de chips de " +
    "som, ficam invalidos nesse caso). `f$(0)`/`f$(1)` so valem se `p(0)<>0`. Nunca retorna erro." + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(0)` = -1 se uma musica esta tocando ou pausada" + #CRLF$ +
    "- `p(1)`/`p(2)` = -1 se e Moonblaster 1.4 / Moonblaster Wave" + #CRLF$ +
    "- `p(4)` = -1 se pausada" + #CRLF$ +
    "- `p(5)`/`p(6)` = segmento/endereco da musica tocando (ou da ultima tocada)" + #CRLF$ +
    "- `p(7)`/`p(8)` = posicao/passo atual (0-15)" + #CRLF$ +
    "- `p(9)`/`p(10)`/`p(11)` = -1 se detectou MSX-MUSIC/MSX-AUDIO/OPL4" + #CRLF$ +
    "- `p(12)` = -1 se ha um tocador inicializado" + #CRLF$ +
    "- `p(13)` = tocador instalado (0=Moonblaster 1.4, 1=Wave - so vale se `p(12)=-1`)" + #CRLF$ +
    "- `f$(0)` = nome da musica (sempre 40 caracteres na 1.4, 50 na Wave)" + #CRLF$ +
    "- `f$(1)` = samplekit/wavekit carregado quando a musica foi salva (maiusculas, sem extensao; " +
    "NONE se nao tinha nenhum)",
    "tocando, pausada, nomeMusica$, erro = .NB_GetMusicInfo()")

  NBHelp_Add(73, "Habilitar/desabilitar os chips de som", "Tocador Moonblaster", ".NB_SetSoundChips",
    "So tem efeito na proxima musica tocada ou apos parar/reiniciar a atual." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = 0 so consultar / 1 aplicar `p(1)`-`p(3)` / 2 habilitar todos os encontrados" + #CRLF$ +
    "- `p(1)`/`p(2)`/`p(3)` = MSX-MUSIC/MSX-AUDIO/OPL4: 0=nao mexe, 1=desabilita, 2=habilita, -1=inverte" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(4)`/`p(5)`/`p(6)` = MSX-MUSIC/MSX-AUDIO/OPL4: 0=nao encontrado, 1=encontrado mas desabilitado, 2=habilitado" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "7 = parametro invalido." + #CRLF$ + "12 = tocador nao instalado.",
    "statusMsxMusic, statusMsxAudio, statusOpl4, erro = .NB_SetSoundChips(acao, msxMusica, msxAudio, opl4)")

  NBHelp_Add(74, "Comecar a tocar uma musica Moonblaster", "Tocador Moonblaster", ".NB_PlayMusic",
    "Moonblaster Wave pode ocupar ate 3 segmentos consecutivos." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = segmento" + #CRLF$ + "- `p(1)` = endereco inicial" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ +
    "-1 = segmento invalido/VRAM/255." + #CRLF$ + "12 = tocador nao inicializado." + #CRLF$ +
    "13 = musica salva em modo EDIT (nao da pra tocar), ou sem musica Moonblaster Wave valida no endereco." + #CRLF$ +
    "14 = ja tem outra musica tocando.",
    "erro = .NB_PlayMusic(segmento, endereco)")

  NBHelp_Add(75, "Parar a musica", "Tocador Moonblaster", ".NB_StopMusic",
    "Para a musica tocando e silencia os chips de som. Nunca retorna erro (nao faz nada se nao " +
    "tiver musica tocando/tocador nao inicializado).",
    "erro = .NB_StopMusic()")

  NBHelp_Add(76, "Pausar/continuar a musica", "Tocador Moonblaster", ".NB_PauseMusic",
    "## Entrada" + #CRLF$ + "- `p(0)` = 0 pausa / 1 continua / -1 inverte o estado atual" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "7 = parametro invalido (nao faz nada, sem erro, se nao tiver musica " +
    "tocando/pausada ou tocador nao inicializado).",
    "erro = .NB_PauseMusic(acao)")

  NBHelp_Add(77, "Fade-out da musica", "Tocador Moonblaster", ".NB_FadeMusic",
    "Delay = ciclos de 1/50 ou 1/60s entre passos do fade - quanto menor, mais rapido. Ao terminar " +
    "(volume chega a zero), a musica para sozinha. Nunca retorna erro." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = 0 so consultar / -1 pausa o fade / 1..254 inicia/continua com esse delay" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = -1 se esta fazendo fade" + #CRLF$ + "- `p(2)` = delay atual (-1 se pausado)",
    "fazendoFade, delayAtual, erro = .NB_FadeMusic(delay)")

  NBHelp_Add(78, "Carregar um samplekit Music Module (S4)", "Tocador Moonblaster", ".NB_LoadSamplekit",
    "Formato Moonblaster: 56 bytes de cabecalho + 32K de amostras. Le de um arquivo ja aberto, na " +
    "posicao atual do ponteiro. Se o retorno vier maior que 16K, so os primeiros 16K foram pra RAM " +
    "de amostras; 32824 nao cabe em inteiro e volta como -32712 (limite do BASIC). Nao faz nada " +
    "(sem erro) se o tocador nao foi inicializado ou nao ha Music Module." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = numero do arquivo (ja aberto)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(7)` = numero de bytes lidos",
    "bytesLidos, erro = .NB_LoadSamplekit(numeroArquivo)")

  NBHelp_Add(79, "Carregar um wavekit Moonsound (S4)", "Tocador Moonblaster", ".NB_LoadWavekit",
    "Precisa estar salvo em modo USER (senao erro 15). Le de um arquivo ja aberto, na posicao " +
    "atual do ponteiro. Nao faz nada (sem erro) se o tocador Wave nao foi inicializado ou nao ha " +
    "Moonsound." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = numero do arquivo (ja aberto)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(6)`/`p(7)` = numero de bytes lidos (32 bits: `p(6)*65536+p(7)`)" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "15 = sem wavekit valido nessa posicao do arquivo, ou nao esta em modo USER.",
    "bytesAlto, bytesBaixo, erro = .NB_LoadWavekit(numeroArquivo)")
EndProcedure

; --- Grupos: controle de uso de segmentos (80), NestorMan/InterNestor Suite/Lite (81-86) ---
Procedure NBHelp_BuildDataTier3()
  NBHelp_Add(-1, "Controle de uso de segmentos", "Controle de uso de segmentos", "",
    "Consultar/limitar quantos segmentos o proprio NestorBASIC reserva pra si (funcao 80) - " +
    "importante quando outros programas residentes (RAM disk do DOS 2, NestorMan, InterNestor " +
    "Suite) tambem precisam alocar segmentos.")

  NBHelp_Add(80, "Obter/definir o numero de segmentos alocados", "Controle de uso de segmentos", ".NB_SetSegmentCount",
    "Se pedir menos de 6, o NestorBASIC usa 5 mesmo assim (ou 6 se o tocador Moonblaster estiver " +
    "carregado); se pedir mais que o disponivel, aloca o maximo possivel (ate 247). Funciona no " +
    "DOS 1 e no DOS 2, mas so faz sentido de verdade no DOS 2 (no DOS 1 so mexe em variaveis " +
    "internas, sem liberar/reservar nada de fato). Nunca retorna erro." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ + "- `p(0)` = numero de segmentos pedido (0 = so consultar, sem mudar nada)" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(0)` = numero de segmentos alocados apos a chamada" + #CRLF$ +
    "- `p(1)` = numero maximo de segmentos que podem ser alocados",
    "segmentosAlocados, segmentosMaximo, erro = .NB_SetSegmentCount(numSegmentos)")

  NBHelp_Add(-1, "NestorMan e InterNestor Suite/Lite", "NestorMan e InterNestor Suite/Lite", "",
    "Interacao com o NestorMan (gerenciador dinamico de memoria residente do MSX-DOS 2), " +
    "InterNestor Suite (pilha TCP/IP do MSX-DOS 2) e InterNestor Lite (pilha TCP/IP do MSX-DOS " +
    "1/2), se estiverem instalados (funcoes 81 a 86). Cada um tem manual proprio, disponivel em " +
    "http://msx.konamiman.com - o NestorBASIC so da o meio de chamar/trocar dados com eles.")

  NBHelp_Add(81, "Informacoes sobre NestorMan/InterNestor Suite", "NestorMan e InterNestor Suite/Lite", ".NB_GetNestorManInfo",
    "Nunca retorna erro." + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ +
    "- `p(0)` = 0 NestorMan nao instalado / 1 NestorMan instalado / 3 NestorMan e InterNestor Suite instalados" + #CRLF$ +
    "- `p(1)` a `p(4)` = segmento NestorMan de cada modulo do InterNestor Suite 1 a 4 (so validos se `p(0)=3`)" + #CRLF$ +
    "- `p(5)` = segmento NestorMan do segmento 4 do NestorBASIC (usado como buffer intermediario em " +
    "transferencias - so valido se `p(0)=1` ou `3`)",
    "status, segmentoNestorManSeg4, erro = .NB_GetNestorManInfo()")

  NBHelp_Add(82, "Executar uma funcao do NestorMan", "NestorMan e InterNestor Suite/Lite", ".NB_CallNestorMan",
    "Chamada indireta via hook estendido da BIOS - equivalente a .NB_ExecCode com endereco `&HFFCA`. " +
    "Mesmos registradores de entrada/saida de .NB_ExecCode." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = numero da funcao NestorMan" + #CRLF$ +
    "- `p(2)` a `p(11)` = registradores de entrada (AF,BC,DE,HL,IX,IY,AF',BC',DE',HL')" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` a `p(14)` = registradores de saida + A + Cy + Z" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ +
    "**Atencao:** o manual original se contradiz aqui - a secao de erros gerais diz que as funcoes " +
    "80, 81 e 82 nunca retornam erro, mas a descricao desta funcao especifica diz -1 se o NestorMan " +
    "nao estiver instalado. Teste na pratica se depender disso. De qualquer forma, nao verifica se " +
    "a funcao pedida realmente existe no NestorMan.",
    "af, bc, de, hl, ix, iy, af2, bc2, de2, hl2, a, cy, z, erro = .NB_CallNestorMan(funcao, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)")

  NBHelp_Add(83, "Copiar dados do NestorMan pro NestorBASIC", "NestorMan e InterNestor Suite/Lite", ".NB_CopyFromNestorMan",
    "segmento de destino nao pode ser o 1 (TurboBASIC) - copie primeiro pra outro segmento (ex.: o " +
    "4) se precisar." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = segmento de origem (NestorMan)" + #CRLF$ + "- `p(1)` = endereco de origem" + #CRLF$ +
    "- `p(2)` = segmento de destino (NestorBASIC)" + #CRLF$ + "- `p(3)` = endereco de destino" + #CRLF$ +
    "- `p(4)` = tamanho" + #CRLF$ + "- `p(5)` = <>0 avanca origem" + #CRLF$ + "- `p(6)` = <>0 avanca destino" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = `p(1)+p(4)` se `p(5)<>0`" + #CRLF$ + "- `p(3)` = `p(3)+p(4)` se `p(6)<>0`" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "-1 = segmento invalido.",
    "novoEndOrigem, novoEndDestino, erro = .NB_CopyFromNestorMan(segOrigemNestorMan, endOrigem, segDestino, endDestino, tamanho, incOrigem, incDestino)")

  NBHelp_Add(84, "Copiar dados do NestorBASIC pro NestorMan", "NestorMan e InterNestor Suite/Lite", ".NB_CopyToNestorMan",
    "segmento de origem nao pode ser o 1 (TurboBASIC)." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = segmento de origem (NestorBASIC)" + #CRLF$ + "- `p(1)` = endereco de origem" + #CRLF$ +
    "- `p(2)` = segmento de destino (NestorMan)" + #CRLF$ + "- `p(3)` = endereco de destino" + #CRLF$ +
    "- `p(4)` = tamanho" + #CRLF$ + "- `p(5)` = <>0 avanca origem" + #CRLF$ + "- `p(6)` = <>0 avanca destino" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(1)` = `p(1)+p(4)` se `p(5)<>0`" + #CRLF$ + "- `p(3)` = `p(3)+p(4)` se `p(6)<>0`" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "-1 = segmento invalido.",
    "novoEndOrigem, novoEndDestino, erro = .NB_CopyToNestorMan(segOrigem, endOrigem, segDestinoNestorMan, endDestino, tamanho, incOrigem, incDestino)")

  NBHelp_Add(85, "Executar uma rotina do InterNestor Suite", "NestorMan e InterNestor Suite/Lite", ".NB_CallInterNestorSuite",
    "Pra ler/escrever as constantes/variaveis de configuracao dos modulos, use " +
    ".NB_GetNestorManInfo (segmento NestorMan de cada modulo) e depois " +
    ".NB_CopyFromNestorMan/.NB_CopyToNestorMan. Mesmos registradores de .NB_ExecCode." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(0)` = numero do modulo (1 a 4)" + #CRLF$ + "- `p(1)` = endereco da rotina" + #CRLF$ +
    "- `p(2)` a `p(11)` = registradores de entrada" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` a `p(14)` = registradores de saida + A + Cy + Z" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "-1 = InterNestor Suite nao instalado, ou numero de modulo invalido.",
    "af, bc, de, hl, ix, iy, af2, bc2, de2, hl2, a, cy, z, erro = .NB_CallInterNestorSuite(modulo, endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)")

  NBHelp_Add(86, "Executar uma rotina do InterNestor Lite", "NestorMan e InterNestor Suite/Lite", ".NB_CallInterNestorLite",
    "So existe uma instancia (sem selecao de modulo). Pra checar se esta instalado sem chamar essa " +
    "rotina: `p(0)=0:p(1)=&Hffca:p(2)=0:p(4)=&H2203:e=usr(58):if p(12)=0 then` (nao instalado) - " +
    "equivalente a usar .NB_ExecCode direto e olhar o registrador A devolvido. Mesmos registradores " +
    "de .NB_ExecCode." + #CRLF$ + #CRLF$ +
    "## Entrada" + #CRLF$ +
    "- `p(1)` = endereco da rotina (ver o manual do InterNestor Lite pra lista)" + #CRLF$ +
    "- `p(2)` a `p(11)` = registradores de entrada" + #CRLF$ + #CRLF$ +
    "## Saida" + #CRLF$ + "- `p(2)` a `p(14)` = registradores de saida + A + Cy + Z" + #CRLF$ + #CRLF$ +
    "## Erros" + #CRLF$ + "-1 = InterNestor Lite nao instalado.",
    "af, bc, de, hl, ix, iy, af2, bc2, de2, hl2, a, cy, z, erro = .NB_CallInterNestorLite(endereco, regAf, regBc, regDe, regHl, regIx, regIy, regAf2, regBc2, regDe2, regHl2)")
EndProcedure

; Converte Titulo/Grupo num "slug" de ancora Markdown (minusculas, so
; letras/numeros/hifen) - suficiente pro nosso texto, que ja evita acentos.
Procedure.s NBHelp_Slug(Text.s)
  Protected Raw.s = ReplaceString(LCase(Text), " ", "-")
  Protected Clean.s = "", i, Ch.s
  For i = 1 To Len(Raw)
    Ch = Mid(Raw, i, 1)
    If (Ch >= "a" And Ch <= "z") Or (Ch >= "0" And Ch <= "9") Or Ch = "-"
      Clean + Ch
    EndIf
  Next
  ProcedureReturn Clean
EndProcedure

; Exporta todos os topicos como um unico arquivo Markdown de verdade
; (docs/reference/nestorbasic.md) - mesma fonte de dados da janela de
; ajuda (NBHelp_Topics()), entao os dois nunca desalinham. Usa
; NBHelp_FullBody() (wrapper + chamada + corpo) pra cada topico, igual a
; janela de ajuda.
Procedure.b NBHelp_ExportMarkdown(Path.s)
  NBHelp_BuildData()

  Protected Text.s = "# NestorBASIC 1.11 - Referencia de funcoes" + #CRLF$ + #CRLF$
  Text + "Gerado a partir de `nestor/SRC/NBASIC/nbas111e.txt` (manual original, by Nestor Soriano / " +
         "Konami Man, 2004) e da mesma base de dados usada pela janela Ajuda -> Nestor Basic... do " +
         "editor. Wrappers Dignified `.NB_*` sao gerados por Arquivo -> Novo Nestor Basic..." + #CRLF$ + #CRLF$

  Text + "## Indice" + #CRLF$ + #CRLF$
  Protected LastGrupo.s = Chr(1) ; sentinela - garante que o 1o grupo real sempre entra no indice
  ForEach NBHelp_Topics()
    If NBHelp_Topics()\Grupo <> LastGrupo
      LastGrupo = NBHelp_Topics()\Grupo
      Text + "- [" + LastGrupo + "](#" + NBHelp_Slug(LastGrupo) + ")" + #CRLF$
    EndIf
  Next
  Text + #CRLF$

  LastGrupo = Chr(1)
  ForEach NBHelp_Topics()
    If NBHelp_Topics()\Grupo <> LastGrupo
      LastGrupo = NBHelp_Topics()\Grupo
      Text + "## " + LastGrupo + #CRLF$ + #CRLF$
    EndIf

    If NBHelp_Topics()\Numero >= 0
      Text + "### " + Str(NBHelp_Topics()\Numero) + " - " + NBHelp_Topics()\Titulo + #CRLF$ + #CRLF$
    ElseIf NBHelp_Topics()\Titulo <> LastGrupo
      Text + "### " + NBHelp_Topics()\Titulo + #CRLF$ + #CRLF$
    EndIf

    Text + NBHelp_FullBody(@NBHelp_Topics()) + #CRLF$ + #CRLF$
  Next

  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf
  WriteString(FileNum, Text, #PB_UTF8)
  CloseFile(FileNum)
  ProcedureReturn #True
EndProcedure
