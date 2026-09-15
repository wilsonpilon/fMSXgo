;
; ------------------------------------------------------------
;  Traducao (japones -> portugues) das 471 notas reais do arquivo de
;  exemplo original do SUPER-X ("SUPER-X.TNK", others/superx/ - arquivo de
;  terceiros, ja commitado no repositorio desde antes desta sessao, NAO
;  gitignored como modulos anteriores do SPEC chegaram a supor - ver achado
;  real/pendencia no modulo 45e) - docs/SPEC.md modulo 45e. Conteudo ESTATICO
;  (escrito a mao, traduzido do japones - katakana meia-largura, Shift-JIS -
;  decodificado fora do projeto com um script Python descartavel, nao faz
;  parte do build) - nao depende de Mamute_LoadNoteFile() (MamuteNotesData.pbi)
;  ter sido chamado, e' so' texto de Ajuda.
;
;  Pedido explicito do usuario: "adicione o conteudo destas notas no help
;  do Mamute Assembler na parte modo Super-X". Anotacoes de registrador
;  (padrao classico de referencia de BIOS Z80/MSX - I/entrada, O/saida,
;  R/registradores destruidos) mantidas sem traduzir onde apareciam no
;  original, por serem notacao tecnica padrao.
; ------------------------------------------------------------
;


