;
; ------------------------------------------------------------
;  Ajuda -> MSX BASIC...: topicos de prosa/referencia do "Manual MSX 2+
;  FM" (Ademir Carchano / Flavio Monaco, ACVS Eletronica), complementando
;  MsxBasic2PlusDictData.pbi (que cobre so os comandos/instrucoes/funcoes
;  em si). Aqui entram: apresentacao do MSX2+, legenda de sintaxe do
;  manual, apresentacao do FM-Music e os 4 apendices (A-D).
;
;  Apendice D (Exemplos de Musicas) e um caso especial: o manual traz
;  duas musicas completas ("UNCHAINED MELODY" e "THEME FROM OVER THE
;  NET") cujos listagens ocupam ~10 paginas densas de strings de notas
;  concatenadas (uma pratica comum de otimizacao de espaco em programas
;  MSX, mas pessima para OCR/transcricao manual - um unico digito trocado
;  quebra a musica inteira sem dar nenhum erro de sintaxe). Por isso,
;  ao contrario do resto do dicionario, o apendice D e DESCRITO aqui
;  (o que cada musica demonstra, canais usados, etc.) e NAO transcrito
;  nota a nota - a mesma logica ja aplicada a tabela ASCII completa e as
;  formas de envelope do SOUND no dicionario do MSX1.
; ------------------------------------------------------------
;

Declare MSXManual_BuildMSX2Plus_Apresentacao()
Declare MSXManual_BuildMSX2Plus_FM()

Procedure MSXManual_BuildMSX2Plus()
  MSXManual_BuildMSX2Plus_Apresentacao()
  MSXManual_BuildMSX2Plus_FM()
EndProcedure

; --- Apresentacao e Sintaxe do capitulo MSX2+ (paginas 5-6 do manual) ---
Procedure MSXManual_BuildMSX2Plus_Apresentacao()
  MSXManual_Add("MSX 2+ - Apresentacao", "MSX 2+ (manual ACVS)",
    "As informacoes desta secao permitem que seja usada toda a potencialidade do novo MSX BASIC " +
    "3.0 incorporado no cartucho MSX 2+ FM fabricado pela ACVS Eletronica." + #CRLF$ + #CRLF$ +
    "As principais caracteristicas do computador depois da conexao do cartucho MSX 2+ FM sao:" + #CRLF$ +
    "- Texto de ate 80 colunas (mesmo pela televisao)." + #CRLF$ +
    "- Resolucao grafica maxima de 512 x 424 pontos com 16 cores de 512 combinacoes (screen 7 " +
    "modo entrelacado)." + #CRLF$ +
    "- Resolucao maxima de cores de 19.268 (screen 12)." + #CRLF$ +
    "- Memoria ROM do BASIC com 64 KBytes (48 KBytes com o MSX BASIC 3.0 e 16 KBytes com " +
    "Music-Basic)." + #CRLF$ +
    "- Memoria RAM de video com 128 KBytes." + #CRLF$ +
    "- Trabalha com varias paginas graficas." + #CRLF$ +
    "- SCREEN 0 a 12." + #CRLF$ +
    "- SPRITES multicoloridos." + #CRLF$ +
    "- Pode ter ate 8 SPRITES na mesma linha horizontal." + #CRLF$ +
    "- Relogio-calendario interno mantido por bateria que atualiza hora e data mesmo com o " +
    "cartucho desconectado." + #CRLF$ +
    "- Processador de video que executa a maior parte das funcoes graficas acelerando o " +
    "processamento." + #CRLF$ +
    "- RAMDISK interna com ate 32 KBytes." + #CRLF$ +
    "- Instrucoes SET PASSWORD, SETTITLE, SETPROMPT, etc." + #CRLF$ +
    "- Sintetizador com mais 9 canais de som FM." + #CRLF$ +
    "- 5 sons de instrumentos de percussao (baterias)." + #CRLF$ +
    "- 64 sons de instrumentos musicais pre-programados." + #CRLF$ +
    "- Saida do sintetizador FM em 2 canais." + #CRLF$ +
    "- Saidas de video colorido (composto) e de RF (canal 3).",
    5)

  MSXManual_Add("MSX 2+ - Sintaxe usada no manual", "MSX 2+ (manual ACVS)",
    "Descricao da sintaxe usada no capitulo MSX 2+ do manual ACVS (mesma ideia da legenda do " +
    "livro Gradiente, com uma categoria a mais: COMANDO)." + #CRLF$ + #CRLF$ +
    "NOME [(X)]   (TIPO)" + #CRLF$ + #CRLF$ +
    "1 - O nome do comando, instrucao ou funcao esta em letras maiusculas e devera ser escrito " +
    "exatamente como aparece." + #CRLF$ +
    "2 - Itens entre parenteses ( ) devem ser definidos pelo usuario." + #CRLF$ +
    "3 - Itens entre colchetes [ ] sao opcionais." + #CRLF$ +
    "4 - Todas as pontuacoes devem ser escritas como aparecem no formato. Isto se aplica a " +
    "pontos finais, virgulas, parenteses, dois pontos, ponto e virgula, etc." + #CRLF$ +
    "5 - X, Y e Z representam expressoes numericas." + #CRLF$ +
    "6 - X$, Y$ e Z$ representam expressoes alfanumericas." + #CRLF$ + #CRLF$ +
    "(TIPO) - Indica se e um COMANDO, uma INSTRUCAO ou uma FUNCAO. A diferenca entre os tipos e " +
    "a seguinte:" + #CRLF$ +
    "- COMANDO: e a ordem que, depois de executada, coloca o computador no modo de comando " +
    "direto via teclado. Por exemplo: LIST." + #CRLF$ +
    "- INSTRUCAO: e a ordem que pode ser dada via teclado ou dentro de um programa. Por exemplo " +
    "PRINT, GOTO, GOSUB, etc." + #CRLF$ +
    "- FUNCAO: so e valida acompanhada por uma INSTRUCAO. Por exemplo: PRINT BASE(0).",
    6)
EndProcedure

; --- FM-Music: apresentacao (pagina 37) e apendices A-D (paginas 48-53+) ---
Procedure MSXManual_BuildMSX2Plus_FM()
  MSXManual_Add("FM-Music - Apresentacao", "FM-Music (manual ACVS)",
    "O FM-Music, residente no cartucho MSX2+ FM (e tambem vendido como cartucho separado) e " +
    "capaz de sintetizar o som de diversos instrumentos musicais, utilizando-se de 2 osciladores " +
    "multi-timbrais e mais os sons de 5 instrumentos de percussao. Nele estao disponiveis 9 " +
    "canais que podem tocar ate 9 instrumentos ao mesmo tempo sem utilizar a bateria." + #CRLF$ + #CRLF$ +
    "Contudo, se os 5 canais da bateria eletronica forem acionados, ficam ainda 6 canais " +
    "simultaneos para outros instrumentos. Os 3 canais do PSG (chip de som original do MSX) " +
    "continuam ativos, podendo ser tocados junto com os canais do FM, resultando em ate 14 " +
    "canais simultaneos." + #CRLF$ + #CRLF$ +
    "O Music-Basic tem armazenado os sons de 64 instrumentos musicais sendo 63 pre-definidos e 1 " +
    "programavel. Os pre-definidos (de 0 a 62) sao os mais utilizados, como piano, flauta, " +
    "clarineta, violino, cordas, trompete, xilofone, etc." + #CRLF$ + #CRLF$ +
    "O som desses instrumentos pode ser alterado atraves de rotinas em Assembler ou Poke's em " +
    "Basic. A programacao do instrumento 63 e feita atraves de parametros transmitidos aos " +
    "registradores dos osciladores. E necessario, portanto, um certo conhecimento de sonorizacao " +
    "para sintetizar com perfeicao outros tipos de instrumentos." + #CRLF$ + #CRLF$ +
    "O FM pode ser programado tanto em Basic quanto em Assembler. Em Basic atraves de comandos " +
    "expandidos, tais como CALL MUSIC, CALL VOICE, entre outros (ver dicionario, letra C). Em " +
    "Assembler atraves de rotinas especificas em linguagem de maquina (um processo que, pelo " +
    "nivel de complexidade, nao foi detalhado no manual original).",
    37)

  MSXManual_Add("FM-Music - Apendice A - Programacao de Instrumentos", "FM-Music (manual ACVS)",
    "O FM possui 64 instrumentos sendo um deles, o 63, programavel. Mas existem algumas " +
    "dificuldades para se gerar o som de um instrumento. Uma delas e saber o que faz cada um " +
    "dos 16 registradores do FM." + #CRLF$ + #CRLF$ +
    "Cada instrumento e definido por 4 linhas de 4 bytes (16 bytes no total, tratados em blocos " +
    "de 16 bits cada - ver CALL VOICECOPY):" + #CRLF$ +
    "1) Nome do instrumento (opcional, 8 bytes, em ASCII hexadecimal se usado)." + #CRLF$ +
    "2) Afinacao e envelope: byte 1 = ajuste grosso da afinacao (default/inicial), byte 2 = " +
    "ajuste fino da afinacao, byte 3 = inutil, byte 4 = valor do gerador de envelope (formato da " +
    "amplitude do som) para mixagem dos dois osciladores. Os quatro bytes restantes desta " +
    "categoria (5,6,7,8) tem funcao desconhecida." + #CRLF$ +
    "3) Dados do 1o oscilador (CARRIER): byte 1 = nivel de graves; byte 2 (subdividido em 4 " +
    "partes) = vibracao (efeitos vibro e tremolo) e tonalidade do som; byte 3 = prolongamento do " +
    "som em relacao ao gerador de envelopes; byte 4 = ataque do 1o oscilador. Os ultimos 4 bytes " +
    "tambem sao inuteis neste caso." + #CRLF$ +
    "4) Dados do 2o oscilador (MODULATE): parecido com o topico 3, com poucas diferencas - byte " +
    "1 tem a mesma funcao do topico anterior (ligeiramente mais fino no ajuste); byte 2 " +
    "subdividido em 3 partes (vibracao, que dependendo de alguns fatores pode nao funcionar, e " +
    "tonalidade deste oscilador); byte 3 = volume dos dois osciladores; byte 4 = ataque deste " +
    "oscilador." + #CRLF$ + #CRLF$ +
    "OBS: Os ultimos bytes de cada linha (exceto a primeira), que nao tem funcao, podem assumir " +
    "qualquer valor. Os valores devem sempre ser colocados em hexadecimal. No APENDICE C ha uma " +
    "relacao com todos os instrumentos pre-definidos.",
    48)

  MSXManual_Add("FM-Music - Apendice B - Dicas e Macetes", "FM-Music (manual ACVS)",
    "O FM Music se caracteriza principalmente pela facilidade de programacao tanto em BASIC " +
    "quanto em ASSEMBLER. Alguns truques que produzem bons efeitos musicais:" + #CRLF$ + #CRLF$ +
    "GERACAO DE ECO OU REVERBERACAO: O som dos instrumentos no FM Music e originalmente composto " +
    "por apenas 2 osciladores. Sao considerados sons puros (extraidos direto do instrumento que " +
    "esta sendo simulado), ou seja, nao ha a entonacao timbral como numa musica de estudio. Para " +
    "resolver este problema e necessario adicionar mais um canal ao que desejamos tocar e " +
    "colocar um POKE que va alterar gradualmente o timbre da nota que estivermos tocando, dando " +
    "a impressao de uma pequena reverberacao (ex.: CALL MUSIC(0,0,2):POKE&HFA3C,40 antes de um " +
    "PLAY em dois canais, comparado com o mesmo PLAY em um so canal, sem o POKE, resulta num som " +
    "mais polido)." + #CRLF$ + #CRLF$ +
    "Variaveis de memoria uteis para todos os canais:" + #CRLF$ +
    "&HFA2C - PITCH CANAL 1 ; &HFA2D - TRANSPOSE CANAL 1" + #CRLF$ +
    "&HFA3C - PITCH CANAL 2 ; &HFA3D - TRANSPOSE CANAL 2" + #CRLF$ +
    "&HFA4C - PITCH CANAL 3 ; &HFA5D - TRANSPOSE CANAL 3" + #CRLF$ +
    "&HFA6C - PITCH CANAL 4 ; &HFA6D - TRANSPOSE CANAL 4" + #CRLF$ +
    "&HFA7C - PITCH CANAL 5 ; &HFA7D - TRANSPOSE CANAL 5" + #CRLF$ +
    "&HFA8C - PITCH CANAL 6 ; &HFA8D - TRANSPOSE CANAL 6" + #CRLF$ +
    "&HFA9C - PITCH CANAL 7 ; &HFA9D - TRANSPOSE CANAL 7" + #CRLF$ +
    "&HFAAC - PITCH CANAL 8 ; &HFAAD - TRANSPOSE CANAL 8" + #CRLF$ +
    "&HFAAC - PITCH CANAL 9 ; &HFAAD - TRANSPOSE CANAL 9" + #CRLF$ + #CRLF$ +
    "Outro recurso para o som sair com eco consiste em utilizar 2 canais tocando uma nota em " +
    "cada, separando a mesma sequencia de notas em dois canais concatenados (ex.: uma sequencia " +
    "unica dividida em dois PLAY# com um pequeno atraso relativo entre eles produz um bonito " +
    "efeito de eco - e necessario que o instrumento utilizado tenha um som prolongado)." + #CRLF$ + #CRLF$ +
    "INSTRUMENTOS NAO-MIXAVEIS: alguns instrumentos, por motivos desconhecidos, nao podem ser " +
    "mixados com outros mesmo em diversos canais. Esses instrumentos, geralmente os mais altos, " +
    "devem ser utilizados com certa precaucao sob risco de atrapalhar os outros." + #CRLF$ +
    "- MIXAVEIS: 00,02,03,04,05,06,07,09,12,14,16,24." + #CRLF$ +
    "- NAO-MIXAVEIS: 01,08,10,11,13,15,17,18,19,20,21,22,23,24 ate o 62." + #CRLF$ + #CRLF$ +
    "PARAMETRO " + MSXQ + "Y" + MSXQ + ": quando utilizado dentro de um comando PLAY, serve para alterar o " +
    "som de alguns instrumentos pre-definidos. Caso esteja dentro de um canal de bateria, ira " +
    "alterar o som dos instrumentos de bateria (como no comando CALL AUDREG). A sintaxe de sua " +
    "utilizacao e: Y<r>,<n>, onde <r> e um registrador de som entre 0 e 255 onde nao sao " +
    "aceitos todos os numeros, apenas alguns. O <n> e um valor qualquer entre 0 e 255 atribuido " +
    "a esse registrador." + #CRLF$ + #CRLF$ +
    "Note que se pode usar o parametro " + MSXQ + "@W" + MSXQ + " para prolongar o tempo de execucao da " +
    "nota, uma vez que o parametro " + MSXQ + "Y" + MSXQ + " nao faz isso (maiores detalhes veja o comando " +
    "CALL AUDREG).",
    50)

  MSXManual_Add("FM-Music - Apendice C - Relacao de Instrumentos", "FM-Music (manual ACVS)",
    "Tabela com todos os 64 instrumentos do FM (numero : nome):" + #CRLF$ +
    "00 Piano I, 01 Piano II, 02 Violin, 03 Flute, 04 Clarinet, 05 Oboe, 06 Trumpet, 07 Pipe " +
    "Organ, 08 Xylophone, 09 Organ, 10 Guitar, 11 Santool, 12 Eletric Piano, 13 Clavicod, 14 " +
    "Harp Sicked, 15 Harp Sicked II, 16 Vibraphone, 17 Koto, 18 Taiko, 19 Engine, 20 UFO, 21 " +
    "Synth Bell, 22 Chime, 23 Synth Bass, 24 Synthesizer, 25 Synth Percussion, 26 Synth Rhythm, " +
    "27 Harm Drum, 28 Cow Bell, 29 Close Hi-Hat, 30 Snare Drum, 31 Bass Drum, 32 Piano III, 33 " +
    "Eletric Piano II, 34 Santool II, 35 Brass, 36 Flute II, 37 Clavicod II, 38 Clavicod III, 39 " +
    "Koto II, 40 Pipe Organ II, 41 PohdsPLA, 42 RohdsPLA, 43 Orch L, 44 Orch R, 45 Synth Violin, " +
    "46 Synth Organ, 47 Synth Brass, 48 Tube, 49 Shamisen, 50 Magical, 51 Huwawa, 52 Wonder " +
    "Flute, 53 Hard Rock, 54 Machine, 55 Machine V, 56 Comic, 57 SE Comic, 58 SE Laser, 59 SE " +
    "Noise, 60 SE Star, 61 SE Star II, 62 Engine II, 63 Silence (instrumento programavel, sem " +
    "som proprio ate ser definido pelo usuario - ver CALL VOICECOPY).",
    52)

  ; CONFERIR: descricao, nao transcricao literal - ver nota no cabecalho
  ; do arquivo sobre o motivo de nao reproduzir os dois listings
  ; completos aqui (risco de erro em strings de notas muito densas,
  ; baixo valor como material de referencia de linguagem).
  MSXManual_Add("FM-Music - Apendice D - Exemplos de Musicas", "FM-Music (manual ACVS)",
    "O manual traz dois exemplos completos de musicas em BASIC usando o FM-Music (paginas " +
    "53 a 62 do manual ACVS). Este topico DESCREVE os dois programas em vez de transcreve-los " +
    "nota a nota - os listagens originais usam strings de notas extremamente densas e " +
    "concatenadas (uma pratica normal de otimizacao de espaco em programas MSX de epoca, mas " +
    "muito arriscada de transcrever a mao: um unico caractere trocado quebra a musica sem gerar " +
    "nenhum erro de sintaxe detectavel). Quem precisar do listing exato deve consultar " +
    "docs/manual_msx2fm_acvs.pdf diretamente." + #CRLF$ + #CRLF$ +
    "UNCHAINED MELODY (trilha do filme " + MSXQ + "GHOST" + MSXQ + ", adaptada e mixada por Flavio " +
    "Monaco, 1991): usa 4 canais de FM, sendo 2 concatenados (para efeito de reverberacao), mais " +
    "a bateria eletronica acionada. Os instrumentos usados sao FLAUTA, PIANO, VIOLINO e BAIXO. O " +
    "programa desenha uma moldura decorativa em modo texto com creditos, depois toca a musica " +
    "usando series de strings (uma por instrumento/trecho) concatenadas em sequencia de " +
    "PLAY#2,... com parametros de acompanhamento de piano, flauta solo, violino e baixo tocados " +
    "simultaneamente em canais diferentes." + #CRLF$ + #CRLF$ +
    "THEME FROM OVER THE NET (tema do jogo original do AMIGA 500, adaptado por Flavio Monaco, " +
    "1991): usa 2 canais concatenados (6 vozes) com um unico instrumento, o CLAVICOD (que tem " +
    "som semelhante ao de uma guitarra de heavy metal), mais a bateria totalmente reprogramada " +
    "via CALL AUDREG, usando tambem o PSG (canais do som original do MSX) como reforco. E uma " +
    "musica retirada de um jogo, com bastante uso de efeitos de eco (2 canais tocando a mesma " +
    "nota defasada) e transposicao (CALL TRANSPOSE) no trecho final para um efeito de saida " +
    "(fade/pitch bend) antes do END do programa.",
    53)
EndProcedure