Procedure MamuteHelp_BuildSuperXNotes()
  MamuteHelp_Add("SUPER-X - Notas do arquivo TNK", "SUPER-X - Notas",
    "**Notas do SUPER-X carregadas do arquivo de exemplo original** (" + Chr(34) + "SUPER-X.TNK" + Chr(34) + ", " +
    "docs/SPEC.md modulo 45e) - o SUPER-X guarda ate 512 anotacoes (endereco + classificacao + texto de " +
    "ate 60 caracteres) num arquivo separado carregavel com o comando " + Chr(34) + "iL" + Chr(34) + " (ainda " +
    "nao implementado no Mamute - fica pra uma sessao futura, fase F do modulo 45 do SPEC). O pacote " +
    "original do SUPER-X vem com 471 dessas 512 notas ja preenchidas, cobrindo a BIOS principal, a area " +
    "de trabalho (work area), os hooks de expansao e as portas de I/O do MSX - originalmente em japones " +
    "(katakana meia-largura, codificacao Shift-JIS de 1 byte). Os topicos ao lado sao a TRADUCAO pro " +
    "portugues dessas 471 notas originais, organizadas por tipo (mesma classificacao do proprio arquivo): " +
    "**BIOS** (130), **WORK** (224 - a area de trabalho do sistema), **DATA** (5), **PORT** (25) e " +
    "**HOOK** (87 - pontos de expansao/interceptacao da BIOS). Os tipos GERAL/MATH/KEY nao tem nenhuma " +
    "nota no arquivo de exemplo original." + #CRLF$ + #CRLF$ +
    "O carregador nativo (`Mamute_LoadNoteFile()`, `editor/assemblers/MamuteNotesData.pbi`) ja existe e " +
    "foi verificado contra o arquivo real - ainda NAO e' chamado automaticamente por nenhum comando do " +
    "`MON>` (o `SUPER-X.TNK` original e' arquivo de terceiros, nao faz parte do projeto nem de `dist/`) - " +
    "os topicos abaixo sao o CONTEUDO das notas, nao uma tela do Mamute rodando.")

  MamuteHelp_Add("SUPER-X - Notas BIOS (1/2)", "SUPER-X - Notas",
    "**0000H** - Verifica a RAM e configura o slot de RAM do sistema." + #CRLF$ +
    "**0008H** - Verifica se o caractere em (HL) e' o especificado. Se diferente: Syntax error. Se igual: salta para 0010H." + #CRLF$ +
    "**000CH** - Le 1 byte do endereco (HL) no slot indicado por A. Interrupcoes ficam desabilitadas durante a chamada." + #CRLF$ +
    "**0010H** - Extrai um caractere (ou token) do texto do BASIC." + #CRLF$ +
    "**0014H** - Escreve o byte E no endereco (HL) do slot indicado por A. Interrupcoes ficam desabilitadas durante a chamada." + #CRLF$ +
    "**0018H** - Envia A para o dispositivo em uso no momento." + #CRLF$ +
    "**001CH** - Chama (IX) no slot especificado pelos 8 bits superiores de IY." + #CRLF$ +
    "**0020H** - Compara o conteudo de HL e DE. HL=DE ativa a flag Z; HL<DE ativa a flag C." + #CRLF$ +
    "**0024H** - A partir dos 2 bits superiores de HL, retorna a pagina correspondente ao slot indicado por A." + #CRLF$ +
    "**0028H** - Devolve o tipo do DAC (acumulador decimal)." + #CRLF$ +
    "**0030H** - Chamada inter-slot pelo metodo: RST 30H, DB slot, DW endereco." + #CRLF$ +
    "**0038H** - Executa a rotina de interrupcao do timer." + #CRLF$ +
    "**003BH** - Inicializa o dispositivo." + #CRLF$ +
    "**003EH** - Inicializa o conteudo das teclas de funcao." + #CRLF$ +
    "**0041H** - Desabilita a exibicao de tela - o processamento fica um pouco mais rapido." + #CRLF$ +
    "**0044H** - Exibicao da tela." + #CRLF$ +
    "**0047H** - Escreve o dado B no registrador C do VDP." + #CRLF$ +
    "**004AH** - Le (HL) da VRAM para A. Endereco da VRAM valido so ate 14 bits." + #CRLF$ +
    "**004DH** - Escreve A na VRAM(HL). Endereco valido so ate 14 bits." + #CRLF$ +
    "**0050H** - Define o endereco HL no VDP e coloca-o em estado de leitura. Endereco valido ate 14 bits." + #CRLF$ +
    "**0053H** - Define o endereco HL no VDP e coloca-o em estado de escrita. Endereco valido ate 14 bits." + #CRLF$ +
    "**0056H** - Preenche BC bytes a partir de VRAM(HL) com A. Endereco valido ate 14 bits." + #CRLF$ +
    "**0059H** - Transfere BC bytes de VRAM(HL) para a memoria (DE). Endereco totalmente valido." + #CRLF$ +
    "**005CH** - Transfere BC bytes da memoria (HL) para VRAM(DE). Endereco totalmente valido." + #CRLF$ +
    "**005FH** - Muda o modo de tela em (FCAFH). Nao inicializa a paleta." + #CRLF$ +
    "**0062H** - Muda as cores da tela - 3 bytes a partir de (F3E9H): cor de frente, fundo e borda." + #CRLF$ +
    "**0066H** - Executa a rotina de tratamento do NMI (Non Maskable Interrupt)." + #CRLF$ +
    "**0069H** - Inicializa todos os sprites." + #CRLF$ +
    "**006CH** - Inicializa a tela no modo TEXT1 (40*24). Nao inicializa a paleta." + #CRLF$ +
    "**006FH** - Inicializa a tela no modo GRAPHIC1 (32*24). Nao inicializa a paleta." + #CRLF$ +
    "**0072H** - Inicializa a tela no modo de alta resolucao grafica. Nao inicializa a paleta." + #CRLF$ +
    "**0075H** - Inicializa a tela no modo MULTI COLOR. Nao inicializa a paleta." + #CRLF$ +
    "**0078H** - Coloca so o VDP no modo TEXT1 (40*24)." + #CRLF$ +
    "**007BH** - Coloca so o VDP no modo GRAPHIC1 (32*24)." + #CRLF$ +
    "**007EH** - Coloca so o VDP no modo GRAPHIC2." + #CRLF$ +
    "**0081H** - Coloca so o VDP no modo MULTICOLOR." + #CRLF$ +
    "**0084H** - Coloca em HL o endereco da tabela geradora de sprites de A." + #CRLF$ +
    "**0087H** - Coloca em HL o endereco da tabela de atributos de sprites de A." + #CRLF$ +
    "**008AH** - Devolve o tamanho atual do sprite - A=tamanho (bytes); se 16*16, ativa a flag C." + #CRLF$ +
    "**008DH** - Exibe o caractere A na tela grafica. Se o modo for 5 ou superior, faz uma operacao logica em (FB02H)." + #CRLF$ +
    "**0090H** - Inicializa o PSG e define os valores iniciais para tocar musicas com PLAY." + #CRLF$ +
    "**0093H** - Escreve o dado E no registrador A do PSG." + #CRLF$ +
    "**0096H** - Le o valor do registrador A do PSG para A." + #CRLF$ +
    "**0099H** - Verifica se uma instrucao PLAY esta sendo executada em segundo plano; se nao, inicia o PLAY." + #CRLF$ +
    "**009CH** - Verifica o estado do buffer do teclado - se nao houver buffer, ativa a flag Z." + #CRLF$ +
    "**009FH** - Entrada de um caractere, esperando pela entrada - devolve o caractere em A." + #CRLF$ +
    "**00A2H** - Exibe o caractere A." + #CRLF$ +
    "**00A5H** - Envia o caractere A para a impressora - se falhar, ativa a flag C." + #CRLF$ +
    "**00A8H** - Verifica o estado da impressora - se ativar a flag Z, impressora NOT READY." + #CRLF$ +
    "**00ABH** - Verifica o codigo de grafico e converte o codigo." + #CRLF$ +
    "**00AEH** - Entrada de uma linha - devolve HL=buffer-1, C=flag de stop." + #CRLF$ +
    "**00B1H** - Entrada de uma linha, respondendo ao prompt - devolve HL=buffer-1, C=flag de stop." + #CRLF$ +
    "**00B4H** - Exibe "+Chr(34)+"? "+Chr(34)+" e depois chama INLIN (00B1H)." + #CRLF$ +
    "**00B7H** - Verifica se CTRL+STOP esta pressionado - se sim, ativa a flag C." + #CRLF$ +
    "**00C0H** - Toca um BEEP." + #CRLF$ +
    "**00C3H** - Limpa a tela." + #CRLF$ +
    "**00C6H** - Move o cursor - H=coordenada X, L=coordenada Y." + #CRLF$ +
    "**00C9H** - Exibe a tecla de funcao se estiver ativa; senao, apaga." + #CRLF$ +
    "**00CCH** - Apaga a exibicao das teclas de funcao." + #CRLF$ +
    "**00CFH** - Exibe as teclas de funcao." + #CRLF$ +
    "**00D2H** - Forca a tela para o modo texto." + #CRLF$ +
    "**00D5H** - Devolve o estado do joystick - A=STICK(A)." + #CRLF$ +
    "**00D8H** - Devolve o estado do botao de disparo - A=STRIG(A); se pressionado, A=FFH." + #CRLF$ +
    "**00DBH** - Devolve o estado do touch pad - A=PAD(A)." + #CRLF$ +
    "**00DEH** - Devolve o valor do paddle - A=PDL(A)." + #CRLF$ +
    "**00E1H** - Depois de ligar o motor do cassete, le o bloco de cabecalho - flag C=erro." + #CRLF$ +
    "**00E4H** - Le um dado da fita - devolve o dado em A; flag C=erro." + #CRLF$ +
    "**00E7H** - Para a leitura da fita." + #CRLF$ +
    "**00EAH** - Depois de ligar o motor do cassete, grava o bloco de cabecalho - A=tipo de cabecalho, flag C=erro." + #CRLF$ +
    "**00EDH** - Grava um dado na fita - A=dado; flag C=erro." + #CRLF$ +
    "**00F0H** - Para a gravacao na fita - flag C=erro." + #CRLF$ +
    "**00F3H** - Define o comportamento do motor do cassete conforme o valor de A." + #CRLF$ +
    "**0132H** - Muda o estado da luz de CAPS - A=0: apaga; A<>0: acende." + #CRLF$)

  MamuteHelp_Add("SUPER-X - Notas BIOS (2/2)", "SUPER-X - Notas",
    "**0135H** - Muda o estado da porta de som de 1 bit - A=0: OFF; A=1: ON." + #CRLF$ +
    "**0138H** - Le para A o valor enviado ao registrador de slot basico." + #CRLF$ +
    "**013BH** - Escreve A no registrador de slot basico." + #CRLF$ +
    "**013EH** - Le o registrador de status do VDP para A." + #CRLF$ +
    "**0141H** - Obtem em A o estado da linha especificada por A na matriz do teclado." + #CRLF$ +
    "**014AH** - Verifica se o dispositivo esta em operacao - se A<>0, esta em operacao." + #CRLF$ +
    "**014DH** - Envia o caractere A para a impressora." + #CRLF$ +
    "**0156H** - Limpa o buffer do teclado." + #CRLF$ +
    "**0159H** - Chamada inter-slot para uma rotina dentro do interpretador BASIC - IX=endereco." + #CRLF$ +
    "**015CH** - Chamada inter-slot para a SUB-ROM - IX=endereco, empilha IX ao mesmo tempo." + #CRLF$ +
    "**015FH** - Chamada inter-slot para a SUB-ROM - IX=endereco." + #CRLF$ +
    "**0168H** - Apaga (deleta) ate o fim da linha - H=coordenada X, L=coordenada Y." + #CRLF$ +
    "**016BH** - Preenche BC bytes a partir de VRAM(HL) com A, sem verificar o modo de tela." + #CRLF$ +
    "**016EH** - Define o endereco no VDP e coloca-o em estado de leitura - HL=endereco." + #CRLF$ +
    "**0171H** - Define o endereco no VDP e coloca-o em estado de escrita - HL=endereco." + #CRLF$ +
    "**0174H** - Le VRAM(HL) para A. Endereco totalmente valido (todos os bits)." + #CRLF$ +
    "**0177H** - Escreve A em VRAM(HL). Endereco totalmente valido (todos os bits)." + #CRLF$ +
    "**0180H** - Troca a CPU conforme o valor de A." + #CRLF$ +
    "**0183H** - Obtem o estado da CPU em A - A=0:Z80 1:ROM 2:DRAM." + #CRLF$ +
    "**0186H** - Reproducao de audio PCM." + #CRLF$ +
    "**0189H** - Gravacao de audio PCM." + #CRLF$ +
    "**0089H** - (SUB-ROM) Exibe A na tela grafica." + #CRLF$ +
    "**00C9H** - (SUB-ROM) Desenha uma caixa - (BC,DE) - ((FCB3H),(FCB5H)), (F3F2H), (FB02H)." + #CRLF$ +
    "**00CDH** - (SUB-ROM) Desenha uma caixa preenchida - (BC,DE) - ((FCB3H),(FCB5H)), (F3F2H), (FB02H)." + #CRLF$ +
    "**00D1H** - (SUB-ROM) Muda o modo de tela para A." + #CRLF$ +
    "**00D5H** - (SUB-ROM) Inicializa a tela no modo texto (40*24)." + #CRLF$ +
    "**00D9H** - (SUB-ROM) Inicializa a tela no modo texto (32*24)." + #CRLF$ +
    "**00DDH** - (SUB-ROM) Inicializa a tela no modo grafico de alta resolucao." + #CRLF$ +
    "**00E1H** - (SUB-ROM) Inicializa a tela no modo MULTI COLOR." + #CRLF$ +
    "**00E5H** - (SUB-ROM) Coloca o VDP no modo texto (40*24)." + #CRLF$ +
    "**00E9H** - (SUB-ROM) Coloca o VDP no modo texto (32*24)." + #CRLF$ +
    "**00EDH** - (SUB-ROM) Coloca o VDP no modo grafico de alta resolucao." + #CRLF$ +
    "**00F1H** - (SUB-ROM) Coloca o VDP no modo MULTI COLOR." + #CRLF$ +
    "**00F5H** - (SUB-ROM) Inicializa todos os sprites." + #CRLF$ +
    "**00F9H** - (SUB-ROM) Obtem em HL a tabela geradora de sprites de A." + #CRLF$ +
    "**00FDH** - (SUB-ROM) Obtem em HL o endereco da tabela de atributos de sprites de A." + #CRLF$ +
    "**0101H** - (SUB-ROM) Obtem o tamanho do sprite - A=tamanho; flag C=16*16." + #CRLF$ +
    "**0105H** - (SUB-ROM) Obtem o padrao do caractere - A=codigo do caractere, padrao devolvido em (FC40H)." + #CRLF$ +
    "**0109H** - (SUB-ROM) Escreve A em VRAM(HL)." + #CRLF$ +
    "**010DH** - (SUB-ROM) Le o valor de VRAM(HL) para A." + #CRLF$ +
    "**0111H** - (SUB-ROM) Muda as cores da tela - 3 bytes a partir de (F3E9H): cor de frente, fundo e borda." + #CRLF$ +
    "**0115H** - (SUB-ROM) Limpa a tela." + #CRLF$ +
    "**011DH** - (SUB-ROM) Exibe as teclas de funcao." + #CRLF$ +
    "**012DH** - (SUB-ROM) Escreve o dado B no registrador C do VDP." + #CRLF$ +
    "**0131H** - (SUB-ROM) Le o registrador A do VDP para A." + #CRLF$ +
    "**013DH** - (SUB-ROM) Troca de pagina - (FAF5H)=pagina de exibicao, (FAF6H)=pagina ativa." + #CRLF$ +
    "**0141H** - (SUB-ROM) Inicializacao da paleta." + #CRLF$ +
    "**0145H** - (SUB-ROM) Restaura a paleta a partir da VRAM." + #CRLF$ +
    "**0149H** - (SUB-ROM) Obtem o codigo de cor a partir da paleta - 4 bits superiores de B=vermelho, 4 bits inferiores de B=azul, 4 bits inferiores de C=verde." + #CRLF$ +
    "**014DH** - (SUB-ROM) Define a paleta - D=paleta; 4 bits superiores de A=vermelho, 4 bits inferiores de A=azul, 4 bits inferiores de E=verde." + #CRLF$ +
    "**017DH** - (SUB-ROM) Toca um BEEP." + #CRLF$ +
    "**0181H** - (SUB-ROM) Exibicao do prompt." + #CRLF$ +
    "**01ADH** - (SUB-ROM) Le o estado do mouse/light pen - A=configuracao na entrada, A=valor na saida." + #CRLF$ +
    "**01B5H** - (SUB-ROM) Muda o modo do VDP para A. A paleta e' inicializada." + #CRLF$ +
    "**01BDH** - (SUB-ROM) Exibe kanji na tela grafica - BC=codigo JIS, A=modo de exibicao." + #CRLF$ +
    "**01F5H** - (SUB-ROM) Le um dado do relogio - C=endereco da RAM do relogio, devolve A=dado lido." + #CRLF$ +
    "**01F9H** - (SUB-ROM) Escreve um dado no relogio - A=dado, C=endereco do relogio." + #CRLF$)

  MamuteHelp_Add("SUPER-X - Notas WORK (1/4)", "SUPER-X - Notas",
    "**F380H** - Rotina de leitura do slot basico. (5 bytes)" + #CRLF$ +
    "**F385H** - Rotina de escrita no slot basico. (7 bytes)" + #CRLF$ +
    "**F38CH** - Rotina de chamada inter-slot. (14 bytes)" + #CRLF$ +
    "**F39AH** - Endereco inicial do programa de maquina da funcao USR. Por padrao aponta para a rotina de erro. (20 bytes)" + #CRLF$ +
    "**F3AEH** - Largura de uma linha no SCREEN0 - definida pelo WIDTH do SCREEN0. [40] (1 byte)" + #CRLF$ +
    "**F3AFH** - Largura de uma linha no SCREEN1 - definida pelo WIDTH do SCREEN1. [29] (1 byte)" + #CRLF$ +
    "**F3B0H** - Largura de uma linha da tela atual. [29] (1 byte)" + #CRLF$ +
    "**F3B1H** - Numero de linhas da tela atual. [24] (1 byte)" + #CRLF$ +
    "**F3B2H** - Posicao horizontal quando os itens do comando PRINT sao separados por virgula. [14] (1 byte)" + #CRLF$ +
    "**F3B3H** - SCREEN0 - Pattern Name Table. [0000H] (2 bytes)" + #CRLF$ +
    "**F3B5H** - Nao utilizado. (2 bytes)" + #CRLF$ +
    "**F3B7H** - SCREEN0 - Pattern Generator Table. [0800H] (2 bytes)" + #CRLF$ +
    "**F3B9H** - Nao utilizado. (2 bytes)" + #CRLF$ +
    "**F3BBH** - Nao utilizado. (2 bytes)" + #CRLF$ +
    "**F3BDH** - SCREEN1 - Pattern Name Table. [1800H] (2 bytes)" + #CRLF$ +
    "**F3BFH** - SCREEN1 - Color Table. [2000H] (2 bytes)" + #CRLF$ +
    "**F3C1H** - SCREEN1 - Pattern Generator Table. [0000H] (2 bytes)" + #CRLF$ +
    "**F3C3H** - SCREEN1 - Sprite Attribute Table. [1B00H] (2 bytes)" + #CRLF$ +
    "**F3C5H** - SCREEN1 - Sprite Generator Table. [3800H] (2 bytes)" + #CRLF$ +
    "**F3C7H** - SCREEN2 - Pattern Name Table. [1800H] (2 bytes)" + #CRLF$ +
    "**F3C9H** - SCREEN2 - Color Table. [2000H] (2 bytes)" + #CRLF$ +
    "**F3CBH** - SCREEN2 - Pattern Generator Table. [0000H] (2 bytes)" + #CRLF$ +
    "**F3CDH** - SCREEN2 - Sprite Attribute Table. [1B00H] (2 bytes)" + #CRLF$ +
    "**F3CFH** - SCREEN2 - Sprite Generator Table. [3800H] (2 bytes)" + #CRLF$ +
    "**F3D1H** - SCREEN3 - Pattern Name Table. [0800H] (2 bytes)" + #CRLF$ +
    "**F3D3H** - Nao utilizado. (2 bytes)" + #CRLF$ +
    "**F3D5H** - SCREEN3 - Pattern Generator Table. [0000H] (2 bytes)" + #CRLF$ +
    "**F3D7H** - SCREEN3 - Sprite Attribute Table. [1B00H] (2 bytes)" + #CRLF$ +
    "**F3D9H** - SCREEN3 - Sprite Generator Table. [3800H] (2 bytes)" + #CRLF$ +
    "**F3DBH** - Key click switch - definido pelo <key click switch> do comando SCREEN. [1] (1 byte)" + #CRLF$ +
    "**F3DCH** - Coordenada Y do cursor. [1] (1 byte)" + #CRLF$ +
    "**F3DDH** - Coordenada X do cursor. [1] (1 byte)" + #CRLF$ +
    "**F3DEH** - Switch de exibicao das teclas de funcao - exibe se diferente de 0. [FFH] (1 byte)" + #CRLF$ +
    "**F3DFH** - Copia do registrador 0 do VDP. [0] (1 byte)" + #CRLF$ +
    "**F3E0H** - Copia do registrador 1 do VDP. [E0H] (1 byte)" + #CRLF$ +
    "**F3E1H** - Copia do registrador 2 do VDP. [0] (1 byte)" + #CRLF$ +
    "**F3E2H** - Copia do registrador 3 do VDP. [0] (1 byte)" + #CRLF$ +
    "**F3E3H** - Copia do registrador 4 do VDP. [0] (1 byte)" + #CRLF$ +
    "**F3E4H** - Copia do registrador 5 do VDP. [0] (1 byte)" + #CRLF$ +
    "**F3E5H** - Copia do registrador 6 do VDP. [0] (1 byte)" + #CRLF$ +
    "**F3E6H** - Copia do registrador 7 do VDP. [0] (1 byte)" + #CRLF$ +
    "**F3E7H** - Copia do status do VDP - no MSX2 ou superior, conteudo do registrador de status 0. [0] (1 byte)" + #CRLF$ +
    "**F3E8H** - Guarda o estado do botao de disparo do joystick. [FFH] (1 byte)" + #CRLF$ +
    "**F3E9H** - Cor de frente - definida pelo comando COLOR. [15] (1 byte)" + #CRLF$ +
    "**F3EAH** - Cor de fundo - definida pelo comando COLOR. [4] (1 byte)" + #CRLF$ +
    "**F3EBH** - Cor da borda - definida pelo comando COLOR. [7] (1 byte)" + #CRLF$ +
    "**F3ECH** - Usado internamente pelo comando CIRCLE. [JP 0000H/C3 00 00] (3 bytes)" + #CRLF$ +
    "**F3EFH** - Usado internamente pelo comando CIRCLE. [JP 0000H/C3 00 00] (3 bytes)" + #CRLF$ +
    "**F3F2H** - Codigo de cor da ultima exibicao grafica. [15] (1 byte)" + #CRLF$ +
    "**F3F3H** - Aponta para a fila usada durante a execucao do comando PLAY. [F959H] (2 bytes)" + #CRLF$ +
    "**F3F5H** - Usado internamente pelo interpretador BASIC. [255] (1 byte)" + #CRLF$ +
    "**F3F6H** - Intervalo de tempo do keyscan. [1] (1 byte)" + #CRLF$ +
    "**F3F7H** - Tempo ate o auto-repeat da tecla comecar. [50] (1 byte)" + #CRLF$ +
    "**F3F8H** - Aponta para o endereco onde a escrita no buffer de teclado acontece. [FBF0H] (2 bytes)" + #CRLF$ +
    "**F3FAH** - Aponta para o endereco onde a leitura do buffer de teclado acontece. [FBF0H] (2 bytes)" + #CRLF$ +
    "**F40BH** - 256/aspect ratio - definido pelo comando SCREEN para uso no comando CIRCLE. (2 bytes)" + #CRLF$ +
    "**F40DH** - 256*aspect ratio - definido pelo comando SCREEN para uso no comando CIRCLE. (2 bytes)" + #CRLF$ +
    "**F40FH** - Fim provisorio do programa para o comando RESUME NEXT. ["+Chr(34)+":"+Chr(34)+"] (5 bytes)" + #CRLF$ +
    "**F414H** - Area que guarda o numero do erro. (1 byte)" + #CRLF$ +
    "**F415H** - Posicao do cabecote da impressora. [0] (1 byte)" + #CRLF$ +
    "**F416H** - Flag de se deve enviar para a impressora. (1 byte)" + #CRLF$ +
    "**F417H** - Tipo de impressora - 0=impressora MSX; diferente de 0=nao e' impressora MSX. (1 byte)" + #CRLF$ +
    "**F418H** - Diferente de 0 quando estiver imprimindo em raw-mode. (1 byte)" + #CRLF$ +
    "**F419H** - Endereco do texto substituido pela funcao VAL. (2 bytes)" + #CRLF$ +
    "**F41BH** - Caractere substituido por 0 pela funcao VAL. (1 byte)" + #CRLF$ +
    "**F41CH** - Numero da linha do BASIC em execucao. (2 bytes)" + #CRLF$ +
    "**F41FH** - Crunch buffer - a partir de (F55EH), guarda o texto convertido para linguagem intermediaria. (318 bytes)" + #CRLF$ +
    "**F55DH** - Usado pelo comando INPUT. ["+Chr(34)+","+Chr(34)+"] (1 byte)" + #CRLF$ +
    "**F55EH** - Buffer onde ficam os caracteres digitados - a instrucao direta fica aqui em codigo ASCII. (258 bytes)" + #CRLF$ +
    "**F660H** - Evita que o buffer (F55E) transborde. (1 byte)" + #CRLF$ +
    "**F661H** - Posicao de cursor virtual usada internamente pelo BASIC. (1 byte)" + #CRLF$ +
    "**F662H** - Usado internamente pelo BASIC. (1 byte)" + #CRLF$ +
    "**F663H** - Usado para distinguir o tipo de variavel. (1 byte)" + #CRLF$ +
    "**F664H** - Indica se a palavra reservada guardada pode ser cruncheada. (1 byte)" + #CRLF$ +
    "**F665H** - Flag do comprimento do crunch. (1 byte)" + #CRLF$)

  MamuteHelp_Add("SUPER-X - Notas WORK (2/4)", "SUPER-X - Notas",
    "**F666H** - Guarda o endereco de texto usado pelo CHRGET. (2 bytes)" + #CRLF$ +
    "**F668H** - Guarda o token da constante depois de chamar o CHRGET. (1 byte)" + #CRLF$ +
    "**F669H** - Tipo da constante guardada. (1 byte)" + #CRLF$ +
    "**F66AH** - Valor da constante guardada. (8 bytes)" + #CRLF$ +
    "**F672H** - Endereco mais alto da memoria usada pelo BASIC. (2 bytes)" + #CRLF$ +
    "**F674H** - Endereco usado pelo BASIC como pilha (stack) - muda com o comando CLEAR. (2 bytes)" + #CRLF$ +
    "**F676H** - Endereco inicial da area de texto do BASIC. (2 bytes)" + #CRLF$ +
    "**F678H** - Endereco inicial da area livre do descritor de string temporario. [F67AH] (2 bytes)" + #CRLF$ +
    "**F67AH** - Area usada para NUMTEMP. (3*NUMTMP bytes)" + #CRLF$ +
    "**F698H** - Guarda o descritor de string do resultado da funcao de string. (3 bytes)" + #CRLF$ +
    "**F69BH** - Endereco inicial da area livre da regiao de strings. (2 bytes)" + #CRLF$ +
    "**F69DH** - Usado pela coleta de lixo (garbage collection) e pela funcao USR, entre outros. (2 bytes)" + #CRLF$ +
    "**F69FH** - Usado pela coleta de lixo. (2 bytes)" + #CRLF$ +
    "**F6A1H** - Guarda o proximo endereco do comando FOR. (2 bytes)" + #CRLF$ +
    "**F6A3H** - Numero da linha do DATA lido pela execucao do comando READ. (2 bytes)" + #CRLF$ +
    "**F6A5H** - Flag usado quando um array e' utilizado pela funcao USR, entre outros. (1 byte)" + #CRLF$ +
    "**F6A6H** - Flag usado pelo INPUT ou READ. (1 byte)" + #CRLF$ +
    "**F6A7H** - Area temporaria para o codigo de statement - usada para ponteiro de variavel, endereco de texto, etc. (2 bytes)" + #CRLF$ +
    "**F6A9H** - 0 se nao houver linha a converter; diferente de 0 se houver. (1 byte)" + #CRLF$ +
    "**F6AAH** - Flag de comando AUTO ativo/inativo - diferente de 0 = ativo; 0 = inativo. (1 byte)" + #CRLF$ +
    "**F6ABH** - Numero da ultima linha digitada. (2 bytes)" + #CRLF$ +
    "**F6ADH** - Incremento do numero de linha do comando AUTO. [10] (2 bytes)" + #CRLF$ +
    "**F6AFH** - Area que guarda o endereco do texto em execucao. (2 bytes)" + #CRLF$ +
    "**F6B1H** - Area que guarda a pilha (stack). (2 bytes)" + #CRLF$ +
    "**F6B3H** - Numero da linha onde ocorreu um erro. (2 bytes)" + #CRLF$ +
    "**F6B5H** - Numero da linha mais recente exibida na tela ou digitada, de alguma forma. (2 bytes)" + #CRLF$ +
    "**F6B7H** - Endereco do texto onde ocorreu o erro. (2 bytes)" + #CRLF$ +
    "**F6B9H** - Endereco do texto de destino quando ocorre um erro - definido pelo ON ERROR GOTO. (2 bytes)" + #CRLF$ +
    "**F6BBH** - Flag que indica se a rotina de erro esta em execucao - diferente de 0 = em execucao. (1 byte)" + #CRLF$ +
    "**F6BCH** - Uso temporario. (2 bytes)" + #CRLF$ +
    "**F6BEH** - Numero da linha interrompida, ou da ultima executada. (2 bytes)" + #CRLF$ +
    "**F6C0H** - Endereco do texto do proximo comando a ser executado. (2 bytes)" + #CRLF$ +
    "**F6C2H** - Endereco inicial das variaveis simples - ao executar NEW, e' definido como (F676H)+2. (2 bytes)" + #CRLF$ +
    "**F6C4H** - Endereco inicial da tabela de arrays. (2 bytes)" + #CRLF$ +
    "**F6C6H** - Ultimo endereco de memoria em uso como area de texto/variaveis. (2 bytes)" + #CRLF$ +
    "**F6C8H** - Endereco de texto do dado lido pela execucao do comando READ. (2 bytes)" + #CRLF$ +
    "**F6CAH** - Area para manter o tipo de variavel por letra inicial (DEFtype). (26 bytes)" + #CRLF$ +
    "**F6E4H** - Bloco de definicao anterior na pilha (usado pela coleta de lixo). (2 bytes)" + #CRLF$ +
    "**F6E6H** - Numero de bytes da tabela alvo de processamento. (2 bytes)" + #CRLF$ +
    "**F6E8H** - Tabela de definicao de parametros do alvo de processamento. PRMSIZ e' o numero de bytes do bloco de definicao." + #CRLF$ +
    "**F74CH** - Ponteiro do bloco de parametros anterior (usado pela coleta de lixo). [F6E4H] (2 bytes)" + #CRLF$ +
    "**F74EH** - Tamanho do bloco de parametros. (2 bytes)" + #CRLF$ +
    "**F750H** - Area para guardar parametros. (100 bytes)" + #CRLF$ +
    "**F7B4H** - Flag que indica se PARM1 ja foi pesquisado. (1 byte)" + #CRLF$ +
    "**F7B5H** - Fim da busca. (2 bytes)" + #CRLF$ +
    "**F7B7H** - 0 se nao houver funcao no alvo de processamento. (1 byte)" + #CRLF$ +
    "**F7B8H** - Area temporaria usada pela coleta de lixo. (2 bytes)" + #CRLF$ +
    "**F7BAH** - Quantidade de funcoes no alvo de processamento. (2 bytes)" + #CRLF$ +
    "**F7BCH** - Area temporaria que guarda o valor da primeira variavel do comando SWAP. (8 bytes)" + #CRLF$ +
    "**F7C4H** - Flag de trace - diferente de 0 = TRACE ON; 0 = TRACE OFF. (1 byte)" + #CRLF$ +
    "**F7C5H** - Usado internamente pelo mathpack. (43 bytes)" + #CRLF$ +
    "**F7F0H** - Usado ao converter um numero decimal (base 10) para ponto flutuante. (2 bytes)" + #CRLF$ +
    "**F7F2H** - Usado durante a execucao de uma sub-rotina auxiliar. (2 bytes)" + #CRLF$ +
    "**F7F4H** - Usado durante a execucao de uma sub-rotina auxiliar. (2 bytes)" + #CRLF$ +
    "**F7F6H** - DAC - area que define o valor alvo da operacao. (16 bytes)" + #CRLF$ +
    "**F806H** - Area de guarda de registradores para a multiplicacao decimal. (48 bytes)" + #CRLF$ +
    "**F836H** - Usado internamente pelo mathpack. (8 bytes)" + #CRLF$ +
    "**F83EH** - Usado internamente pelo mathpack. (8 bytes)" + #CRLF$ +
    "**F847H** - Area que define o valor a operar com o DAC (F7F6H) - ARG. (16 bytes)" + #CRLF$ +
    "**F857H** - Guarda o numero aleatorio mais recente em ponto flutuante duplo - definido pela funcao RND. (8 bytes)" + #CRLF$ +
    "**F85FH** - Valor maximo do numero de arquivo - definido por MAXFILES. (1 byte)" + #CRLF$ +
    "**F860H** - Endereco inicial da area de dados de arquivo. (2 bytes)" + #CRLF$ +
    "**F862H** - Buffer usado pelo interpretador BASIC no SAVE/LOAD. (2 bytes)" + #CRLF$ +
    "**F864H** - Endereco onde esta o dado de arquivo do arquivo em acesso. (2 bytes)" + #CRLF$ +
    "**F866H** - Valor diferente de 0 se o programa deve ser executado apos o LOAD. (1 byte)" + #CRLF$ +
    "**F866H** - Area de guarda do nome do arquivo. (11 bytes)" + #CRLF$ +
    "**F871H** - Area de guarda do nome do arquivo." + #CRLF$ +
    "**F87CH** - Valor diferente de 0 durante o load de um programa. (1 byte)" + #CRLF$ +
    "**F87DH** - Endereco final do programa de maquina a ser salvo. (2 bytes)" + #CRLF$)

  MamuteHelp_Add("SUPER-X - Notas WORK (3/4)", "SUPER-X - Notas",
    "**F87FH** - Area de guarda das strings das teclas de funcao. (16 chars * 10)" + #CRLF$ +
    "**F91FH** - Endereco da fonte de caracteres na ROM. (3 bytes)" + #CRLF$ +
    "**F922H** - Endereco base da Pattern Name Table atual. (2 bytes)" + #CRLF$ +
    "**F924H** - Endereco base da Pattern Generator Table atual. (2 bytes)" + #CRLF$ +
    "**F926H** - Endereco base da Sprite Generator Table atual. (2 bytes)" + #CRLF$ +
    "**F928H** - Endereco base da Sprite Attribute Table atual. (2 bytes)" + #CRLF$ +
    "**F92AH** - Usado internamente pela rotina grafica. (2 bytes)" + #CRLF$ +
    "**F92CH** - Usado internamente pela rotina grafica. (1 byte)" + #CRLF$ +
    "**F92DH** - Usado internamente pela rotina grafica. (2 bytes)" + #CRLF$ +
    "**F92FH** - Usado internamente pela rotina grafica. (2 bytes)" + #CRLF$ +
    "**F956H** - Aponta para o inicio da tabela de macro do PLAY ou do DRAW. (2 bytes)" + #CRLF$ +
    "**F958H** - Indicador PLAY/DRAW. (1 byte)" + #CRLF$ +
    "**F959H** - Tabela de filas. (24 bytes)" + #CRLF$ +
    "**F971H** - Usado por BCKQ. (4 bytes)" + #CRLF$ +
    "**F975H** - Fila de som/voz 1. (128 bytes)" + #CRLF$ +
    "**F9F5H** - Fila de som/voz 2. (128 bytes)" + #CRLF$ +
    "**FA75H** - Fila de som/voz 3. (128 bytes)" + #CRLF$ +
    "**FAF5H** - Numero da pagina de exibicao (display page). (1 byte)" + #CRLF$ +
    "**FAF6H** - Numero da pagina ativa (active page). (1 byte)" + #CRLF$ +
    "**FAF7H** - Guarda a porta de controle AV. (1 byte)" + #CRLF$ +
    "**FAF8H** - Endereco de slot da SUB-ROM. (1 byte)" + #CRLF$ +
    "**FAF9H** - Contador de caracteres no buffer, usado na conversao romaji-kana - valor 0<=n<=2. (1 byte)" + #CRLF$ +
    "**FAFAH** - Area que guarda os caracteres no buffer, usada na conversao romaji-kana. (1 byte)" + #CRLF$ +
    "**FAFCH** - Switch de modo da conversao romaji-kana, e o tamanho da VRAM. (1 byte)" + #CRLF$ +
    "**FAFDH** - Nao utilizado. (1 byte)" + #CRLF$ +
    "**FAFEH** - Guarda a coordenada X, presenca de requisicao de interrupcao da caneta otica, etc. (2 bytes)" + #CRLF$ +
    "**FB00H** - Guarda a coordenada Y. (2 bytes)" + #CRLF$ +
    "**FB02H** - Codigo de operacao logica. (1 byte)" + #CRLF$ +
    "**FB21H** - Tabela do numero de drives conectados ao slot da ROM de disco e do endereco do slot. (8 bytes)" + #CRLF$ +
    "**FBB0H** - Flag que habilita o warm start via [SHIFT+CTRL+GRAPH+tecla kana]. (1 byte)" + #CRLF$ +
    "**FBB1H** - Indica onde esta o texto do BASIC - 0=RAM; diferente de 0=na ROM. (1 byte)" + #CRLF$ +
    "**FBB2H** - Line terminal table - area que guarda informacao sobre cada linha da tela de texto. (24 bytes)" + #CRLF$ +
    "**FBCAH** - Posicao do primeiro caractere da linha digitada pelo INLIN (B1H) da BIOS. (2 bytes)" + #CRLF$ +
    "**FBCCH** - Area que guarda o caractere da posicao onde o cursor esta sobreposto. (1 byte)" + #CRLF$ +
    "**FBCDH** - Indica quais teclas de funcao estao sendo exibidas quando o KEY ON e' executado. (1 byte)" + #CRLF$ +
    "**FBCEH** - Indica o estado de operacao da interrupcao das teclas de funcao. (10 bytes)" + #CRLF$ +
    "**FBD8H** - Flag que indica se ocorreu o evento durante a espera em TRPTBL (FC4CH). (1 byte)" + #CRLF$ +
    "**FBD9H** - Flag de key click. (1 byte)" + #CRLF$ +
    "**FBDAH** - Estado da matriz de teclado (antigo). (11 bytes)" + #CRLF$ +
    "**FBE5H** - Estado da matriz de teclado (novo). (11 bytes)" + #CRLF$ +
    "**FBF0H** - Buffer de codigo de tecla. (40 bytes)" + #CRLF$ +
    "**FC18H** - Area temporaria usada pelo driver de tela. (40 bytes)" + #CRLF$ +
    "**FC40H** - Area temporaria usada pelo conversor de padrao (pattern converter). (8 bytes)" + #CRLF$ +
    "**FC48H** - Endereco inicial (mais baixo) da RAM instalada - normalmente 8000H. (2 bytes)" + #CRLF$ +
    "**FC4AH** - Endereco mais alto da memoria disponivel - definido pelo <limite de memoria> do comando CLEAR. (2 bytes)" + #CRLF$ +
    "**FC4CH** - Tabela de traps usada no tratamento de interrupcao. (78 bytes)" + #CRLF$ +
    "**FC9AH** - Usado internamente pelo BASIC. (1 byte)" + #CRLF$ +
    "**FC9BH** - Quando CTRL+STOP e' pressionado, entre outros casos, colocar 03H aqui interrompe a execucao. (1 byte)" + #CRLF$ +
    "**FC9CH** - Coordenada Y do paddle. (1 byte)" + #CRLF$ +
    "**FC9DH** - Coordenada X do paddle. (1 byte)" + #CRLF$ +
    "**FC9EH** - Usado internamente pelo comando PLAY. (2 bytes)" + #CRLF$ +
    "**FCA0H** - Intervalo do INTERVAL - definido pelo comando ON INTERVAL GOSUB. (2 bytes)" + #CRLF$ +
    "**FCA2H** - Contador para o INTERVAL. (2 bytes)" + #CRLF$ +
    "**FCA6H** - Flag de quando um caractere grafico esta sendo exibido. (1 byte)" + #CRLF$ +
    "**FCA7H** - Area que conta quantos caracteres vieram depois de um codigo de escape. (1 byte)" + #CRLF$ +
    "**FCA9H** - Presenca de exibicao do cursor - definida pelo <cursor switch> do comando LOCATE. (1 byte)" + #CRLF$ +
    "**FCAAH** - Formato do cursor. (1 byte)" + #CRLF$ +
    "**FCABH** - Estado da tecla CAPS - diferente de 0 = CAPS ON. (1 byte)" + #CRLF$ +
    "**FCACH** - Estado da tecla kana - diferente de 0 = ON. (1 byte)" + #CRLF$ +
    "**FCADH** - Estado do layout de teclas kana - 0=50 sons (gojuon); diferente de 0=JIS. (1 byte)" + #CRLF$ +
    "**FCAEH** - Diferente de 0 durante o load de um programa BASIC. (1 byte)" + #CRLF$ +
    "**FCAFH** - Numero do modo de tela atual. (1 byte)" + #CRLF$ +
    "**FCB0H** - Area de guarda do modo de tela. (1 byte)" + #CRLF$ +
    "**FCB2H** - Codigo de cor da borda usada pelo comando PAINT. (1 byte)" + #CRLF$ +
    "**FCB3H** - Coordenada X. (2 bytes)" + #CRLF$ +
    "**FCB5H** - Coordenada Y. (2 bytes)" + #CRLF$ +
    "**FCB7H** - Acumulador grafico (coordenada X). (2 bytes)" + #CRLF$ +
    "**FCB9H** - Acumulador grafico (coordenada Y). (2 bytes)" + #CRLF$ +
    "**FCBBH** - Flag usado pelo comando DRAW. (1 byte)" + #CRLF$ +
    "**FCBCH** - Fator de escala do DRAW - 0=sem escala; diferente de 0=com escala. (1 byte)" + #CRLF$ +
    "**FCBDH** - Angulo usado pelo DRAW. (1 byte)" + #CRLF$ +
    "**FCBEH** - Flag que indica se esta em BLOAD, em BSAVE, ou em nenhum dos dois. (1 byte)" + #CRLF$ +
    "**FCBFH** - Endereco inicial do BSAVE. (2 bytes)" + #CRLF$ +
    "**FCC1H** - Tabela de flags para slots expandidos - se cada slot e' expandido ou nao. (4 bytes)" + #CRLF$)

  MamuteHelp_Add("SUPER-X - Notas WORK (4/4)", "SUPER-X - Notas",
    "**FCC5H** - Situacao de selecao de slot atual para cada registrador de slot expandido. (4 bytes)" + #CRLF$ +
    "**FCC9H** - Guarda o atributo de cada pagina para cada slot. (64 bytes)" + #CRLF$ +
    "**FD09H** - Reserva uma area de trabalho especifica para cada slot. (128 bytes)" + #CRLF$ +
    "**FD89H** - Guarda o nome dos dispositivos de extended statement - termina em 0. (16 bytes)" + #CRLF$ +
    "**FD99H** - Usado para distinguir o dispositivo instalado no cartucho. (1 byte)" + #CRLF$ +
    "**FFFFH** - Registrador de selecao de slot expandido." + #CRLF$)

  MamuteHelp_Add("SUPER-X - Notas DATA", "SUPER-X - Notas",
    "**002DH** - Numero da versao do MSX." + #CRLF$ +
    "**002BH** - Byte ID - formato/tipo do gerador de caracteres, frequencia de interrupcao, etc." + #CRLF$ +
    "**002CH** - Byte ID - tipo de teclado, informacoes sobre PRINT USING, etc." + #CRLF$ +
    "**0006H** - Endereco da porta de acesso (leitura) ao VDP." + #CRLF$ +
    "**0007H** - Endereco da porta de acesso (escrita) ao VDP." + #CRLF$)

  MamuteHelp_Add("SUPER-X - Notas PORT", "SUPER-X - Notas",
    "**0090H** - Porta da impressora - bit0: saida de strobe (escrita); bit1: entrada de status (leitura)." + #CRLF$ +
    "**0091H** - Porta da impressora - dados de impressao." + #CRLF$ +
    "**0098H** - Acesso ao VDP - leitura e escrita de VRAM." + #CRLF$ +
    "**0099H** - Acesso ao VDP - comando/definicao de endereco (escrita); leitura de status (leitura)." + #CRLF$ +
    "**009AH** - Acesso ao VDP - registrador de paleta (so escrita)." + #CRLF$ +
    "**009BH** - Acesso ao VDP - definicao indireta de registrador (so escrita)." + #CRLF$ +
    "**00A0H** - Acesso ao PSG - trava de endereco." + #CRLF$ +
    "**00A1H** - Acesso ao PSG - escrita de dados." + #CRLF$ +
    "**00A2H** - Acesso ao PSG - leitura de dados." + #CRLF$ +
    "**00A8H** - Porta paralela - Porta A - leitura e escrita de dados." + #CRLF$ +
    "**00A9H** - Porta paralela - Porta B - leitura e escrita de dados." + #CRLF$ +
    "**00AAH** - Porta paralela - Porta C - leitura e escrita de dados." + #CRLF$ +
    "**00ABH** - Porta paralela - definicao de modo (so escrita)." + #CRLF$ +
    "**00B0H** - Endereco de acesso a memoria expandida (A0-A7)." + #CRLF$ +
    "**00B1H** - Endereco de acesso a memoria expandida (A8-A10, A13-A15)." + #CRLF$ +
    "**00B2H** - Endereco de acesso a memoria expandida (A11-A12); leitura de dados (D0-D7)." + #CRLF$ +
    "**00B3H** - Definicao de modo de acesso a memoria expandida." + #CRLF$ +
    "**00B4H** - Trava de endereco de acesso ao CLOCK-IC." + #CRLF$ +
    "**00B5H** - Leitura e escrita de dados de acesso ao CLOCK-IC." + #CRLF$ +
    "**00D8H** - Acesso a ROM Kanji - escrita do endereco baixo (b5-b0)." + #CRLF$ +
    "**00D9H** - Acesso a ROM Kanji - escrita do endereco alto (b5-b0); leitura de dados (b7-b0)." + #CRLF$ +
    "**00FCH** - Registrador de mapa de memoria, pagina 0." + #CRLF$ +
    "**00FDH** - Registrador de mapa de memoria, pagina 1." + #CRLF$ +
    "**00FEH** - Registrador de mapa de memoria, pagina 2." + #CRLF$ +
    "**00FFH** - Registrador de mapa de memoria, pagina 3." + #CRLF$)

  MamuteHelp_Add("SUPER-X - Notas HOOK (1/2)", "SUPER-X - Notas",
    "**FD9AH** - Inicio do processamento de interrupcao do MSXIO - adiciona tratamento de interrupcao para RS-232C, etc." + #CRLF$ +
    "**FD9FH** - Processamento de interrupcao do timer do MSXIO - adiciona tratamento de interrupcao do timer." + #CRLF$ +
    "**FDA4H** - Inicio do CHPUT (exibe 1 caractere) do MSXIO - conecta outros dispositivos de saida de console." + #CRLF$ +
    "**FDA9H** - Inicio do DSPCSR (exibicao do cursor) do MSXIO - conecta outros dispositivos de saida de console." + #CRLF$ +
    "**FDAEH** - Inicio do ERACSR (apagar cursor) do MSXIO - conecta outros dispositivos de saida de console." + #CRLF$ +
    "**FDB3H** - Inicio do DSPFNK (exibicao das teclas de funcao) do MSXIO - conecta outros dispositivos de saida de console." + #CRLF$ +
    "**FDB8H** - Inicio do ERAFNK (apagar teclas de funcao) do MSXIO - conecta outros dispositivos de saida de console." + #CRLF$ +
    "**FDBDH** - Inicio do TOTEXT (coloca a tela em modo texto) do MSXIO - conecta outros dispositivos de saida de console." + #CRLF$ +
    "**FDC2H** - Inicio do CHGET (le 1 caractere) do MSXIO - conecta outros dispositivos de saida de console." + #CRLF$ +
    "**FDC7H** - Inicio do INIPAT (inicializacao do padrao de caractere) do MSXIO - para usar outro conjunto de caracteres." + #CRLF$ +
    "**FDCCH** - Inicio do KEYCOD (conversao de codigo de tecla) do MSXIO - para usar outro layout de teclado." + #CRLF$ +
    "**FDD1H** - Inicio da rotina NMI (Key Easy) do MSXIO - para usar outro layout de teclado." + #CRLF$ +
    "**FDD6H** - Inicio do NMI (Non-Maskable Interrupt) do MSXIO - faz o tratamento do NMI." + #CRLF$ +
    "**FDDBH** - Inicio do PINLIN (entrada de 1 linha) do MSXINL - para usar outro dispositivo de entrada de console, etc." + #CRLF$ +
    "**FDE0H** - Inicio do QINLIN ("+Chr(34)+"?"+Chr(34)+" + entrada de 1 linha) do MSXINL - para usar outro dispositivo de entrada de console, etc." + #CRLF$ +
    "**FDE5H** - Inicio do INLIN (entrada de 1 linha) do MSXINL - para usar outro dispositivo de entrada de console, etc." + #CRLF$ +
    "**FDEAH** - Inicio do INGOTOP (ON GOTO) do MSXSTS - para usar outro dispositivo de tratamento de interrupcao." + #CRLF$ +
    "**FDF4H** - Inicio do SETS (set attribute) do MSXSTS - para conectar dispositivo de disco." + #CRLF$ +
    "**FDEFH** - Inicio do DSKO$ (saida de disco) do MSXSTS - para conectar dispositivo de disco." + #CRLF$ +
    "**FDF9H** - Inicio do NAME (renomear) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FDFEH** - Inicio do KILL (apagar arquivo) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE03H** - Inicio do IPL (carga do programa inicial) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE08H** - Inicio do COPY (copiar arquivo) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE0DH** - Inicio do CMD (comando estendido) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE12H** - Inicio do DSKF (espaco livre em disco) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE17H** - Inicio do DSKI (entrada de disco) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE1CH** - Inicio do ATTR$ (atributo) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE21H** - Inicio do LSET (alinhamento a esquerda) do MSXSTS - para conectar dispositivo de disco." + #CRLF$ +
    "**FE26H** - Inicio do RSET (alinhamento a direita) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE2BH** - Inicio do FIELD do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE30H** - Inicio do MKI$ (criacao de inteiro) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE35H** - Inicio do MKS$ (criacao de ponto flutuante simples) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE3AH** - Inicio do MKD$ (criacao de ponto flutuante duplo) do MSXSTS - para conectar dispositivo de disco." + #CRLF$ +
    "**FE3FH** - Inicio do CVI (conversao para inteiro) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE44H** - Inicio do CVS (conversao para ponto flutuante simples) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE49H** - Inicio do CVD (conversao para ponto flutuante duplo) do MSXSTS - conecta dispositivo de disco." + #CRLF$ +
    "**FE4EH** - SPDSK GETPTR (obter ponteiro de arquivo) - conecta dispositivo de disco." + #CRLF$ +
    "**FE53H** - SPCDSK SETFIL (definir ponteiro de arquivo) - conecta dispositivo de disco." + #CRLF$ +
    "**FE58H** - SPDSK NOFOR (nao ha FOR no comando OPEN) - conecta dispositivo de disco." + #CRLF$ +
    "**FE5DH** - SPCDSK NULOPN (abrir arquivo vazio) - conecta dispositivo de disco." + #CRLF$ +
    "**FE62H** - SPCDSK NTFLO (o numero do arquivo nao e' 0) - conecta dispositivo de disco." + #CRLF$ +
    "**FE67H** - SPCDSK MERGE (mesclar arquivo de programa) - conecta dispositivo de disco." + #CRLF$ +
    "**FE71H** - SPCDSK BINSAV (salvar em codigo de maquina) - conecta dispositivo de disco." + #CRLF$ +
    "**FE6CH** - SPCDSK SAVE (salvar) - conecta dispositivo de disco." + #CRLF$ +
    "**FE76H** - SPCDSK BINLOD (carregar codigo de maquina) - conecta dispositivo de disco." + #CRLF$ +
    "**FE7BH** - SPCDSK FILES (exibir nomes de arquivo) - conecta dispositivo de disco." + #CRLF$ +
    "**FE80H** - SPCDSK DGET (disk GET) - conecta dispositivo de disco." + #CRLF$ +
    "**FE85H** - SPCDSK FILOUT (saida de arquivo) - conecta dispositivo de disco." + #CRLF$ +
    "**FE8AH** - SPCDSK INDSKC (entrada do atributo do disco) - conecta dispositivo de disco." + #CRLF$ +
    "**FE8FH** - SPCDSK - seleciona novamente o drive anterior. Para conectar dispositivo de disco." + #CRLF$ +
    "**FE94H** - SPCDSK - guarda o drive atualmente selecionado. Conecta dispositivo de disco." + #CRLF$ +
    "**FE99H** - SPCDSK - funcao LOC (indica posicao). Conecta dispositivo de disco." + #CRLF$ +
    "**FE9EH** - SPCDSK - funcao LOF (tamanho do arquivo). Conecta dispositivo de disco." + #CRLF$ +
    "**FEA3H** - SPCDSK - funcao EOF (fim do arquivo). Conecta dispositivo de disco." + #CRLF$ +
    "**FEA8H** - SPCDSK - funcao FPOS (posicao no arquivo). Conecta dispositivo de disco." + #CRLF$ +
    "**FEADH** - SPCDSK BAKUPT (backup) - conecta dispositivo de disco." + #CRLF$)

  MamuteHelp_Add("SUPER-X - Notas HOOK (2/2)", "SUPER-X - Notas",
    "**FEB2H** - SPCDEV PARDEV (obter nome do dispositivo) - estende o nome de dispositivo logico." + #CRLF$ +
    "**FEB7H** - SPCDEV NODEVN (sem nome de dispositivo) - define o nome abreviado de dispositivo para outro dispositivo." + #CRLF$ +
    "**FEBCH** - SPCDEV POSDSK - conecta dispositivo de disco." + #CRLF$ +
    "**FEC1H** - SPCDEV DEVNAM (tratamento do nome do dispositivo) - estende o nome de dispositivo logico." + #CRLF$ +
    "**FEC6H** - SPCDEV GENDSP (atribuicao de dispositivo) - estende o nome de dispositivo logico." + #CRLF$ +
    "**FECBH** - BIMISC RUNC (limpeza para o RUN)." + #CRLF$ +
    "**FED0H** - BIMISC CLEARC (limpeza para o comando CLEAR)." + #CRLF$ +
    "**FED5H** - BIMISC LOPDFT (define o valor padrao do loop) - usa outro valor padrao na variavel." + #CRLF$ +
    "**FEDAH** - BIMISC STKERR (erro de pilha/stack error)." + #CRLF$ +
    "**FEDFH** - BIMISC ISFLIO (se e' entrada/saida de arquivo)." + #CRLF$ +
    "**FEE4H** - BIO OUTDO (executa o OUT)." + #CRLF$ +
    "**FEE9H** - BIO CRDO (executa CRLF)." + #CRLF$ +
    "**FEEEH** - BIO DSKCHI (entrada do atributo do disco)." + #CRLF$ +
    "**FEF3H** - GENGRP DOGRAPH (executa processamento grafico)." + #CRLF$ +
    "**FEF8H** - BINTRP PRGEND (fim de programa)." + #CRLF$ +
    "**FEFDH** - BINTRP ERRPRT (exibicao de erro)." + #CRLF$ +
    "**FF11H** - BINTRP DIRDO (executa instrucao direta)." + #CRLF$ +
    "**FF7FH** - BINTRP ISMID$ (se e' MID$)." + #CRLF$ +
    "**FF84H** - BINTRP WIDTHS (WIDTH)." + #CRLF$ +
    "**FF89H** - BINTRP LIST." + #CRLF$ +
    "**FF8EH** - BINTRP BUFLIN (buffer line)." + #CRLF$ +
    "**FFA2H** - BIPTRG PTRGET (obter ponteiro) - usa uma variavel diferente do padrao." + #CRLF$ +
    "**FFA7H** - MSXIO PHYDIO (entrada/saida fisica de disco) - conecta dispositivo de disco." + #CRLF$ +
    "**FFB1H** - BINTRP ERROR - tratamento de erro de programa de aplicacao." + #CRLF$ +
    "**FFB6H** - MSXIO LPTOUT (saida de impressora) - usa uma impressora diferente da padrao." + #CRLF$ +
    "**FFBBH** - MSXIO LPTSTT (status da impressora) - usa uma impressora diferente da padrao." + #CRLF$ +
    "**FFC0H** - MSXSTS - entrada do comando SCREEN. Estende o comando SCREEN." + #CRLF$ +
    "**FFC5H** - MSXSTS - entrada do comando PLAY. Estende o comando PLAY." + #CRLF$ +
    "**FFCAH** - Hook usado pela BIOS estendida." + #CRLF$ +
    "**FFCFH** - Usado pelo DOS." + #CRLF$ +
    "**FFD4H** - Usado pelo DOS." + #CRLF$)

EndProcedure
