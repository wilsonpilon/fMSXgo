; Ajuda -> Mamute Assembler...: base de dados dos topicos, escrita a mao (nao
; convertida de nenhum manual externo - ao contrario de AsmsxHelpData.pbi/
; RedBookHelpData.pbi/etc.) porque o Mamute Assembler e uma ferramenta NOVA
; desta IDE, sem documento de origem. Cresce um Add() por comando novo, na
; mesma velocidade que MamuteAssemblerGui.pbi ganha o Case correspondente em
; MamuteGui_Dispatch() - os dois crescem juntos por sessao.
;
; Corpo.s renderizado por GenMdHelp_RenderMarkdown() (GenericMdHelpGui.pbi,
; mesmo motor do Ajuda -> asMSX...) - suporta **negrito**/`codigo`/blocos
; ``` sem precisar de parser proprio.

Structure MamuteHelpTopic
  Titulo.s
  Grupo.s
  Corpo.s
EndStructure

Global NewList MamuteHelp_Topics.MamuteHelpTopic()
Global MamuteHelp_DataBuilt.b = #False

Procedure MamuteHelp_Add(Titulo.s, Grupo.s, Corpo.s)
  AddElement(MamuteHelp_Topics())
  MamuteHelp_Topics()\Titulo = Titulo
  MamuteHelp_Topics()\Grupo = Grupo
  MamuteHelp_Topics()\Corpo = Corpo
EndProcedure

Procedure MamuteHelp_BuildData()
  If MamuteHelp_DataBuilt
    ProcedureReturn
  EndIf
  MamuteHelp_DataBuilt = #True

  MamuteHelp_Add("Introducao", "",
    "O **Mamute Assembler** (`Executar -> Mamute Assembler...`) e uma janela estilo " +
    Chr(34) + "monitor" + Chr(34) + " - inspirada nos montadores de linha de comando dos " +
    "computadores de 8 bits dos anos 80 (o **MegaAssembler** original foi a inspiracao direta) " +
    "- em vez de uma tela cheia de campos e botoes, um prompt `MON>` aceita comandos digitados, " +
    "um de cada vez." + #CRLF$ + #CRLF$ +
    "Fundo preto, texto monoespacado verde: visual deliberadamente diferente do resto da IDE " +
    "(que segue o tema claro escolhido em `Configurar -> Editor...`) - e pra lembrar um " +
    "terminal de verdade daquela epoca, nao um dialogo moderno." + #CRLF$ + #CRLF$ +
    "**Nao e o Editor Hexa nem os assemblers ja existentes** (nativo, N80, asMSX) - e uma " +
    "ferramenta a parte, com seu proprio pequeno conjunto de comandos, que vai crescer aos " +
    "poucos, sessao a sessao. Comandos disponiveis ate agora: **BA / QUIT**, **PAGE**, **DM**, " +
    "**ZAP**, **SCR**, **SH**, **MS**, **LOAD**, **SAVE**, **M**, **S**, **C**, **D**, **P**, " +
    "**V**, **T**, **F**, **G**, **X**, **R**, **L**, **LP**, **CL**, **XD** e **XM**, ver ao lado " +
    "(**G** e **R** ainda so " +
    "validam a sintaxe e confirmam no log - a execucao de programas e o carregamento de assemblados " +
    "ficam pra uma fase futura). **Os enderecos/setores digitados em qualquer " +
    "comando sao sempre em hexadecimal** - o padrao de entrada do Mamute Assembler inteiro. **Setas " +
    "Cima/Baixo** " +
    "no campo `MON>` navegam pelo historico de comandos ja digitados (Cima = mais recente, Baixo = " +
    "volta pro presente) - esse historico e salvo no arquivo de projeto atual (ou num projeto padrao, " +
    "se nenhum estiver aberto) e continua disponivel na proxima vez que o Mamute Assembler abrir." + #CRLF$ + #CRLF$ +
    "**`?` na frente de um comando do SUPER-X manda a saida pra " + Chr(34) + "impressora" + Chr(34) +
    "** (`?XD 4000,4010` em vez de `XD 4000,4010`) - convencao do SUPER-X original (colocar `?` na " +
    "frente do comando), que aqui vira **PDF** em vez de impressora de verdade (mesma ideia do `P`/" +
    "`LP` do MegaAssembler). So' vale pros comandos PORTADOS do SUPER-X (`XD`, ver ao lado - `XM` nao " +
    "tem listagem estatica pra imprimir, e' uma sessao interativa) - os herdados do MegaAssembler ja " +
    "tem seu proprio verbo dedicado pra isso (`D`->`P`, `L`->`LP`), sem precisar de prefixo." + #CRLF$ + #CRLF$ +
    "**7 variaveis de debugger do SUPER-X** guardam um endereco (com slot/sub-slot/VRAM junto) pra " +
    "reusar depois: `@0`-`@3` (normais) e `@B`/`@E`/`@S` (Begin/End/Start-ou-Size, especiais - " +
    "preenchidas automaticamente por comandos de carga em disco quando esses existirem numa sessao " +
    "futura). `@` sozinho no prompt mostra as 7; `@<numero ou letra>=<endereco>[#<slot>[-<sub>]|#V|" +
    "#S]` define uma (ex.: `@0=8000#3-1`). Depois de definida, `@<nome>` substitui um endereco " +
    "INTEIRO (numero + slot) em qualquer comando do SUPER-X (`XD @0` em vez de `XD 8000#3-1`) - " +
    "**so' pros comandos PORTADOS do SUPER-X**, mesma decisao de escopo do `#slot`/`?`. Dentro de " +
    "expressoes da calculadora (`CL`, e os campos de dado do `XM`), `@<nome>` vira so' o NUMERO " +
    "gravado, sem o slot (`CL @1+1` soma 1 ao endereco de `@1`). Comandos que abrem `XD`/`XM` " +
    "gravam o endereco usado automaticamente em `@0` (mesmo comportamento do manual original: " +
    "" + Chr(34) + "commands store base address in variable 0" + Chr(34) + ")." + #CRLF$ + #CRLF$ +
    "O Mamute Assembler simula o **sistema de slots do MSX de verdade**: 4 slots (0-3), cada um " +
    "com 4 paginas de 16KB (`Pagina 0` = `0000-3FFF`, `Pagina 1` = `4000-7FFF`, `Pagina 2` = " +
    "`8000-BFFF`, `Pagina 3` = `C000-FFFF`) - 16 blocos de memoria ao todo. `Configurar -> " +
    "Mamute Assembler...` define o que existe FISICAMENTE em cada um desses 16 blocos (Vazio/" +
    "RAM/ROM/BASIC, e um arquivo pra carregar quando for ROM/BASIC). Blocos RAM comecam sempre " +
    "em branco; blocos ROM/BASIC com arquivo configurado sao lidos de verdade toda vez que esta " +
    "janela abre - se o arquivo for menor que 16KB, o resto do bloco fica em branco." + #CRLF$ + #CRLF$ +
    "A mesma tela de configuracao tambem define o **tamanho da VRAM simulada** (16KB/128KB/192KB, " +
    "usada pelo comando `V`) - endereco plano, sem banco/pagina, ja que a VRAM de um MSX de " +
    "verdade nunca fica mapeada no espaco de enderecos do Z80 (e acessada pelas portas do VDP).")

  MamuteHelp_Add("BA / QUIT", "Comandos",
    "Encerra a janela do Mamute Assembler - equivalente a fechar pelo X da janela. Sem " +
    "argumentos, funciona em qualquer um dos dois nomes (nao diferencia maiusculas de " +
    "minusculas)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>BA" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "ou" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>QUIT" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Qualquer outra entrada nao reconhecida ainda mostra `?COMANDO INVALIDO` - novos comandos " +
    "entram aqui aos poucos, ver `README.md`/`docs/RELEASE_NOTES.md` pro que ja foi " +
    "acrescentado desde esta versao.")

  MamuteHelp_Add("PAGE", "Comandos",
    "Mostra ou troca o **mapeamento ativo agora mesmo**: pra cada uma das 4 paginas que o Z80 " +
    "enxerga (0-3), qual dos 4 slots fisicos (`Configurar -> Mamute Assembler...`) esta " +
    "comutado ali - exatamente como o registrador de slot primario de um MSX de verdade. Isso " +
    "e diferente da configuracao fisica: um slot pode ter RAM/ROM/BASIC configurados nele, mas " +
    "so o slot MAPEADO numa pagina e o que os proximos comandos que mostram/inserem dados vao " +
    "realmente enxergar naquele endereco (comandos ainda nao portados - ver Introducao)." + #CRLF$ + #CRLF$ +
    "**`PAGE`** (sem argumentos) - coloca as 4 paginas no slot marcado como RAM (o primeiro " +
    "slot, varrendo 0 a 3, que tiver RAM configurada em alguma pagina). Mostra `?NENHUM SLOT " +
    "DE RAM CONFIGURADO` se nenhum slot tiver RAM ainda." + #CRLF$ + #CRLF$ +
    "**`PAGE ?`** - so mostra o mapeamento ativo, sem mudar nada:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>PAGE ?" + #CRLF$ +
    "PAGE0(0000-3FFF) SLOT 0" + #CRLF$ +
    "PAGE1(4000-7FFF) SLOT 0" + #CRLF$ +
    "PAGE2(8000-BFFF) SLOT 3" + #CRLF$ +
    "PAGE3(C000-FFFF) SLOT 3" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "**`PAGE X, Y, Z, W`** - troca o mapeamento: pagina 0 passa pro slot `X`, pagina 1 pro " +
    "slot `Y`, pagina 2 pro slot `Z`, pagina 3 pro slot `W` (cada um de 0 a 3). Sempre os 4 de " +
    "uma vez - nao da pra trocar so uma pagina isolada. Exemplos:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>PAGE 2, 2, 2, 2" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "coloca as 4 paginas no slot 2;" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>PAGE 0, 1, 3, 3" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "coloca a pagina 0 no slot 0, a pagina 1 no slot 1, e as paginas 2 e 3 no slot 3. Depois de " +
    "aplicar, o novo mapeamento e mostrado na hora (igual `PAGE ?`), pra confirmar visualmente " +
    "o que mudou. Argumento fora de 0-3, faltando ou sobrando (sempre precisa ser exatamente 4, " +
    "separados por virgula) mostra `?ERRO DE SINTAXE`.")

  MamuteHelp_Add("DM", "Comandos",
    "**Despejo de Memoria** - o primeiro comando que realmente le/escreve a memoria simulada. " +
    "Abre uma janela separada mostrando 128 bytes (16 linhas de 8 bytes) a partir do endereco " +
    "informado, em hexa e ASCII lado a lado, navegavel e editavel." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>DM <endereco>[,<deslocamento>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endereco>` (obrigatorio) - onde comeca o despejo, em hexa (0000-FFFF). `<deslocamento>` " +
    "(opcional, tambem hexa, com sinal `+`/`-` opcional na frente) - de `-7F` a `80` - " + Chr(34) +
    "criptografa/descriptografa" + Chr(34) + " so a INTERPRETACAO ASCII exibida: cada byte mostrado " +
    "como texto e o valor cru mais o deslocamento (modulo 256) - o bloco hexa sempre mostra o " +
    "byte cru da memoria, sem nenhuma alteracao. Exemplo:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>DM 4000,-20" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "**Layout de cada linha:** endereco na primeira coluna, 8 bytes em hexa nas colunas " +
    "seguintes, os 8 caracteres correspondentes como um bloco no final. Caractere que nao da pra " +
    "imprimir vira `.`. Abaixo da grade, duas linhas de status: `Endereco:` (o endereco base " +
    "atual) e `Desloc.:` (o deslocamento ativo)." + #CRLF$ + #CRLF$ +
    "**Navegacao do cursor** - move pela grade de 128 bytes (clique direto numa celula tambem " +
    "funciona):" + #CRLF$ +
    "- 4 setas pequenas na tela (clicaveis) - movem uma celula por vez; teclado (setas do " +
    "cursor) faz o mesmo." + #CRLF$ +
    "- `TAB` alterna se o cursor esta no bloco hexa ou no bloco de texto." + #CRLF$ +
    "- 2 setas maiores (`<<`/`>>`) pulam **-128**/**+128 bytes** no endereco base (PgUp/PgDn do " +
    "teclado fazem o mesmo)." + #CRLF$ +
    "- Botoes `+`/`-` (ou as teclas correspondentes do teclado numerico) ajustam o deslocamento " +
    "em 1, dentro da faixa `-7F` a `80`." + #CRLF$ + #CRLF$ +
    "**Editar um byte** - `RETURN` abre um campo de entrada pro bloco ativo (hex ou texto); " +
    "`RETURN` de novo confirma o que foi digitado; `ESC` cancela a edicao em andamento (ou, fora " +
    "de edicao, fecha a janela do DM). No bloco hexa, digite 1-2 digitos hexa pro byte sob o " +
    "cursor. No bloco de texto, digite um texto simples - cada caractere vira um byte cru " +
    "(revertendo o deslocamento ativo), escritos a partir do cursor, que avanca sozinho." + #CRLF$ + #CRLF$ +
    "Escrita **so tem efeito em celulas mapeadas como RAM agora** (`PAGE`/`Configurar -> Mamute " +
    "Assembler...`) - ROM, BASIC e Vazio sao somente-leitura, igual hardware real (nao ha o que " +
    "escrever fisicamente ali).")

  MamuteHelp_Add("ZAP", "Comandos",
    "**Editor de Setores de disco** - muito parecido com o `DM`, mas em vez de mostrar/editar a " +
    "memoria simulada do MSX, abre uma **imagem de disco (.dsk)** e mostra/edita os bytes crus " +
    "dela, setor a setor (512 bytes/setor). Prioridade pra disquetes de **720KB** (FAT12 padrao), " +
    "mas 360KB e 180KB tambem funcionam - qualquer combinacao de face simples/dupla e densidade " +
    "simples/dupla, 5" + Chr(34) + "1/4 ou 3" + Chr(34) + "1/2. O ZAP nao interpreta a estrutura " +
    "FAT12 (boot sector, FAT, diretorio) - so le/escreve bytes crus por posicao, igual um editor " +
    "de setor de verdade da epoca." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>ZAP <setor inicial>[,<deslocamento>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<setor inicial>` (obrigatorio, hexa) - o setor onde a grade comeca (setor 0 = boot sector). " +
    "`<deslocamento>` (opcional, hexa com sinal, `-7F` a `80`) - identico ao do `DM`: " + Chr(34) +
    "criptografa/descriptografa" + Chr(34) + " so a interpretacao ASCII exibida/digitada, nunca o " +
    "byte cru." + #CRLF$ + #CRLF$ +
    "**Ao rodar, primeiro pede um arquivo .dsk** (janela normal de escolher arquivo do Windows). " +
    "Cancelar a escolha cancela o comando inteiro, sem abrir nada." + #CRLF$ + #CRLF$ +
    "**Layout e navegacao** identicos ao `DM` (mesmas setas/`TAB`/`PgUp`/`PgDn`/`+`/`-`/clique do " +
    "mouse - ver o topico `DM` ao lado pro detalhe completo) - a diferenca e o rotulo de cada " +
    "linha, que mostra o deslocamento DENTRO DO SETOR atual (`000` a `1F8`, ja que um setor tem " +
    "512 bytes = 4 telas de 128), e as linhas de status mostram `Setor:` + `Byte:` (endereco " +
    "absoluto dentro do arquivo) em vez de `Endereco:`." + #CRLF$ + #CRLF$ +
    "**Salvando alteracoes - a diferenca mais importante em relacao ao DM**: editar um byte no " +
    "ZAP muda so o que esta na MEMORIA (ainda nao grava no arquivo .dsk de verdade). Pra gravar o " +
    "setor onde o cursor esta agora de volta no disco, use:" + #CRLF$ + #CRLF$ +
    "- **`Ctrl+S`**, ou" + #CRLF$ +
    "- o botao amarelo **" + Chr(34) + "SALVAR SETOR" + Chr(34) + "** na tela (unico botao extra " +
    "que o ZAP tem alem dos mesmos do `DM`)." + #CRLF$ + #CRLF$ +
    "So o setor sob o cursor e gravado (gravacao cirurgica, nao o disco inteiro). O titulo da " +
    "janela ganha um `*` enquanto houver qualquer alteracao ainda nao salva; fechar a janela nesse " +
    "estado (`ESC` ou o X) pede confirmacao antes de descartar.")

  MamuteHelp_Add("SCR", "Comandos",
    "**Display grafico da memoria** - mostra uma tela FIXA de 256x192 pixels (32x24 caracteres " +
    "8x8, a mesma resolucao de um SCREEN 2/1 real do MSX) preenchida com a memoria a partir de um " +
    "endereco, cada caractere formado por 8 bytes/8 pixels (1 bit = 1 pixel), exatamente como a " +
    "Pattern Generator Table do SCREEN 1/2 ou a Sprite Pattern Table de um MSX real - util pra " +
    "visualizar fontes de caracteres e sprites direto na memoria simulada." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>SCR <endinic>,<dx>,<dy>[,<modo>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Todos os numeros sao hexa. `<endinic>` (obrigatorio) - endereco do primeiro caractere. A " +
    "TELA em si e sempre 256x192 - `<dx>`/`<dy>` (obrigatorios, >=1) NAO mudam esse tamanho, eles " +
    "definem o " + Chr(34) + "azulejo" + Chr(34) + " (bloco de `dx`x`dy` caracteres) usado pra " +
    "ladrilhar a tela inteira, da esquerda pra direita e de cima pra baixo. `<modo>` (opcional, " +
    "`0` ou `1`, default `0`) - ordem em que os blocos de 8 bytes sao lidos DENTRO de cada " +
    "azulejo:" + #CRLF$ +
    "- **`0` (horizontal)** - linha por linha dentro do azulejo." + #CRLF$ +
    "- **`1` (vertical)** - coluna por coluna dentro do azulejo, a mesma ordem real de " +
    "armazenamento de sprites do MSX (por isso o manual original chama esse modo de " +
    Chr(34) + "formato sprite" + Chr(34) + ")." + #CRLF$ + #CRLF$ +
    "Exemplo pra ver a tabela de caracteres ASCII de uma ROM de fonte carregada em " +
    "`Configurar -> Mamute Assembler...` (endereco 1BBF e onde a maioria das BIOS de MSX guarda o " +
    "inicio da Pattern Generator Table; `<dx>`=`<dy>`=`1` ladrilha a tela toda com 1 caractere por " +
    "azulejo, ou seja, uma leitura sequencial simples - a tela fica identica ao MegaAssembler " +
    "original rodando de verdade):" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>SCR 1BBF,1,1" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "**Navegacao** (fora do modo de edicao):" + #CRLF$ +
    "- **Setas esquerda/direita** - deslocam o endereco base **1 byte** (ajuste fino, util pra " +
    "achar o alinhamento certo de uma tabela)." + #CRLF$ +
    "- **Setas cima/baixo** - deslocam o endereco base **1 azulejo inteiro** (`dx`*`dy`*8 bytes)." + #CRLF$ +
    "- **`TAB`** (ou o botao **MOL**) - liga/desliga o contorno de uma **moldura**: um cursor de " +
    "edicao de tamanho FIXO, sempre **2x2 CARACTERES** (16x16 pixels), sempre no canto superior " +
    "esquerdo da tela (os 2 primeiros caracteres da 1a linha + os 2 primeiros da 2a linha). Nao ha " +
    "tecla pra mover a moldura pela tela - a unica forma de trazer outro pedaco da memoria pra " +
    "dentro dela e rolar o endereco base com as setas." + #CRLF$ +
    "- **`E`** (ou o botao **END**) - mostra/oculta o rotulo com o endereco base atual." + #CRLF$ +
    "- **`ENTER`** - entra no modo de edicao, ampliando exatamente os 16x16 pixels da moldura num " +
    "painel a parte, ao lado da tela." + #CRLF$ +
    "- **`ESC`** - encerra o comando (fecha a janela)." + #CRLF$ + #CRLF$ +
    "**Modo de edicao** (`ENTER`) - so afeta os 16x16 pixels da moldura, mostrados ampliados no " +
    "painel da direita com um cursor (contorno vermelho):" + #CRLF$ +
    "- **Setas** - movem o cursor de pixel dentro da moldura (nunca sai dos 16x16 pixels dela)." + #CRLF$ +
    "- **`ESPACO`** - inverte (acende/apaga) o pixel sob o cursor." + #CRLF$ +
    "- **`I`** (ou o botao **INV**) - inverte (XOR) os 16x16 pixels INTEIROS da moldura de uma " +
    "vez." + #CRLF$ +
    "- **`L`** (ou o botao **APG**) - apaga (zera) esses mesmos 16x16 pixels de uma vez." + #CRLF$ +
    "- **`ENTER`** - sai do modo de edicao (as alteracoes ja foram gravadas, pixel a pixel, na " +
    "memoria simulada)." + #CRLF$ +
    "- **`ESC`** - cancela TODAS as alteracoes feitas desde que entrou no modo de edicao " +
    "(restaura a moldura pra como estava) e sai do modo de edicao." + #CRLF$ + #CRLF$ +
    "**Se a moldura cair sobre uma celula que nao seja RAM agora** (ROM/BASIC/Vazio, conforme " +
    "`PAGE`) - o painel de edicao mostra o conteudo REAL normalmente (util pra so dar zoom e ver " +
    "um detalhe da tela, sem intencao de editar) e todas as teclas de edicao continuam " +
    "respondendo ao toque, MAS nada e gravado de verdade - ROM e fisicamente somente-leitura " +
    "(mesma regra do `DM`), entao o pixel so volta a mostrar o mesmo valor real no proximo " +
    "desenho. Um aviso amarelo " + Chr(34) + "ROM - somente leitura (alteracoes nao sao " +
    "gravadas)" + Chr(34) + " aparece abaixo da tela nesse caso.")

  MamuteHelp_Add("SH", "Comandos",
    "**Busca de bytes ou texto na memoria** - procura uma sequencia de bytes exatos (com curingas " +
    "opcionais) ou um texto (testando automaticamente todos os deslocamentos possiveis). Nao abre " +
    "janela nenhuma - so mostra o resultado direto no log do `MON>`." + #CRLF$ + #CRLF$ +
    "**Sintaxe (modo bytes):**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>SH [<endereco>],<byte>[,<byte>...]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endereco>` (hexa) - onde comecar a busca. Se for omitido (a virgula continua ali, so o " +
    "numero antes dela que falta - ex.: `SH ,2A,40`), a busca continua do endereco onde a ULTIMA " +
    "busca deste comando achou algo, mais 1 - so funciona depois de um `SH` que ja tenha achado " +
    "algo nesta mesma sessao da janela do Mamute Assembler." + #CRLF$ + #CRLF$ +
    "Cada `<byte>` e 1-2 digitos hexa. **Deixar um `<byte>` vazio (virgula dupla) vira curinga** - " +
    "" + Chr(34) + "esse byte pode ser qualquer um" + Chr(34) + ". Exemplos:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>SH 4000,2A,40,0C" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "procura a sequencia exata `2A 40 0C` a partir de `4000`;" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>SH 4000,2A,,0C" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "procura 3 bytes onde o 1o e `2A`, o 2o pode ser qualquer coisa, e o 3o e `0C`." + #CRLF$ + #CRLF$ +
    "**Sintaxe (modo texto):**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>SH [<endereco>],'<texto>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Um apostrofo seguido do texto (sem precisar fechar com outro apostrofo), 2+ caracteres. " +
    "Diferente do modo bytes, a busca de texto testa TODOS os deslocamentos possiveis (`-7F` a " +
    "`80`, mesma faixa do `DM`/`ZAP`) em cada posicao candidata - acha tanto o texto puro " +
    "(deslocamento `+00`) quanto texto " + Chr(34) + "cifrado" + Chr(34) + " por um deslocamento " +
    "fixo (truque comum em jogos antigos pra nao deixar dialogo legivel num editor de disco cru). " +
    "Exemplo:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>SH 3F41,'teste" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "**Resultado:** `ACHADO EM <endereco>` (modo bytes) ou `ACHADO EM <endereco> DESLOC " +
    "<deslocamento>` (modo texto, com sinal `+`/`-`), ou `NAO ENCONTRADO` se a busca varrer os " +
    "65536 enderecos (com volta ao inicio) sem achar nada.")

  MamuteHelp_Add("MS", "Comandos",
    "**Grava uma string na memoria** - escreve o texto digitado, byte a byte, a partir de um " +
    "endereco, com um deslocamento opcional. Nao abre janela nenhuma - so confirma no log do " +
    "`MON>`." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>MS <endereco>,[<deslocamento>],'<texto>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endereco>` (obrigatorio, hexa) - onde comeca a gravacao. `<deslocamento>` (opcional, hexa " +
    "com sinal `+`/`-`, `-7F` a `80`, mesma faixa do `DM`/`ZAP`/`SH`) - `0` se omitido. Um " +
    "apostrofo seguido do texto (sem precisar fechar com outro apostrofo) - qualquer virgula " +
    "dentro do texto NAO quebra o comando, tudo depois do apostrofo vira parte do texto." + #CRLF$ + #CRLF$ +
    "Cada caractere e gravado como `(codigo do caractere - deslocamento) & FF` - a MESMA formula " +
    "usada pelo bloco de texto do `DM` ao editar. Isso significa que o texto gravado com um " +
    "deslocamento diferente de zero fica " + Chr(34) + "cifrado" + Chr(34) + " nos bytes crus - " +
    "so volta a aparecer legivel se depois for lido (`DM`) ou procurado (`SH`) com esse MESMO " +
    "deslocamento. Exemplo:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>MS 9A15,20,'nome" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "grava a string `nome` a partir do endereco `9A15` com deslocamento `+20` - `DM 9A15,20` (ou " +
    "`SH ,'nome` apos ajustar o deslocamento) mostraria `nome` de volta." + #CRLF$ + #CRLF$ +
    "Escrita **so tem efeito em celulas mapeadas como RAM agora** (`PAGE`) - mesma regra do `DM`, " +
    "ROM/BASIC/Vazio sao somente-leitura (recusa silenciosa, sem aviso separado).")

  MamuteHelp_Add("LOAD", "Comandos",
    "**Carrega um arquivo na memoria simulada** - totalmente interativo, diferente do manual " +
    "original: nao se digita nome de arquivo nem `CAS:`/`A:` no comando. Basta digitar `LOAD` " +
    "sozinho:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>LOAD" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Um nome de arquivo pode ser digitado depois do `LOAD` (`MON>LOAD alfabeto.alf`) - mas ele NAO " +
    "carrega nada sozinho, so pre-preenche o campo de nome na janela de escolher arquivo e " +
    "acrescenta a extensao dele ao filtro padrao (nesse exemplo, o filtro passa a mostrar " +
    "`*.alf;*.bin;*.rom`). O arquivo que de fato vai ser carregado e sempre o que for confirmado na " +
    "janela." + #CRLF$ + #CRLF$ +
    "Uma janela normal de escolher arquivo do Windows abre primeiro. Cancelar a escolha cancela o " +
    "comando inteiro, sem gravar nada." + #CRLF$ + #CRLF$ +
    "Em seguida, **sempre** e perguntado em qual **Slot (0-3)** carregar - o slot que tiver RAM " +
    "configurada (`Configurar -> Mamute Assembler...`) e sugerido como padrao, mas qualquer slot " +
    "pode ser escolhido." + #CRLF$ + #CRLF$ +
    "**O que acontece depois depende da extensao do arquivo:**" + #CRLF$ +
    "- **`.ROM`** (cartucho) - carregado a partir do endereco `4000` (Pagina 1). Se tiver mais de " +
    "16KB (ate 32KB), ocupa tambem a Pagina 2 (`8000`). Arquivos com mais de 32KB nao sao " +
    "suportados (precisariam de troca de banco, que este simulador nao faz) - `?ROM MAIOR QUE " +
    "32KB NAO SUPORTADA`." + #CRLF$ +
    "- **Binario com cabecalho BLOAD** (qualquer outra extensao, ex.: `.bin`) - se o arquivo " +
    "comecar com o cabecalho real do BSAVE do MSX (byte `FE` seguido de endereco inicial/final/" +
    "execucao, 2 bytes cada), carrega automaticamente no endereco indicado pelo cabecalho." + #CRLF$ +
    "- **Binario sem cabecalho** - se nao comecar com `FE`, pergunta o **endereco inicial** (hexa) " +
    "antes de carregar." + #CRLF$ + #CRLF$ +
    "**`.CAS` ainda nao e suportado** - mostra `?ARQUIVOS .CAS NAO SUPORTADOS AINDA` e cancela, em " +
    "vez de tentar interpretar errado." + #CRLF$ + #CRLF$ +
    "Ao final, o resultado e mostrado no log: `CARREGADO NO SLOT <slot> EM <endereco> - TAMANHO " +
    "<tamanho> - FIM <endereco final>`." + #CRLF$ + #CRLF$ +
    "**Diferente do `DM`/`MS`**: `LOAD` grava DIRETO na memoria fisica do slot escolhido, " +
    "independente do que o `PAGE` tem mapeado ativo agora (simula " + Chr(34) +
    "inserir um cartucho/carregar dado naquele slot" + Chr(34) + ", nao escrever pela CPU). " +
    "Tambem ajusta a configuracao fisica das paginas tocadas (RAM pro binario, ROM pro `.rom`) - " +
    "mas so em memoria, nunca grava em `mamute_settings.json`; fechar e reabrir a janela do Mamute " +
    "Assembler volta pra configuracao salva de antes, igual desligar e ligar um MSX de verdade " +
    "tira o cartucho.")

  MamuteHelp_Add("SAVE", "Comandos",
    "**Grava um bloco de memoria num arquivo** - o inverso do `LOAD`, tambem com janela propria " +
    "(diferente do `SAVE <arquivo>,<endi>,<endf>,[<ende>]` de linha de comando do manual original: " +
    "aqui o nome e os enderecos digitados no comando so PRE-PREENCHEM a janela, nunca gravam nada " +
    "sozinhos)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>SAVE [<nome>][,<endinic>,<endfim>[,<endexec>]]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Tudo opcional - `MON>SAVE` sozinho abre a janela em branco. `<nome>` sugere o campo Arquivo. " +
    "Se `<endinic>`/`<endfim>` forem informados (sempre os dois juntos, `<endexec>` opcional " +
    "separado - vazio assume igual ao inicial), pre-preenchem os campos de endereco - a janela " +
    "abre mesmo assim, so ja vem com esses valores prontos. Exemplo:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>SAVE rom.bin,4000,7FFF" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "**Campos da janela:**" + #CRLF$ +
    "- **Arquivo** - campo editavel + botao " + Chr(34) + "..." + Chr(34) + " (janela normal de " +
    "Salvar Como do Windows)." + #CRLF$ +
    "- **Slot (0-3)** - de qual slot fisico ler os bytes. Sugerido a partir do que o `PAGE` tem " +
    "mapeado ATIVO agora na pagina do endereco inicial - sempre editavel pra qualquer slot." + #CRLF$ +
    "- **Endereco inicial / final** - o bloco a gravar (inclusive nos dois extremos), obrigatorios " +
    "na hora de salvar." + #CRLF$ +
    "- **Endereco de execucao** - vai no cabecalho; deixar vazio usa o mesmo valor do inicial " +
    "(mesma regra do manual original)." + #CRLF$ +
    "- **Formato** - `BIN` (cabecalho real do BSAVE do MSX: byte `FE` + inicial + final + execucao, " +
    "2 bytes cada) ou `ROM` (mesma ideia, mas com `AB` no lugar do `FE` - formato proprio deste " +
    "simulador, NAO e o cabecalho real de 16 bytes de um cartucho MSX de verdade). Sugerido " +
    "automaticamente como `ROM` se o nome do arquivo terminar em `.rom` (ou `BIN` caso contrario), " +
    "mas pode ser trocado livremente - o que valer na hora de gravar e sempre o combo, nao a " +
    "extensao." + #CRLF$ +
    "- **Salvar sem cabecalho** - checkbox: se marcado, grava so os bytes crus, sem `FE`/`AB`/" +
    "enderecos nenhum na frente, ignorando o Formato escolhido." + #CRLF$ + #CRLF$ +
    "Ao gravar com sucesso, confirma no log do `MON>`: `SALVO " + Chr(34) + "<arquivo>" + Chr(34) +
    " - SLOT <slot> - <inicial>-<final> - TAMANHO <tamanho>`." + #CRLF$ + #CRLF$ +
    "**Igual o `LOAD`**: le DIRETO de `MamuteMem(Slot,...)`, sem passar pelo `PAGE` - o slot lido e " +
    "sempre exatamente o escolhido na janela, nao o que estiver mapeado ativo no momento.")

  MamuteHelp_Add("M", "Comandos",
    "**Edicao rapida de memoria** - mesma grade de 128 bytes (16 linhas de 8, hexa+ASCII) e mesma " +
    "navegacao do `DM` (setas, `PgUp`/`PgDn`, `TAB`, botoes, `+`/`-` pro deslocamento da " +
    "interpretacao ASCII exibida) - a diferenca e como um byte e editado." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>M [<endereco>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endereco>` opcional (hexa) - se nao for informado, a janela reabre exatamente onde ficou da " +
    "ultima vez (so funciona depois que o `M` ja abriu pelo menos uma vez nesta sessao)." + #CRLF$ + #CRLF$ +
    "**Editar um byte** - com o cursor no bloco hexa, digite dois digitos hexa (`0-9`, `A-F`) " +
    "DIRETO, sem abrir campo de edicao nenhum: o primeiro digito fica mostrado com um " + Chr(34) +
    "_" + Chr(34) + " no lugar do segundo (ex.: `3_`) esperando o proximo; o segundo confirma o " +
    "byte inteiro (`3F`) e avanca o cursor sozinho pro proximo endereco. `ESC` cancela o primeiro " +
    "digito se ainda estiver pendente, ou sai da janela se nao houver nada pendente. `RETURN` " +
    "sempre sai da janela." + #CRLF$ + #CRLF$ +
    "O bloco de texto (ASCII) e SOMENTE LEITURA neste comando - `TAB` ainda alterna o destaque " +
    "visual entre hexa/texto (so pra acompanhar o `DM`), mas nao abre edicao no bloco de texto." + #CRLF$ + #CRLF$ +
    "Escrita **so tem efeito em celulas mapeadas como RAM agora** (`PAGE`) - mesma regra do `DM`.")

  MamuteHelp_Add("S", "Comandos",
    "**Igual ao `M`** (mesma grade, mesma navegacao, mesmo jeito de editar um byte digitando dois " +
    "digitos hexa direto) - a UNICA diferenca e QUAIS teclas do teclado representam cada digito " +
    "hexa. Em vez de `0-9`/`A-F` fixos, usa um teclado numerico reduzido configuravel em " +
    "**Configurar -> Mamute Assembler...** - por padrao:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "1 2 3 4        1 2 3 4" + #CRLF$ +
    "Q W E R   =>   5 6 7 8" + #CRLF$ +
    "A S D F        9 A B C" + #CRLF$ +
    "Z X C V        D E F 0" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "(o mesmo layout classico de teclado numerico usado em varios emuladores - as 4 fileiras da " +
    "esquerda do teclado QWERTY). Qualquer uma das 16 teclas pode ser trocada individualmente na " +
    "tela de configuracao pra qualquer letra ou digito." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>S [<endereco>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endereco>` opcional, mesma regra do `M` - mas o `S` guarda seu proprio " + Chr(34) +
    "ultimo endereco" + Chr(34) + ", separado do `M`.")

  MamuteHelp_Add("C", "Comandos",
    "**Escolhe o modo de exibicao** que os comandos `D`, `P` e `V` (dump de memoria formatado) " +
    "vao usar. Sozinho nao mostra nada alem da confirmacao - so guarda a escolha pra esses tres " +
    "comandos consultarem." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>C <modo>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<modo>` de `0` a `3`:" + #CRLF$ +
    "- **`0`** - hexadecimal + ASCII, 4 bytes por linha." + #CRLF$ +
    "- **`1`** - igual ao `0`, mas 16 bytes por linha (pra telas/impressoras de 80 colunas)." + #CRLF$ +
    "- **`2`** - so hexadecimal, 8 bytes por linha, com um checksum no final de cada linha = soma " +
    "dos 8 bytes + o byte baixo do endereco inicial da linha (tudo modulo 256)." + #CRLF$ +
    "- **`3`** - igual ao `2`, mas o checksum e so a soma dos bytes, sem somar o endereco." + #CRLF$ + #CRLF$ +
    "Exemplo:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>C 1" + #CRLF$ +
    "MODO 1: HEXA+ASCII, 16 BYTES/LINHA" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "*Nota: precisa de espaco entre `C` e o numero (`C 1`) - o `C1` colado do manual original do " +
    "MegaAssembler nao e reconhecido, porque todo comando aqui separa o verbo dos argumentos pelo " +
    "primeiro espaco digitado.*" + #CRLF$ + #CRLF$ +
    "O modo escolhido dura so enquanto a janela do Mamute Assembler estiver aberta - fechar e " +
    "reabrir volta pro modo `0`.")

  MamuteHelp_Add("D", "Comandos",
    "**Despejo formatado de memoria, direto no log do `MON>`** - mesma memoria RAM/ROM que o `DM` " +
    "enxerga (`Mamute_ReadByte`, resolve pelo mapeamento `PAGE` ativo agora), formatado conforme " +
    "o modo escolhido em `C` (padrao: modo `0`)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>D <endinic>[,<endfim>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Sem `<endfim>`, mostra so 16 bytes a partir de `<endinic>`. Com os dois, mostra o intervalo " +
    "inteiro (inclusive) - `<endfim>` nao pode ser menor que `<endinic>`, e nenhum dos dois " +
    "passa de `FFFF` (sem dar a volta pro `0000` como o `SH`/`M` fazem)." + #CRLF$ + #CRLF$ +
    "Exemplo:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>D 4000,400F" + #CRLF$ +
    "```")

  MamuteHelp_Add("P", "Comandos",
    "**Igual ao `D`**, mas ao inves de mandar o despejo pro log, gera uma listagem num arquivo " +
    "**PDF A4** (fonte Courier, cabecalho com o intervalo/modo usado) e abre uma janela " +
    Chr(34) + "Salvar como" + Chr(34) + " no final. Simula " + Chr(34) + "a impressora" + Chr(34) +
    " do MegaAssembler original - um driver de verdade pra impressora Epson FX-80 " +
    "(ponto-a-ponto, matriz de pontos) e um projeto separado pra uma sessao futura; por enquanto " +
    "o PDF resolve a listagem." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>P <endinic>[,<endfim>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Mesmas regras de `<endinic>`/`<endfim>` do `D` (le a mesma RAM/ROM mapeada agora). " +
    "Cancelar a janela " + Chr(34) + "Salvar como" + Chr(34) + " nao gera arquivo nenhum - so " +
    "mostra `CANCELADO`.")

  MamuteHelp_Add("V", "Comandos",
    "**Igual ao `P`**, mas le da **VRAM simulada** em vez da RAM/ROM - endereco plano, sem " +
    "`PAGE` nem banco algum (a VRAM de verdade de um MSX nunca fica mapeada no espaco de " +
    "enderecos do Z80; e acessada pelas portas do VDP, entao esta ferramenta simula ela num " +
    "bloco de memoria a parte, `Configurar -> Mamute Assembler...` -> tamanho de VRAM: **16KB** " +
    "(MSX1, mesmo tamanho que o MegaAssembler original enxergava), **128KB** ou **192KB** " +
    "(MSX2/2+, ampliacao desta ferramenta sobre o original)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>V <endinic>[,<endfim>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endinic>`/`<endfim>` aqui podem ter ate 5 digitos hexa (a VRAM maxima configuravel, 192KB, " +
    "passa de `FFFF`) e sao validados contra o tamanho de VRAM configurado agora - passar do teto " +
    "e `?ERRO DE SINTAXE`, sem dar a volta." + #CRLF$ + #CRLF$ +
    "*Nota: ainda nao existe nenhum comando que ESCREVA na VRAM simulada nesta versao (isso fica " +
    "pra uma sessao futura - `VLOAD`/`VSAVE` ou uma extensao do `LOAD`/`SAVE`) - por enquanto ela " +
    "comeca sempre zerada.*")

  MamuteHelp_Add("T", "Comandos",
    "**Transfere (copia) um bloco de memoria** RAM/ROM (mesma memoria mapeada agora pelo `PAGE`) de " +
    "um intervalo de enderecos pra outro." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>T <endinic>,<endfim>,<enddest>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Copia o bloco de `<endinic>` a `<endfim>` (inclusive) pro bloco do mesmo tamanho iniciado em " +
    "`<enddest>`. Exemplo:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>T 4000,7FFF,8000" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "copia o bloco de `4000` a `7FFF` para `8000` em diante." + #CRLF$ + #CRLF$ +
    "Se origem e destino se sobrepoem, a copia e feita na ordem certa pra nao corromper dado ainda " +
    "nao lido (de tras pra frente quando o destino vem depois da origem, de frente pra tras caso " +
    "contrario) - mesmo cuidado de um `memmove` de verdade." + #CRLF$ + #CRLF$ +
    "`<endfim>` nao pode ser menor que `<endinic>`, e o bloco copiado nao pode passar de `FFFF` no " +
    "destino (sem dar a volta pro `0000`) - qualquer um dos dois casos e `?ERRO DE SINTAXE`. Escrita " +
    "silenciosa em celulas do destino que nao sejam RAM (mesma regra do `DM`/`MS`).")

  MamuteHelp_Add("F", "Comandos",
    "**Preenche um bloco de memoria** RAM/ROM (mesma memoria mapeada agora pelo `PAGE`) inteiro com " +
    "um unico byte repetido." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>F <endinic>,<endfim>,<byte>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Exemplo:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>F 8000,C000,FF" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "preenche o bloco de `8000` a `C000` (inclusive) com `FF` em todo byte." + #CRLF$ + #CRLF$ +
    "`<endfim>` nao pode ser menor que `<endinic>`. Escrita silenciosa em celulas que nao sejam RAM " +
    "(mesma regra do `DM`/`MS`/`T`).")

  MamuteHelp_Add("G", "Comandos",
    "**Ainda NAO executa nada** - por enquanto so reconhece e valida a sintaxe do comando, " +
    "confirmando no log que o Mamute Assembler entendeu o pedido. A execucao de verdade de " +
    "programas na memoria simulada (com breakpoints, registradores etc.) fica pra uma fase futura " +
    "deste projeto." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>G <endinic>[,<brkpnt1>[,<brkpnt2>]]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endinic>` (obrigatorio) e ate dois enderecos de breakpoint opcionais - todos validados como " +
    "endereco hexa de 4 digitos, mesma sintaxe planejada pro comando de verdade quando existir " +
    "(iniciaria a execucao em `<endinic>`, carregando os registradores com o que o `X` guardou, " +
    "parando ao atingir `<brkpnt1>`/`<brkpnt2>`).")

  MamuteHelp_Add("X", "Comandos",
    "**Mostra ou edita os registradores do Z80 simulado.** Sem argumento, mostra os 7 pares de " +
    "registrador de uma vez. Com argumento, entra num modo de edicao sequencial - aceita tanto um " +
    "PAR de registrador (`AF`, `BC`, `DE`, `HL`, `IX`, `IY`, `SP` - editado como um valor unico de " +
    "16 bits/4 digitos hexa) quanto um registrador de UM BYTE isolado (`A`, `F`, `B`, `C`, `D`, " +
    "`E`, `H`, `L` - 2 digitos hexa)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>X [<reg>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Exemplos:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>X" + #CRLF$ +
    "AF=0000 BC=0000 DE=0000 HL=0000" + #CRLF$ +
    "IX=0000 IY=0000 SP=0000" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>X BC" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "abre uma caixa de dialogo perguntando o novo valor de `BC` (valor atual ja preenchido) - " +
    "confirmar com **ENTER sem editar mantem** o valor (e passa pro proximo registrador da " +
    "sequencia: `DE`, `HL`, `IX`, `IY`, `SP`); **apagar o campo e confirmar (ou Cancelar)** para a " +
    "edicao inteira." + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>X A" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "mesma ideia, mas caminhando pelos BYTES isolados: `A`, `F`, `B`, `C`, `D`, `E`, `H`, `L`." + #CRLF$ + #CRLF$ +
    "*Nota: o manual original do MegaAssembler so tem os registradores de 1 byte (`A`-`L`) mais " +
    "`X`/`Y`/`S` como abreviacao de `IX`/`IY`/`SP` - os nomes de par diretos (`AF`/`BC`/`DE`/`HL`) " +
    "editaveis como um valor so de 16 bits sao uma extensao desta ferramenta, pedida explicitamente " +
    "pelo usuario.*" + #CRLF$ + #CRLF$ +
    "Os registradores duram so enquanto a janela do Mamute Assembler estiver aberta - fechar e " +
    "reabrir zera todos de novo (mesmo espirito volatil do `PAGE`/`C`). Quando o comando `G` " +
    "(execucao de programas) for implementado de verdade, vai carregar o Z80 simulado com estes " +
    "valores.")

  MamuteHelp_Add("R", "Comandos",
    "**Ainda NAO faz nada alem de confirmar no log** que o carregamento de um programa assemblado " +
    "(gravado pela opcao `I` do comando `A` do manual original) depende do assemblador Z80 embutido " +
    "nesta ferramenta - que tambem fica pra uma fase futura. Nenhum argumento e validado por " +
    "enquanto." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>R [<offset>]" + #CRLF$ +
    "```")

  MamuteHelp_Add("L", "Comandos",
    "**Disassembla a memoria RAM/ROM** (mesma memoria mapeada agora pelo `PAGE`) direto no log do " +
    "`MON>` - um disassembler Z80 de verdade, com o conjunto de instrucoes documentado inteiro mais " +
    "as formas nao documentadas mais estaveis/conhecidas (`IXH`/`IXL`/`IYH`/`IYL`, formas indexadas " +
    "do `CB` com copia-sombra)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>L [<endinic>[,<endfim>]]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "- **Os dois enderecos** - disassembla de `<endinic>` ate ultrapassar `<endfim>` (a instrucao " +
    "que comeca dentro do intervalo entra inteira, mesmo que os ultimos bytes dela passem um pouco " +
    "de `<endfim>`)." + #CRLF$ +
    "- **So `<endinic>`** - disassembla exatamente 10 instrucoes a partir dali." + #CRLF$ +
    "- **Nenhum endereco** - continua de onde o `L`/`LP` mais recente parou, tambem 10 instrucoes." + #CRLF$ + #CRLF$ +
    "Cada linha mostra o endereco, os bytes crus em hexa (1 a 4 bytes, conforme o tamanho da " +
    "instrucao) e o mnemonico com os operandos - saltos relativos (`JR`/`DJNZ`) ja mostram o " +
    "**endereco de destino absoluto**, nao o deslocamento cru." + #CRLF$ + #CRLF$ +
    "Exemplo:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>L 4000,4010" + #CRLF$ +
    "4000  E5           PUSH HL" + #CRLF$ +
    "4001  CD 39 54     CALL 5439" + #CRLF$ +
    "4004  44           LD B,H" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "*Nota: o `<CTRL+STOP>` do manual original pra interromper a disassemblagem no meio nao se " +
    "aplica aqui - a listagem inteira e calculada de uma vez, nao ha nada rodando em tempo real pra " +
    "interromper.*")

  MamuteHelp_Add("LP", "Comandos",
    "**Igual ao `L`**, mas ao inves de mandar a listagem pro log, gera um arquivo **PDF A4** (fonte " +
    "Courier) e abre uma janela " + Chr(34) + "Salvar como" + Chr(34) + " no final - mesma ideia do " +
    "`P`/`V` (a impressora Epson FX-80 de verdade fica pra uma sessao futura, projeto separado do " +
    "usuario)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>LP [<endinic>[,<endfim>]]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Mesmas regras de `<endinic>`/`<endfim>` do `L` (inclusive continuar de onde o `L`/`LP` mais " +
    "recente parou, se nenhum endereco for passado). Cancelar a janela " + Chr(34) + "Salvar como" +
    Chr(34) + " nao gera arquivo nenhum - so mostra `CANCELADO`.")

  MamuteHelp_Add("CLS", "Comandos",
    "**Limpa a tela** - apaga todo o conteudo do log do `MON>` (rolagem, banner de abertura, historico " +
    "de comandos anteriores - tudo), deixando a janela em branco pronta pra continuar. Nao afeta " +
    "memoria/PAGE/registradores/historico de comandos digitados (Cima/Baixo continuam navegando " +
    "normalmente) - so' o texto visivel no log e' apagado. Sem argumentos.")

  MamuteHelp_Add("CL", "Comandos",
    "**Calculadora** - converte um numero (ou avalia uma expressao matematica inteira) e mostra o " +
    "resultado em quatro formatos de uma vez: **HEX**, **BIN** (16 bits), **DEC+** (decimal sem " +
    "sinal, 0-65535) e **DEC+-** (decimal com sinal, -32768 a 32767) - tudo sempre em **16 bits**, " +
    "com wraparound (mesma convencao de endereco do resto do Mamute: um resultado " + Chr(34) +
    "grande demais" + Chr(34) + " so' da a volta, nunca da erro por estourar)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>CL <expressao>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "**Numeros** seguem a mesma convencao de sempre - **hexa por padrao**, sem precisar de sufixo " +
    "nenhum - mas o `CL`, diferente do resto do Mamute, tambem aceita sufixos opcionais no final " +
    "de cada numero pra escolher outra base: **`D`/`d`** (decimal), **`B`/`b`** (binario), " +
    "**`H`/`h`** (hexa, redundante com o padrao) e **`O`/`o`** (octal). O sufixo so' vale se os " +
    "digitos antes dele forem validos naquela base - `10D` vira decimal 10 (nao hexa `10D`), " +
    "porque `10` e' decimal valido; pra hexa de verdade nesse caso especifico, use o sufixo `H` " +
    "explicito (`10DH`)." + #CRLF$ + #CRLF$ +
    "**Alem de um numero isolado, aceita expressoes matematicas completas**, com a precedencia " +
    "classica (do mais apertado pro mais frouxo: unarios primeiro, depois `*`/`/`/`%`, depois " +
    "`+`/`-`, depois `&`, depois `^`, depois `|`) e **parenteses** pra mudar a ordem:" + #CRLF$ + #CRLF$ +
    "- **`+`** soma, **`-`** subtracao (binaria) ou troca de sinal (unaria)." + #CRLF$ +
    "- **`*`** multiplicacao, **`/`** divisao inteira, **`%`** modulo (resto da divisao)." + #CRLF$ +
    "- **`|`** OR bit a bit, **`&`** AND bit a bit, **`^`** XOR bit a bit." + #CRLF$ +
    "- **`!`** NOT bit a bit (unario - complemento de todos os 16 bits)." + #CRLF$ +
    "- **`( )`** agrupam sub-expressoes, mudando a ordem normal de avaliacao." + #CRLF$ + #CRLF$ +
    "Divisao ou modulo por zero mostram `?DIVISAO POR ZERO`; qualquer outro erro (numero invalido, " +
    "parenteses sobrando, caractere desconhecido) mostra `?ERRO DE SINTAXE` (ou `?NUMERO INVALIDO: " +
    "<token>` quando da pra apontar exatamente qual pedaco falhou)." + #CRLF$ + #CRLF$ +
    "**`@<nome>`** (`@0`-`@3`/`@B`/`@E`/`@S`) - uma das 7 variaveis de debugger do SUPER-X ja " +
    "definidas (ver Introducao) tambem pode entrar numa expressao, virando o NUMERO gravado nela " +
    "(sem slot) - `CL @1+1` soma 1 ao endereco de `@1`, exemplo direto do manual original." + #CRLF$ + #CRLF$ +
    "Exemplos:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>CL 4000" + #CRLF$ +
    "HEX  : 4000H" + #CRLF$ +
    "BIN  : 0100000000000000" + #CRLF$ +
    "DEC+ : 16384" + #CRLF$ +
    "DEC+-: 16384" + #CRLF$ + #CRLF$ +
    "MON>CL (100H+2ADH)*3-1" + #CRLF$ +
    "HEX  : 0B06H" + #CRLF$ +
    "BIN  : 0000101100000110" + #CRLF$ +
    "DEC+ : 2822" + #CRLF$ +
    "DEC+-: 2822" + #CRLF$ +
    "```")

  MamuteHelp_Add("XD", "Comandos",
    "**Porta do comando `D` do monitor SUPER-X** (`docs/SPEC.md`, modulo 45) - batizado `XD` (nao " +
    "`D`) porque o Mamute ja tem seu proprio `D` (despejo formatado pro log, ao lado), com significado " +
    "diferente. Igual ao SUPER-X original, o comportamento muda conforme quantos enderecos sao " +
    "informados." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XD [<endereco>|@<var>]" + #CRLF$ +
    "MON>XD <endinic>,<endfim>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "*`<endereco>` aceita o sufixo `[#<slot>[-<subslot>]|#V|#4|#S|#5]` (ver abaixo), OU `@<nome>` " +
    "(`@0`-`@3`/`@B`/`@E`/`@S`) - uma das 7 variaveis de debugger do SUPER-X ja definidas (ver " +
    "Introducao) substitui o endereco INTEIRO (numero + slot/sub-slot/VRAM juntos).*" + #CRLF$ + #CRLF$ +
    "**Um endereco (ou nenhum)** - abre uma janela separada com a mesma grade de 128 bytes " +
    "(hexa+ASCII) do `DM`/`M`, navegacao identica (setas/`PgUp`/`PgDn`/`TAB`/botoes/`+`/`-`). Sem " +
    "endereco, reabre onde a janela do `XD` ficou da ultima vez, **incluindo o mesmo alvo** (slot/" +
    "sub-slot/VRAM - so funciona depois que o `XD` ja abriu ao menos uma vez nesta sessao)." + #CRLF$ + #CRLF$ +
    "**Enderecamento estendido do SUPER-X** - um sufixo opcional depois do endereco escolhe ONDE " +
    "ler/gravar, ignorando o `PAGE` corrente pelo resto da sessao dessa janela:" + #CRLF$ +
    "- **`#<slot>`** (0-3) - le/edita o slot PRIMARIO informado direto, mesmo que ele nao esteja " +
    "comutado em nenhuma pagina agora (ex.: `XD C000#3`)." + #CRLF$ +
    "- **`#<slot>-<subslot>`** (subslot 0-3) - slot EXPANDIDO: MSX de verdade suportava ate 1MB de " +
    "RAM assim (4 slots primarios x 4 sub-slots x 64KB - existiu ate cartucho comercial de RAM de " +
    "64KB pra rodar CP/M com RAMDISK). Sub-slot omitido assume sub-slot 0 (o Mamute ainda nao " +
    "simula um " + Chr(34) + "registrador de sub-slot ativo" + Chr(34) + " por slot - isso e' " +
    "emulacao de hardware de verdade, escopo do debugger/`G`, nao deste parser de endereco). Sub-" +
    "slots 1-3 comecam **sempre como RAM gravavel** (sem Vazio/ROM/BASIC por celula ainda - nao " +
    "existe tela de configuracao fisica por sub-slot)." + #CRLF$ +
    "- **`#V`/`#4`** - mira a VRAM simulada (mesma do `V`/`P`) em vez da RAM/ROM - endereco pode ir " +
    "ate 5 digitos (o teto configurado em `Configurar -> Mamute Assembler...`), e' a **primeira " +
    "forma de ESCREVER na VRAM** do Mamute (antes so' V/P liam)." + #CRLF$ +
    "- **`#S`/`#5`** - " + Chr(34) + "estado de slot normal (de boot)" + Chr(34) + " - como o Mamute " +
    "nao guarda um estado de boot separado, e' so' sinonimo explicito de nao informar sufixo " +
    "nenhum (usa o `PAGE` corrente)." + #CRLF$ + #CRLF$ +
    "**Diferencas do `M`/`S`:**" + #CRLF$ +
    "- **O bloco ASCII tambem e editavel** (no `M`/`S` ele e so leitura). Pressione `" + Chr(34) +
    "` (aspas) pra entrar em digitacao ASCII direta - a partir dai, cada tecla impressa (inclusive " +
    "`" + Chr(34) + "`/`@` literais) grava um byte cru no cursor e avanca sozinho, sem precisar de " +
    "`ENTER` a cada caractere (mesma formula do bloco de texto do `DM`: `(codigo do char - " +
    "deslocamento) & FF`). `ESC` sai da digitacao ASCII (um segundo `ESC`, fora dela, fecha a " +
    "janela)." + #CRLF$ +
    "- **`@` repete o byte anterior** - com o cursor no bloco hexa (fora da digitacao ASCII), `@` le " +
    "o byte em `endereco-1` e grava no cursor, avancando - util pra preencher sequencias repetidas " +
    "rapido." + #CRLF$ +
    "- `SHIFT`+Cima/Baixo funcionam como sinonimo de `PgUp`/`PgDn` (a doc do SUPER-X lista os dois)." + #CRLF$ + #CRLF$ +
    "**Dois enderecos** - NAO abre grade nenhuma, so despejo direto no log do `MON>` (doc do SUPER-X: " +
    Chr(34) + "Two Addresses: give a non stop list output" + Chr(34) + "). `<endfim>` nao pode ser " +
    "menor que `<endinic>`. `<endinic>` aceita o MESMO sufixo de alvo do endereco unico acima " +
    "(`#slot[-sub]`/`#V`/`#S`) - nao e' PAGE-relativo apenas." + #CRLF$ + #CRLF$ +
    "**Formato FIXO, sempre 8 bytes/linha, hexa + checksum + ASCII juntos** (pedido explicito do " +
    "usuario):" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "AAAA XX XX XX XX XX XX XX XX : YY : QQQQQQQQ" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`AAAA` = endereco da linha, `XX` = os bytes (ate 8), `YY` = checksum de 1 byte (soma dos bytes " +
    "da linha, com wraparound em 8 bits), `QQQQQQQQ` = ASCII dos mesmos bytes (`.` pros nao-" +
    "imprimiveis). **`XCS`** (ao lado) alterna COMO `YY` e' calculado: **NORMAL** (so' os bytes, " +
    "padrao) ou **+ADDR** (soma tambem o byte baixo `AAAA & FF` de cada linha) - vale tanto pro " +
    "despejo no log quanto pro PDF (`?XD`, abaixo)." + #CRLF$ + #CRLF$ +
    "**`?XD <endinic>,<endfim>`** - " + Chr(34) + "impressora" + Chr(34) + " do SUPER-X (`?` na frente " +
    "do comando, ver Introducao ao lado) - em vez de mandar a mesma listagem pro log, gera um PDF A4 " +
    "(fonte Courier, igual `P`/`LP`) e abre " + Chr(34) + "Salvar como" + Chr(34) + " no final. So' " +
    "funciona com DOIS enderecos (uma listagem estatica faz sentido pra imprimir; a grade interativa " +
    "de UM endereco, nao) - `?XD <endereco>` sozinho mostra `?IMPRESSAO SO FUNCIONA COM DOIS " +
    "ENDERECOS`. Cancelar a janela " + Chr(34) + "Salvar como" + Chr(34) + " nao gera arquivo nenhum - " +
    "so mostra `CANCELADO`." + #CRLF$ + #CRLF$ +
    "Escrita **so tem efeito em celulas mapeadas como RAM agora** - slot/sub-slot 0 respeitam a " +
    "configuracao fisica de `Configurar -> Mamute Assembler...` (mesma regra do `DM`/`M`); sub-slots " +
    "1-3 sao sempre RAM gravavel (ver acima); VRAM (`#V`) sempre aceita escrita.")

  MamuteHelp_Add("XM", "Comandos",
    "**Porta do comando `M` do monitor SUPER-X** (`docs/SPEC.md`, modulo 45) - batizado `XM` (nao " +
    "`M`) porque o Mamute ja tem seu proprio `M` (grade de edicao rapida, ao lado), com significado " +
    "diferente. Abre uma janela separada com um prompt " + Chr(34) + "endereco>" + Chr(34) + " (estilo " +
    "`MON>`, mesma paleta verde-sobre-preto) que **monta instrucoes Z80 de verdade direto na memoria** " +
    "conforme voce digita - o assembler nativo do projeto por baixo (`Z80Asm.pbi`, o mesmo motor do " +
    "comando `A` do `EDIT`), sem precisar montar um programa inteiro." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XM [<endereco>|@<var>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "*`<endereco>` aceita o sufixo `[#<slot>[-<subslot>]|#V|#4|#S|#5]` (ver `XD`) OU `@<nome>` " +
    "(uma das 7 variaveis de debugger do SUPER-X, ver Introducao) - vale tanto na abertura quanto em " +
    "qualquer linha `ENDERECO...` dentro da sessao.*" + #CRLF$ + #CRLF$ +
    "Sem endereco, reabre onde a janela do `XM` ficou da ultima vez (mesmo endereco E mesmo alvo). A " +
    "cada linha aceita, o endereco **avanca sozinho** pelo tamanho do que foi gravado - digite a " +
    "proxima instrucao/dado direto, sem repetir o endereco." + #CRLF$ + #CRLF$ +
    "**Enderecamento estendido do SUPER-X** - o sufixo `#slot[-subslot]`/`#V`/`#4`/`#S`/`#5` funciona " +
    "exatamente como no `XD` (ver ao lado pro detalhe completo de cada um: slot primario, slot " +
    "expandido/sub-slot ate 1MB de RAM simulada, VRAM, ou o `PAGE` corrente) - a diferenca e' que " +
    "aqui o sufixo pode aparecer em QUALQUER linha que comece com endereco, nao so' na abertura, " +
    "TROCANDO o alvo da sessao inteira dali em diante (ex.: digitar `D000#3-1` no meio de uma sessao " +
    "redireciona escrita/leitura pro slot 3 sub-slot 1). **Um endereco digitado SEM sufixo mantem o " +
    "alvo atual** (nao volta pro `PAGE` sozinho - mesma regra do manual original do SUPER-X: " +
    Chr(34) + "if the slot number is left out, the CURRENT slot is assumed" + Chr(34) + "); usar `#S`/" +
    "`#5` explicito e' a unica forma de voltar pro `PAGE` corrente de proposito." + #CRLF$ + #CRLF$ +
    "**Cada linha digitada pode ser:**" + #CRLF$ + #CRLF$ +
    "- **Uma instrucao Z80** (`LD HL,1234H`, `LDIR`, `CALL 5000H`...) - monta e grava os bytes, " +
    "ecoando `ENDERECO  bytes-hexa  instrucao` no log, igual uma linha de listagem do `L`. Erros de " +
    "sintaxe do assembler (operando invalido, mnemonico desconhecido) mostram `?` + a mensagem do " +
    "assembler." + #CRLF$ +
    "- **Dados crus**, com um sinal de tipo na frente e itens separados por virgula:" + #CRLF$ +
    "  - **`.`** - 1 byte cada item (ex.: `.CD, 4DH, 00`)" + #CRLF$ +
    "  - **`:`** - 2 bytes cada item, little-endian (ex.: `:1234, ABCD`)" + #CRLF$ +
    "  - **`;`** - numerico, 2 bytes, little-endian (ex.: `;'A'*100, 18200|11b`)" + #CRLF$ +
    "  - **`[`** - numerico, 1 byte (ex.: `[100, '#'`)" + #CRLF$ +
    "  - **`" + Chr(34) + "`** - string literal crua, o resto da linha inteiro vira bytes ASCII " +
    "(ex.: `" + Chr(34) + "OLA MUNDO`, sem precisar fechar as aspas)" + #CRLF$ + #CRLF$ +
    "  Cada item de `.`/`:`/`;`/`[` passa pela **mesma calculadora do comando `CL`** " +
    "(`Mamute_CL_Eval()`) - aceita um numero simples (hexa por padrao, sufixos `D`/`B`/`H`/`O`), uma " +
    "expressao matematica completa (`+ - * / % | & ^ !`, parenteses) OU um literal ASCII entre aspas " +
    "simples/duplas (`'A'`, `" + Chr(34) + "AB" + Chr(34) + "`, ate 2 caracteres - 1 char vira o " +
    "codigo dele, 2 chars viram byte alto+byte baixo). *Cuidado com ambiguidade:* um numero como `4D` " +
    "vira **decimal 4** (sufixo `D` tem prioridade quando os digitos antes dele - aqui so `4` - sao " +
    "decimal valido), nao hexa `4Dh`; pra hexa de verdade nesse caso, use o `H` explicito (`4DH`)." + #CRLF$ +
    "- **Um endereco[#sufixo], sozinho ou seguido de um dos itens acima** (`D000` pula pra `D000` " +
    "sem gravar nada, mantendo o alvo atual; `D000#3-1 .1,2,3` pula pra `D000` NO slot 3 sub-slot 1 " +
    "e ja grava os 3 bytes ali) - so reconhecido quando o primeiro token bate como endereco[#sufixo] " +
    "valido E NAO for um mnemonico Z80 valido (evita ambiguidade real com `DAA`/`CCF`, os unicos dois " +
    "mnemonicos sem operando que tambem sao hexa valido - digitar `DAA` sozinho monta a instrucao, " +
    "nao pula pro endereco `0DAAh`)." + #CRLF$ +
    "- **`I [<n>]`** - lista as proximas `<n>` instrucoes (padrao 20, aceita expressao da " +
    "calculadora) a partir do endereco atual, so leitura, nao grava nem avanca nada - mesmo " +
    "disassembler do `L`/`LP`. *So funciona com o alvo `PAGE` corrente (sem `#slot`/`#V` ativo)* - o " +
    "disassembler ainda so' le pelo mapeamento `PAGE`, nao entende slot/sub-slot/VRAM explicito " +
    "ainda; usando um alvo explicito, `I` mostra um erro em vez de bytes errados." + #CRLF$ + #CRLF$ +
    "**Navegacao no campo de entrada:** Cima/Baixo percorrem as linhas ja digitadas nesta sessao da " +
    "janela (mesmo espirito do historico do `MON>`, mas so' dentro do `XM` - nao persiste entre " +
    "aberturas). `ESC` fecha a janela." + #CRLF$ + #CRLF$ +
    "Escrita **so tem efeito em celulas mapeadas como RAM agora** - slot/sub-slot 0 respeitam a " +
    "configuracao fisica (`Configurar -> Mamute Assembler...`); sub-slots 1-3 sao sempre RAM " +
    "gravavel; VRAM (`#V`) sempre aceita escrita - mesmas regras do `XD`.")

  MamuteHelp_Add("XH", "Comandos",
    "**Porta do comando `H` do monitor SUPER-X** (`docs/SPEC.md`, modulo 45) - o editor de " +
    "caracteres/sprites, ultimo modo " + Chr(34) + "Char" + Chr(34) + " da cruz que ainda faltava (ver " +
    "`XD`). Edita **4 caracteres (ou sprites - o layout de bytes e' identico) CONSECUTIVOS de uma vez** " +
    "- 32 bytes, 8 por caractere, formato padrao MSX de gerador de caracteres/padrao de sprite 8x8." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XH [<endereco>|@<var>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "*`<endereco>` aceita o sufixo `[#<slot>[-<subslot>]|#V|#4|#S|#5]` (ver `XD`) OU `@<nome>` " +
    "(uma das 7 variaveis de debugger do SUPER-X, ver Introducao).* Sem endereco, reabre onde a janela " +
    "do `XH` ficou da ultima vez (mesmo endereco E mesmo alvo)." + #CRLF$ + #CRLF$ +
    "**A grade** e' 16 linhas x 16 colunas de PIXELS (nao bytes) - cada linha e' UMA linha de pixel de " +
    "DOIS caracteres lado a lado (colunas 0-7 = caractere da esquerda, 8-F = caractere da direita), com " +
    "um cabecalho `0123456789ABCDEF` no topo marcando as colunas. As primeiras 8 linhas mostram os " +
    "caracteres 1 e 2; as ultimas 8 mostram os caracteres 3 e 4 (" + Chr(34) + "2 em cima, 2 embaixo" + Chr(34) +
    "). Pixel aceso desenha `0`, apagado desenha `-`. Cada linha termina com `ENDERECO : YY:ZZ N` - " +
    "`ENDERECO`/`YY` sao o endereco/valor do byte do caractere DA ESQUERDA nessa linha, `ZZ` e' o valor " +
    "do byte do caractere DA DIREITA na mesma linha, `N` (0-7) e' o indice da linha DENTRO do caractere." + #CRLF$ + #CRLF$ +
    "**No canto**, uma miniatura mostra os 4 caracteres ja montados lado a lado/um embaixo do outro " +
    "(16x16 pixels), exatamente como ficam de verdade numa tela MSX." + #CRLF$ + #CRLF$ +
    "**Edicao:** setas movem o cursor pela grade 16x16; `ESPACO` inverte o bit sob o cursor. Botoes " +
    "`INVERTER`/`LIMPAR`/`PREENCHER` operam sobre o **caractere onde o cursor esta agora** (nao a grade " +
    "inteira); `LIMPAR BLOCO` zera os 4 caracteres de uma vez (32 bytes). `<<`/`>>` (ou `PgUp`/`PgDn`, " +
    "`SHIFT`+Cima/Baixo) pulam 32 bytes - um bloco inteiro de 4 caracteres - pro anterior/proximo." + #CRLF$ + #CRLF$ +
    "Escrita **so tem efeito em celulas mapeadas como RAM agora** - mesmas regras do `XD`/`XM`.")

  MamuteHelp_Add("XBT", "Comandos",
    "**Transferencia de bloco entre alvos** (" + Chr(34) + "BT" + Chr(34) + " de " + Chr(34) +
    "Block Transfer" + Chr(34) + ") - versao do `T` (comando herdado do MegaAssembler, ao lado) que " +
    "entende o enderecamento estendido do SUPER-X: origem e destino podem estar em slot/sub-slot/VRAM " +
    "**DIFERENTES um do outro** (" + Chr(34) + "inclusive intra-slots" + Chr(34) + ", pedido explicito " +
    "do usuario) - o `T` comum so trabalha dentro do `PAGE` corrente, um unico espaco de 16 bits pros " +
    "tres numeros." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XBT <endinic>[#slot[-sub]|#V|#S],<endfim>,<enddest>[#slot[-sub]|#V|#S]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "- **`<endinic>`** aceita o sufixo de alvo completo (ver `XD`) - resolve ONDE o bloco de origem " +
    "comeca." + #CRLF$ +
    "- **`<endfim>`** e' sempre um endereco PURO, sem sufixo - marca o FIM do bloco de origem no MESMO " +
    "alvo que `<endinic>` ja escolheu (nao teria sentido um alvo proprio so pro fim de um bloco que " +
    "comecou noutro)." + #CRLF$ +
    "- **`<enddest>`** tambem aceita o sufixo de alvo completo, resolvido de forma **totalmente " +
    "independente** da origem - pode ser outro slot, outro sub-slot, VRAM enquanto a origem e' RAM " +
    "normal, ou vice-versa." + #CRLF$ + #CRLF$ +
    "Copia [`<endinic>`,`<endfim>`] inteiro pro bloco iniciado em `<enddest>`, avancando byte a byte. " +
    "**Sem wraparound** (mesma regra do `T`/`D`/`P`/`V`) - se `<enddest>` + o tamanho do bloco passar do " +
    "teto do ALVO DE DESTINO (FFFF pra RAM/slot, o tamanho de VRAM configurado pra `#V`), e' `?ERRO DE " +
    "SINTAXE`, nunca da a volta. Origem/destino sobrepostos (quando os dois caem no MESMO alvo de " +
    "verdade) sao tratados com o mesmo algoritmo seguro de um `memmove` que o `T` ja usa - copia de " +
    "tras pra frente quando `<enddest>` e' numericamente maior que `<endinic>`, de frente pra tras " +
    "senao; quando origem e destino sao alvos DIFERENTES essa direcao e' irrelevante pro resultado " +
    "(nao ha sobreposicao de verdade possivel), entao nenhuma deteccao extra e' necessaria." + #CRLF$ + #CRLF$ +
    "Escrita **so tem efeito em celulas do destino mapeadas como RAM agora** - slot/sub-slot 0 " +
    "respeitam a configuracao fisica (`Configurar -> Mamute Assembler...`); sub-slots 1-3 sao sempre " +
    "RAM gravavel; VRAM (`#V`) sempre aceita escrita - mesmas regras do `XD`/`XM`.")

  MamuteHelp_Add("XRT", "Comandos",
    "**Reloca um programa Z80** (" + Chr(34) + "RT" + Chr(34) + " de " + Chr(34) + "Relocating Transfer" +
    Chr(34) + ") - mesma sintaxe de 3 campos do `XBT` (ao lado), mas em vez de copiar bytes crus, " +
    "**decodifica cada instrucao** do bloco e ajusta " +
    "todo endereco absoluto embutido (`JP`/`CALL`, ponteiros `LD`) que apontava pra DENTRO do bloco " +
    "original, somando o deslocamento do movimento - pedido explicito do usuario." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XRT <endinic>[#slot[-sub]|#V|#S],<endfim>,<enddest>[#slot[-sub]|#V|#S]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Mesma regra de sufixo de alvo do `XBT` pros tres campos (`<endinic>`/`<enddest>` aceitam slot/" +
    "sub-slot/VRAM, `<endfim>` e' sempre um endereco puro no MESMO alvo de `<endinic>`) - inclusive " +
    "entre slots DIFERENTES." + #CRLF$ + #CRLF$ +
    "**O que e' ajustado**: `JP`/`CALL`/`JP cc`/`CALL cc` (endereco absoluto), `LD dd,nn` (par de " +
    "registrador com um numero de 16 bits), `LD (nn),HL`/`LD HL,(nn)`/`LD (nn),A`/`LD A,(nn)` e as " +
    "formas estendidas equivalentes (`ED`/`DD`/`FD`) - **so' quando o endereco embutido cai DENTRO** " +
    "de `[<endinic>,<endfim>]`. Um `CALL 8012H` vira `CALL C012H` ao mover `8000H` pra `C000H`, mas um " +
    "`CALL 004DH` (BIOS, endereco fora do bloco) fica **intocado** - exatamente o exemplo pedido pelo " +
    "usuario. `JR`/`DJNZ` (saltos relativos) normalmente nao precisam de ajuste nenhum quando o alvo " +
    "tambem esta dentro do bloco (origem e destino se movem juntos, a distancia relativa nao muda) - " +
    "so' recalcula o deslocamento quando o alvo de um `JR`/`DJNZ` fica FORA do bloco (salto pra codigo " +
    "fixo externo), e aborta com `?RELOCACAO INVALIDA` **sem gravar nada** se o novo deslocamento nao " +
    "couber em -128..127 depois do movimento (o bloco inteiro e' lido/decodificado pra um buffer " +
    "ANTES de qualquer escrita no destino - um erro no meio nunca deixa o destino pela metade)." + #CRLF$ + #CRLF$ +
    "**Limitacao aceita** (mesma classe de limite ja documentada no disassembler do `L`/`LP`/`XI`): " +
    "tabelas de dados inline (`DEFW` com enderecos, por exemplo) NO MEIO do codigo sao lidas como se " +
    "fossem instrucao, podendo confundir a decodificacao dali em diante - funciona bem pro caso comum " +
    "(codigo continuo, sem dados misturados no meio do fluxo), mas nao ha como garantir 100% sem " +
    "executar o programa de verdade." + #CRLF$ + #CRLF$ +
    "Escrita **so tem efeito em celulas do destino mapeadas como RAM agora** - mesmas regras do `XBT`.")

  MamuteHelp_Add("XFL", "Comandos",
    "**Preenche um bloco** - versao do `F` comum (modulo 31, ao lado) que entende o enderecamento " +
    "estendido do SUPER-X: preenche um bloco num slot/sub-slot/VRAM **explicito**, em vez de sempre " +
    "PAGE-relativo." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XFL <endinic>[#slot[-sub]|#V|#S],<endfim>,<valor>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endinic>` aceita o sufixo de alvo completo (ver `XD`); `<endfim>` e' sempre um endereco puro, " +
    "no MESMO alvo que `<endinic>` ja escolheu (mesma convencao do `XBT`/`XRT`, ao lado). `<valor>` e' " +
    "1-2 digitos hexa - o byte que preenche [`<endinic>`,`<endfim>`] inteiro." + #CRLF$ + #CRLF$ +
    "Escrita **so tem efeito em celulas mapeadas como RAM agora** - slot/sub-slot 0 respeitam a " +
    "configuracao fisica (`Configurar -> Mamute Assembler...`); sub-slots 1-3 sao sempre RAM " +
    "gravavel; VRAM (`#V`) sempre aceita escrita - mesmas regras do `XD`/`XBT`.")

  MamuteHelp_Add("XCM", "Comandos",
    "**Compara dois blocos de memoria** byte a byte - pedido explicito do usuario. Origem e bloco de " +
    "comparacao podem estar em alvos TOTALMENTE independentes (slot/sub-slot/VRAM diferentes um do " +
    "outro, mesmo espirito " + Chr(34) + "intra-slots" + Chr(34) + " do `XBT`/`XRT`/`XFL`, ao lado)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XCM <endinic>[#slot[-sub]|#V|#S],<endfim>,<endcomp>[#slot[-sub]|#V|#S][,S]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endinic>`/`<endcomp>` aceitam o sufixo de alvo completo (ver `XD`); `<endfim>` e' sempre um " +
    "endereco puro, no MESMO alvo que `<endinic>` ja escolheu (mesma convencao do `XBT`/`XRT`/`XFL`)." + #CRLF$ + #CRLF$ +
    "Compara [`<endinic>`,`<endfim>`] com o bloco de mesmo tamanho comecando em `<endcomp>`, byte a " +
    "byte. **Por padrao lista so' os bytes DIFERENTES** - uma linha por byte, endereco+valor dos dois " +
    "lados (`ENDERECO_A: VALOR_A <> ENDERECO_B: VALOR_B`), terminando com a contagem total de " +
    "diferencas. **`,S` no final inverte pro modo " + Chr(34) + "iguais" + Chr(34) + "** - lista so' os " +
    "bytes que BATEM (`ENDERECO_A: VALOR_A == ENDERECO_B: VALOR_B`) em vez dos diferentes.")

  MamuteHelp_Add("XFD", "Comandos",
    "**Procura uma instrucao Z80** dentro de um intervalo - pedido explicito do usuario: " + Chr(34) +
    "o sistema pede uma instrucao em ASM, ai ele vai listar todos os enderecos no intervalo que " +
    "tenham esta instrucao" + Chr(34) + "." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XFD <endinic>[#slot[-sub]|#V|#S],<endfim>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endinic>` aceita o sufixo de alvo completo (ver `XD`); `<endfim>` e' sempre um endereco puro, " +
    "no MESMO alvo (mesma convencao do `XBT`/`XRT`/`XFL`/`XCM`)." + #CRLF$ + #CRLF$ +
    "Depois do `ENTER`, abre uma caixa de dialogo pedindo **uma instrucao Z80** (mesma sintaxe do " +
    "`XM`/comando `A` - ex.: `CALL 8012H`). Decodifica o intervalo inteiro instrucao por instrucao " +
    "(mesmo motor do `L`/`LP`/`XI`/`XRT`) e lista o ENDERECO de toda ocorrencia onde a instrucao " +
    "encontrada bate EXATAMENTE (opcode + operando, byte a byte) com a digitada, terminando com a " +
    "contagem total. So' conta instrucao REAL, alinhada num limite de instrucao de verdade - nao e' " +
    "uma busca de bytes crua (diferente do `SH`, que acharia coincidencias no MEIO de outra " +
    "instrucao/dado)." + #CRLF$ + #CRLF$ +
    "**Limitacao aceita**: a instrucao digitada e' montada UMA unica vez, ancorada em `<endinic>` - " +
    "funciona perfeitamente pra qualquer instrucao com operando ABSOLUTO (`CALL`/`JP`/`LD nn`/etc., " +
    "que codificam sempre os MESMOS bytes independente de onde ficam), mas `JR`/`DJNZ` (saltos " +
    "RELATIVOS) codificam bytes diferentes dependendo de onde ficam - a busca so' encontra ocorrencias " +
    "na MESMA distancia relativa da instrucao digitada, nao " + Chr(34) +
    "todo JR pro mesmo alvo absoluto" + Chr(34) + " (mesmo espirito do aviso ja documentado no `XRT`).")

  MamuteHelp_Add("XCO", "Comandos",
    "**Cor da tela** - troca a paleta de cores do Mamute Assembler INTEIRO (monitor principal, `XD`/" +
    "`XM`/`XA`/`XI`/`XH`, debugger grafico, `DM`/`ZAP`/`SCR`/`M`/`EDIT`) - pedido explicito do usuario. " +
    "Porta do `CO` do SUPER-X, batizado `XCO` (nao `CO`) pra ficar consistente com o prefixo `X` de todo " +
    "o resto dos comandos portados do SUPER-X." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XCO [<frente>],[<fundo>],[<borda>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<frente>`/`<fundo>`/`<borda>` sao indices **0-15, sempre DECIMAL** (nao hexa - mesma convencao " +
    "do `COLOR frente,fundo,borda` do MSX BASIC de verdade, ja que `XCO` porta um comando de cor de " +
    "tela MSX) da paleta REAL e FIXA do MSX1/TMS9918 (a mesma paleta de sempre - nao e' editavel, " +
    "MSX1 nao tem paleta programavel)." + #CRLF$ + #CRLF$ +
    "Qualquer um dos 3 pode ficar VAZIO (virgula sem nada entre duas virgulas, ou so' nao digitar o " +
    "resto) - mantem o valor atual dessa cor sozinho, mesma convencao do `COLOR` original (`XCO ,,4` " +
    "muda so a borda). Sem argumento nenhum, `XCO` so mostra o estado atual." + #CRLF$ + #CRLF$ +
    "*Nao repinta janela nenhuma ja aberta - vale a partir da PROXIMA janela que abrir (inclusive " +
    "fechar e reabrir o proprio Mamute Assembler). Fica salvo em `mamute_settings.json` - sobrevive " +
    "entre sessoes, diferente do `XCS`/`C` (esses continuam volateis de proposito).*")

  MamuteHelp_Add("XQT", "Comandos",
    "**Encerra o Mamute Assembler** - porta do `QT` do SUPER-X (inventario do modulo 45: " +
    Chr(34) + "Sai pro BASIC" + Chr(34) + "), pedido explicito do usuario (" + Chr(34) +
    "apenas encerra o mamute assembler" + Chr(34) + "). Comportamento IDENTICO ao `BA`/`QUIT` " +
    "nativo (fecha a janela na hora, sem mensagem nenhuma no log antes) - so' mais um nome pro " +
    "mesmo efeito." + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XQT" + #CRLF$ +
    "```")

  MamuteHelp_Add("XDK", "Comandos",
    "**Escolhe/troca o disco corrente** - UNICO comando de disco que TROCA o disco corrente (os " +
    "outros - `XFS`/`XCI`/`XTP`/`XL%`/`XS%` - so' USAM o que ja esta carregado) - pedido explicito do " +
    "usuario, junto com uma mudanca drastica de design: nenhum comando de disco aceita mais nome/" +
    "sufixo de troca - " + Chr(34) + "vamos padronizar todos sem nome, o nome e' o corrente" + Chr(34) +
    "." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XDK" + #CRLF$ +
    "MON>XDK <nome>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "SEMPRE abre o dialogo " + Chr(34) + "Selecione a imagem de disco (DSK)" + Chr(34) + ", mesmo ja " +
    "tendo um disco corrente - `<nome>` (opcional) e' so' a SUGESTAO inicial do campo, nao um caminho " +
    "usado direto sem confirmar. O disco escolhido vira o novo corrente, mostrado na barra de status " +
    "(topo) como " + Chr(34) + "DISCO: <nome>" + Chr(34) + ". Cancelar preserva o disco corrente " +
    "anterior (se havia) e mostra `CANCELADO`." + #CRLF$ + #CRLF$ +
    "*Os outros comandos de disco abrem esse MESMO dialogo automaticamente, so' na PRIMEIRA vez, se " +
    "ainda nao houver disco corrente nenhum - `XDK` e' so' pra TROCAR de disco no meio de uma sessao.*")

  MamuteHelp_Add("XFS", "Comandos",
    "**Lista o diretorio do disco corrente** (equivalente ao `DIR`) - porta do `FS` do SUPER-X, " +
    "PRIMEIRO comando de disco do Mamute Assembler - pedido explicito do usuario. Usa o conceito de " +
    "**disco corrente**: um caminho de imagem `.dsk` guardado nesta sessao da janela, mostrado na " +
    "barra de status (topo) como " + Chr(34) + "DISCO: <nome>" + Chr(34) + " - compartilhado por " +
    "TODOS os comandos de disco (`XFS`/`XCI`/`XTP`/`XL%`/`XS%`)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XFS" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Sem argumento nenhum (nenhum comando de disco aceita mais nome/troca de disco - so' o `XDK`, ao " +
    "lado). Se AINDA NAO houver disco corrente, abre o dialogo " + Chr(34) +
    "Selecione a imagem de disco (DSK)" + Chr(34) + " pra escolher um antes de listar; se JA houver, " +
    "lista o diretorio dele direto, sem dialogo nenhum." + #CRLF$ + #CRLF$ +
    "*Pra trocar de disco corrente, use `XDK` primeiro.*")

  MamuteHelp_Add("XCI", "Comandos",
    "**Uso do disco corrente** - clusters livres / total de clusters - porta do `CI` do SUPER-X, " +
    "pedido explicito do usuario. Sem argumento nenhum, mesma logica de disco corrente do `XFS` (ao " +
    "lado) - sem disco corrente, abre o dialogo de escolha primeiro." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XCI" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Mostra:" + #CRLF$ +
    "```" + #CRLF$ +
    "DISCO.DSK: 342 / 714 CLUSTERS LIVRES" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "*Pra trocar de disco corrente, use `XDK` primeiro.*")

  MamuteHelp_Add("XTP", "Comandos",
    "**Visualizador de texto simples** - abre uma janela separada mostrando o conteudo de um arquivo " +
    "**dentro do disco corrente** (mesmo disco corrente do `XFS`/`XCI`, ao lado) - porta do `TP` do " +
    "SUPER-X, pedido explicito do usuario." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XTP <arquivo>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<arquivo>` e' o nome do arquivo DENTRO do disco corrente (o mesmo nome que o `XFS` lista), NAO " +
    "um caminho do computador - UNICO argumento (sem disco corrente, abre o dialogo de escolha " +
    "primeiro, mesmo idioma do `XFS`/`XCI`)." + #CRLF$ + #CRLF$ +
    "**8 botoes de navegacao**, mesmo layout do `XH`:" + #CRLF$ +
    "- **`|<`/`>|`** - INICIO/FIM do arquivo inteiro." + #CRLF$ +
    "- **`<<`/`>>`** - pagina anterior/proxima (rola 30 linhas de uma vez)." + #CRLF$ +
    "- **`^`/`v`** - linha anterior/proxima." + #CRLF$ +
    "- **`<`/`>`** - rola pros lados (colunas) - pra linhas mais compridas que a tela." + #CRLF$ + #CRLF$ +
    "Setas do teclado (cima/baixo/esquerda/direita), `PgUp`/`PgDn` e `Home`/`End` fazem o mesmo que os " +
    "botoes (desligados enquanto o campo de busca esta em foco, pra nao competir com a edicao de texto " +
    "nele); `RETURN`/`ESC` fecha a janela." + #CRLF$ + #CRLF$ +
    "**Campo de busca** - `Buscar:`, com 2 caixinhas: `Case` (marcada = diferencia maiusculas/" +
    "minusculas) e `Regex` (marcada = o texto digitado e' uma expressao regular, sintaxe padrao do " +
    "PureBasic/PCRE). Botao `BUSCAR` (ou `RETURN` com o campo em foco) acha a PROXIMA ocorrencia a " +
    "partir de onde a ultima busca parou (ou da tela atual, na primeira vez) - com wraparound pro " +
    "inicio do arquivo se chegar ao fim sem achar nada. Sem ocorrencia nenhuma, mostra " +
    Chr(34) + "NAO ENCONTRADO" + Chr(34) + "; expressao regular invalida mostra " + Chr(34) +
    "?EXPRESSAO REGULAR INVALIDA" + Chr(34) + "." + #CRLF$ + #CRLF$ +
    "*So' leitura - nao altera o arquivo no disco. Extrai pra um temporario, mostra, apaga o " +
    "temporario ao fechar.*")

  MamuteHelp_Add("XSV", "Comandos",
    "**Salva com cabecalho BSAVE** - funciona exatamente como o `BSAVE` do MSX BASIC (cabecalho real " +
    "de 7 bytes: `$FE` + inicio/fim/execucao, 2 bytes cada) - porta do `SV` do SUPER-X, pedido " +
    "explicito do usuario. Abre o dialogo " + Chr(34) + "Salvar como" + Chr(34) + " sugerindo `<nome>` " +
    "como nome de arquivo." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XSV <nome>,<inicio>[#slot[-sub]|#S],<fim>[,<execucao>[,<offset>]]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<inicio>` aceita sufixo de slot/sub-slot (igual `XD`) **exceto VRAM** (`#V`) - `BSAVE` de " +
    "verdade nunca salva de VRAM. `<fim>` e' sempre um endereco puro, no MESMO alvo. `<execucao>` " +
    "vazio = igual a `<inicio>` (mesma regra do `BSAVE` original)." + #CRLF$ + #CRLF$ +
    "**`<offset>`** (opcional, so' faz sentido com `<execucao>` tambem informado) desloca so' os " +
    "ENDERECOS GRAVADOS NO CABECALHO - os bytes continuam lidos do intervalo `[<inicio>,<fim>]` de " +
    "verdade aqui no simulador. Util pra montar/testar num endereco de trabalho e gerar um `.bin` que " +
    "declara um endereco de carga DIFERENTE (o destino real), pra carregar de volta depois com o " +
    "`XLD` (ou `BLOAD` de verdade) no lugar certo." + #CRLF$ + #CRLF$ +
    "*Ao contrario do `SAVE` nativo (janela rica com Slot/Formato editaveis), o `XSV` e' direto: so' " +
    "pede o nome do arquivo, sem tela de confirmacao extra.*")

  MamuteHelp_Add("XLD", "Comandos",
    "**Carrega com cabecalho BLOAD** - le um arquivo gravado no formato `BSAVE` (mesmo cabecalho do " +
    "`XSV`, ao lado) e escreve os bytes na memoria - porta do `LD` do SUPER-X, pedido explicito do " +
    "usuario. Abre o dialogo " + Chr(34) + "Selecione o arquivo" + Chr(34) + " sugerindo `<nome>`." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XLD <nome>[,<offset>[#slot[-sub]|#S]]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`?ARQUIVO INVALIDO` se o 1o byte do arquivo nao for `$FE` (mesma exigencia do `BLOAD` de " +
    "verdade)." + #CRLF$ + #CRLF$ +
    "- **Sem `<offset>`** - carrega no MESMO endereco que o cabecalho ja diz, `PAGE`-relativo comum." + #CRLF$ +
    "- **Com `<offset>`** - ignora o endereco do cabecalho pra fins de escrita, carrega a partir de " +
    "`<offset>` (aceita o mesmo sufixo de slot do `XSV`, tambem sem VRAM)." + #CRLF$ + #CRLF$ +
    "*O endereco de execucao do cabecalho so' e' MOSTRADO no log - `XLD` nunca executa nada sozinho " +
    "(equivalente ao `BLOAD` sem `,R`) - rode depois com `XGO` se quiser.*")

  MamuteHelp_Add("XS#", "Comandos",
    "**Salva bytes CRUS, sem cabecalho** - porta do `S#` do SUPER-X, pedido explicito do usuario. " +
    "Diferente do `XSV` (que grava o cabecalho `BSAVE` real), o `XS#` grava SO' os bytes do intervalo, " +
    "nada mais - nem `$FE`, nem enderecos, nada." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XS# <nome>,<inicio>[#slot[-sub]|#V|#S],<fim>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Abre o dialogo " + Chr(34) + "Salvar como" + Chr(34) + " sugerindo `<nome>`. `<inicio>` aceita o " +
    "sufixo de alvo completo (igual `XD`) **incluindo VRAM** (`#V`) - diferente do `XSV`/`XLD` (que " +
    "rejeitam VRAM pra ficar fiel ao `BSAVE`/`BLOAD` reais), o `XS#`/`XL#` sao um dump/restore cru " +
    "generico, sem pretensao de imitar nenhum formato de arquivo do MSX de verdade. `<fim>` e' sempre " +
    "um endereco puro, no MESMO alvo.")

  MamuteHelp_Add("XL#", "Comandos",
    "**Carrega bytes CRUS, sem cabecalho** - analogo ao `XS#` (ao lado), porta do `L#` do SUPER-X, " +
    "pedido explicito do usuario. Sem `<fim>` (mesma sintaxe do `L#` original) - o tamanho vem do " +
    "PROPRIO arquivo, carrega ele inteiro a partir de `<inicio>`." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XL# <nome>,<inicio>[#slot[-sub]|#V|#S]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Abre o dialogo " + Chr(34) + "Selecione o arquivo" + Chr(34) + " sugerindo `<nome>`. Se o arquivo " +
    "nao couber inteiro a partir de `<inicio>` (estouraria o teto do alvo), `?ERRO DE SINTAXE` - nunca " +
    "" + Chr(34) + "da a volta" + Chr(34) + " silenciosamente (mesma convencao do `XBT`/`XRT`/`XFL`).")

  MamuteHelp_Add("XL%", "Comandos",
    "**Le setor(es) do disco corrente DIRETO pra memoria** (bruto, sem passar pelo sistema de " +
    "arquivos - abaixo do nivel de `XFS`/`XTP`) - porta do `L%` do SUPER-X, pedido explicito do " +
    "usuario. Sem disco corrente, abre o dialogo de escolha primeiro (mesmo idioma do `XFS`)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XL% <setorinic>[,<setorfim>],<endereco>[#slot[-sub]|#V|#S]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<setorinic>`/`<setorfim>` sao numeros de SETOR (512 bytes cada), em HEXA (mesma convencao " +
    "numerica do resto do monitor) - setor 0 e' o setor de boot. `<setorfim>` AUSENTE = carrega " +
    "apenas UM UNICO setor. `<endereco>` aceita o sufixo de alvo completo, INCLUSIVE VRAM (`#V`) - " +
    "carregar um setor cru direto na VRAM e' uma operacao real do MSX." + #CRLF$ + #CRLF$ +
    "`?ERRO DE SINTAXE` se `<setorfim>` for alem do tamanho real do disco corrente, ou se os bytes " +
    "nao couberem a partir de `<endereco>` (mesma convencao " + Chr(34) + "nunca da a volta" + Chr(34) +
    " do `XBT`/`XRT`/`XFL`/`XL#`).")

  MamuteHelp_Add("XS%", "Comandos",
    "**Grava memoria DIRETO em setor(es) do disco corrente** - o reverso do `XL%` (ao lado), porta do " +
    "`S%` do SUPER-X, pedido explicito do usuario. MESMA sintaxe/validacao do `XL%` - so' a direcao " +
    "da copia inverte." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XS% <setorinic>[,<setorfim>],<endereco>[#slot[-sub]|#V|#S]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<setorfim>` AUSENTE = grava apenas UM UNICO setor." + #CRLF$ + #CRLF$ +
    "*Grava DIRETO em cima do disco corrente, sem confirmacao extra - mesmo espirito " + Chr(34) +
    "MON> executa na hora" + Chr(34) + " de todo o resto do monitor (`M`/`S`/`F`/`XFL`/`XS#` ja " +
    "escrevem sem perguntar).*")

  MamuteHelp_Add("XIM", "Comandos",
    "**Adiciona uma nota nova em memoria** - porta do `iM` (Input Memo) do SUPER-X, pedido explicito " +
    "do usuario apos perguntar se ja dava pra " + Chr(34) + "consultar um endereco" + Chr(34) + " a " +
    "partir de um arquivo de notas. So' fica em memoria ate' o fim da sessao, a nao ser que grave com " +
    "`XIS` depois." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XIM <endereco>,<slot>,<tipo>,<texto>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<slot>` (0-4: Geral/MAIN/SUB/FDC/RAM) e `<tipo>` (0-7: Geral/BIOS/WORK/DATA/PORT/MATH/KEY/HOOK) " +
    "sao os codigos NUMERICOS PROPRIOS do SUPER-X (classificacao da doc original do arquivo de notas) - " +
    "**nao** tem nada a ver com o `#slot-subslot` do enderecamento estendido usado pelo resto do modulo " +
    "45, so' coincidem de nome. `<texto>` e' tudo que sobrar depois da 3a virgula (pode ter espacos e " +
    "quase qualquer pontuacao)." + #CRLF$ + #CRLF$ +
    "*Mais de uma nota pode existir no mesmo `<endereco>` - `XIC` mostra todas.*")

  MamuteHelp_Add("XIC", "Comandos",
    "**Consulta nota(s) de um endereco** - porta do `iC` (Input Check) do SUPER-X, o comando que " +
    "responde a pergunta original do usuario (" + Chr(34) + "ja posso consultar um endereco?" + Chr(34) +
    ")." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XIC <endereco>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Mostra TODAS as notas gravadas nesse `<endereco>` (podem existir mais de uma - confirmado em 17 " +
    "casos reais entre as 471 notas originais traduzidas, coincidencias numericas entre BIOS/PORT ou " +
    "SUB-ROM vs ROM principal). `?NOTA NAO ENCONTRADA` se nenhuma nota bater." + #CRLF$ + #CRLF$ +
    "*Precisa de `XIL` primeiro pra carregar notas - a lista comeca vazia.*")

  MamuteHelp_Add("XIL", "Comandos",
    "**Carrega um arquivo de notas** - porta do `iL` (Input Load) do SUPER-X. Abre o dialogo " +
    Chr(34) + "Selecione o arquivo" + Chr(34) + ", sugerindo `<nome>` (ou, sem argumento nenhum, o " +
    "arquivo de notas TRADUZIDO que o proprio Paleobasic ja traz pronto - **nunca** o `SUPER-X.TNK` " +
    "original em japones, pedido explicito do usuario: " + Chr(34) + "assegure-se de ler o arquivo ja " +
    "traduzido de notas e nao o original em japones" + Chr(34) + ")." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XIL [<nome>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Substitui TODAS as notas em memoria pelas do arquivo (`ClearList` antes de carregar) - qualquer " +
    "nota adicionada com `XIM` e nao gravada com `XIS` se perde." + #CRLF$ + #CRLF$ +
    "*Formato proprio deste porte (texto, uma nota por linha) - diferente do binario Shift-JIS do " +
    "`SUPER-X.TNK` original, que fica só' de referencia estatica na Ajuda.*")

  MamuteHelp_Add("XIS", "Comandos",
    "**Grava as notas em memoria num arquivo** - porta do `iS` (Input Save) do SUPER-X, o reverso do " +
    "`XIL` (ao lado). Util pra guardar notas adicionadas com `XIM` durante a sessao." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XIS <nome>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Abre o dialogo " + Chr(34) + "Salvar como" + Chr(34) + ", sugerindo `<nome>` (mesmo formato texto " +
    "do `XIL` - nao o binario do `SUPER-X.TNK`).")

  MamuteHelp_Add("XIR", "Comandos",
    "**Visualizador interativo das notas em memoria** - abre uma janela mostrando as notas " +
    "(`MamuteNotes()`, carregadas via `XIL`/adicionadas via `XIM`) uma de cada vez, com botoes de " +
    "navegacao e um campo de busca - pedido explicito do usuario." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XIR [<endereco>]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endereco>`, se informado, abre ja' na primeira nota daquele endereco (senao abre na primeira " +
    "nota da lista)." + #CRLF$ + #CRLF$ +
    "**Navegacao:** botoes `|<`/`<`/`>`/`>|` (primeira/anterior/proxima/ultima) - tambem Setas Cima/" +
    "Baixo, PgUp/PgDn (pula 10 notas), Home/End." + #CRLF$ + #CRLF$ +
    "**Busca:** mesmo campo do `XTP` - `Case` (diferencia maiusculas/minusculas) e `Regex` (expressao " +
    "regular), independentes um do outro (cobre busca com case, sem case, e com expressao regular, nas " +
    "combinacoes que fizerem sentido). Busca contra `ENDERECO SLOT TIPO TEXTO` de cada nota - da pra " +
    "buscar por endereco hexa (ex. `00B4`), por categoria (ex. `PORT`), ou por texto livre. Sempre a " +
    "partir da PROXIMA nota, com wraparound completo pela lista.")

  MamuteHelp_Add("XPP", "Comandos",
    "**Painel de Portas I/O** - abre uma janela mostrando as portas monitoradas (0-255), com colunas " +
    "`Entrada` (ultimo byte que o programa mandou pra' porta via `OUT`) e `Saida` (byte que uma `IN` vai " +
    "ler dessa porta) - pedido explicito do usuario." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XPP" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Botoes `Adicionar`/`Remover` incluem/excluem uma porta (digitada no campo `Porta:`) do painel; " +
    "`Definir` (Entrada/Saida) edita manualmente os dois valores - **por enquanto NAO existe nenhuma " +
    "rotina de simulacao de hardware de verdade**, entao e' o usuario quem digita o que `Saida` deve " +
    "valer ANTES de rodar o programa com `XGO`/`XTR`, se quiser controlar o que uma `IN` vai ler. " +
    "`Limpar Marcas` tira o destaque (fundo amarelo) das portas que sofreram alguma alteracao - `XPI`/`XPO` " +
    "e as instrucoes `IN`/`OUT` de verdade do programa simulado marcam a porta assim que ESCREVEM nela " +
    "(ler nunca marca). Lista sempre em ordem crescente de porta.")

  MamuteHelp_Add("XPI", "Comandos",
    "**Le uma porta e mostra o valor no prompt** - simula manualmente a instrucao `IN` do Z80, lendo " +
    "`Saida` da porta no Painel de Portas I/O (`XPP`, ao lado)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XPI <porta>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<porta>` e' hexa (0-FF). Cria a porta no painel se ainda nao existir (com `Saida` = `FF`, " +
    "barramento flutuante, ate' o usuario definir algo diferente pelo `XPP`). So' LE - nunca marca a " +
    "porta como alterada.")

  MamuteHelp_Add("XPO", "Comandos",
    "**Escreve um byte numa porta** - simula manualmente a instrucao `OUT` do Z80, gravando `Entrada` " +
    "da porta no Painel de Portas I/O (`XPP`, ao lado)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XPO <porta>,<byte>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<porta>` e `<byte>` sao hexa (0-FF cada). Cria a porta no painel se ainda nao existir, e marca a " +
    "porta como alterada (mesmo efeito visual de uma `OUT` de verdade rodada via `XGO`/`XTR`).")

  MamuteHelp_Add("XCS", "Comandos",
    "**Alterna o tipo de checksum** do despejo do `XD` (`XD <endinic>,<endfim>`, ver ao lado) - pedido " +
    "explicito do usuario." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XCS" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Sem argumentos - cada `XCS` so' ALTERNA entre os dois modos e confirma o novo estado no log " +
    "(mesmo idioma do `PAGE`/`C` ecoando o estado apos uma mudanca):" + #CRLF$ +
    "- **NORMAL** (padrao) - checksum = soma dos ate 8 bytes da linha, com wraparound em 8 bits." + #CRLF$ +
    "- **+ADDR** - a mesma soma, mas somando TAMBEM o byte baixo do endereco da linha (`AAAA & FF`) - " +
    "checksum tipico de 8 bits que embute o endereco, util pra detectar linhas fora de ordem/deslocadas " +
    "que o modo NORMAL nao pegaria (mesmos bytes, endereco diferente = checksum igual no NORMAL, " +
    "diferente no +ADDR)." + #CRLF$ + #CRLF$ +
    "Dura so' esta sessao da janela (nao persiste em `mamute_settings.json`, mesmo espirito volatil do " +
    "`PAGE`/`C`) - reabrir o Mamute Assembler volta pro modo NORMAL.")

  MamuteHelp_Add("XTS", "Comandos",
    "**Calcula UM checksum agregado** do bloco inteiro - pedido explicito do usuario. Diferente do " +
    "checksum POR LINHA do despejo do `XD` (8 bits, alternado pelo `XCS`, ao lado), aqui e' um UNICO " +
    "valor de 16 bits pro bloco `[endinic,endfim]` inteiro (soma de TODOS os bytes, com wraparound) - " +
    "util pra comparar/verificar a integridade de um bloco inteiro (ex.: um ROM) de uma vez, nao linha " +
    "a linha." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XTS <endinic>[#slot[-sub]|#V|#S],<endfim>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<endinic>` aceita o sufixo de alvo completo (ver `XD`); `<endfim>` e' sempre um endereco puro, " +
    "no MESMO alvo (mesma convencao do `XBT`/`XRT`/`XFL`/`XCM`/`XFD`)." + #CRLF$ + #CRLF$ +
    "Mostra o resultado nos MESMOS 4 formatos do `CL` (ao lado) mais **OCTAL**:" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "HEX  : 06C4H" + #CRLF$ +
    "BIN  : 0000011011000100" + #CRLF$ +
    "DEC+ : 1732" + #CRLF$ +
    "DEC+-: 1732" + #CRLF$ +
    "OCT  : 003304" + #CRLF$ +
    "```")

  MamuteHelp_Add("XRG", "Comandos",
    "**Mostra/edita os registradores Z80 simulados** - pedido explicito do usuario. Sem argumento, " +
    "mostra TODOS os pares de 16 bits, inclusive os " + Chr(34) + "secretos" + Chr(34) + " (o par " +
    "alternado AF'/BC'/DE'/HL', que nem o comando `X` mostra) mais o `PC` e os 5 breakpoints nomeados " +
    "do `XGO` (`BP`/`BP1`/`BP2`/`BP3`/`BPF`, ver `XGO` ao lado)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XRG" + #CRLF$ +
    "MON>XRG *" + #CRLF$ +
    "MON>XRG +" + #CRLF$ +
    "MON>XRG <registro>,<valor>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "- **`XRG`** (sem argumento) - mostra os registradores:" + #CRLF$ +
    "```" + #CRLF$ +
    "AF=0000 BC=0000 DE=0000 HL=0000" + #CRLF$ +
    "IX=0000 IY=0000 SP=0000" + #CRLF$ +
    "AF'=0000 BC'=0000 DE'=0000 HL'=0000" + #CRLF$ +
    "PC=0000" + #CRLF$ +
    "BP=---- BP1=---- BP2=---- BP3=---- BPF=----" + #CRLF$ +
    "```" + #CRLF$ +
    "- **`XRG *`** - limpa TODOS os registradores (`A`-`L`, o par alternado, `IX`/`IY`/`PC`/`I`/`R`/" +
    "`IFF1`/`IFF2`/`IM`/estado de `HALT`) **exceto a pilha** (`SP`) - mesma ressalva do manual " +
    "original (`RG *` limpa tudo " + Chr(34) + "except stack" + Chr(34) + "). Nao mexe em `BP`/`BP1`/" +
    "`BP2`/`BP3`/`BPF` - sao configuracao de depuracao, nao registradores da CPU." + #CRLF$ +
    "- **`XRG +`** - reseta SO' a pilha (`SP`) pro seu inicio (`$0000` - a pilha cresce pra baixo, " +
    "entao o 1o `PUSH`/`CALL` grava em `$FFFF`)." + #CRLF$ +
    "- **`XRG <registro>,<valor>`** - atribui `<valor>` (hexadecimal) ao registrador escolhido. " +
    "Registradores suportados: `A`, `B`, `C`, `D`, `E`, `F`, `H`, `L`, `A'`, `B'`, `C'`, `D'`, `E'`, " +
    "`F'`, `H'`, `L'` (1-2 digitos hexa cada), `AF`, `BC`, `DE`, `HL`, `AF'`, `BC'`, `DE'`, `HL'`, " +
    "`IX`, `IY`, `IXH`, `IXL`, `IYH`, `IYL`, `SP`, `PC` (1-4 digitos hexa, exceto `IXH`/`IXL`/`IYH`/" +
    "`IYL`, que sao meios-registradores de 1 byte) e `BP`/`BP1`/`BP2`/`BP3`/`BPF`." + #CRLF$ + #CRLF$ +
    "*Alterando `SP` o Stack Pointer de verdade e' alterado tambem* - nao e' um valor cosmetico " +
    "separado, e' o MESMO `SP` que `PUSH`/`POP`/`CALL`/`RET` usam (`MamuteZ80Cpu.pbi`)." + #CRLF$ + #CRLF$ +
    "**`BP`/`BP1`/`BP2`/`BP3`/`BPF` nao sao registradores de verdade** - cada um marca um endereco de " +
    "breakpoint. O `XGO` (ao lado) para nesses enderecos EM SEQUENCIA e mostra os registradores " +
    "automaticamente, mesmo idioma do manual original (" + Chr(34) + "the program will stop at this " +
    "point and the registers are displayed" + Chr(34) + ").")

  MamuteHelp_Add("XGO", "Comandos",
    "**Executa o programa** a partir de um endereco, no MESMO motor Z80 simulado do comando `G`/" +
    "debugger grafico (`MamuteZ80Cpu.pbi`) - pedido explicito do usuario. Para AUTOMATICAMENTE num dos " +
    "5 breakpoints nomeados (`BP`/`BP1`/`BP2`/`BP3`/`BPF`, editaveis via `XRG`, ver ao lado) e mostra os " +
    "registradores no ponto onde parou." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XGO <endereco>[#<slot>]" + #CRLF$ +
    "MON>XGO" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "- **`XGO <endereco>`** - COMECA do zero nesse endereco, e para no `BP` (se estiver definido). " +
    "`#<slot>` troca IMPLICITAMENTE o slot PRIMARIO mapeado na PAGINA de `<endereco>` (mesmo efeito do " +
    "comando `PAGE`) antes de rodar - **`#V` (VRAM) e sub-slot explicito (`#slot-sub`) sao " +
    "?ERRO DE SINTAXE**: o motor de execucao Z80 so' roda contra a memoria mapeada normal (a mesma que " +
    "`PAGE` controla), nunca contra um sub-slot/VRAM explicito como os comandos de memoria (`XD`/`XM`/" +
    "`XA`/`XI`) conseguem mirar." + #CRLF$ +
    "- **`XGO`** (sem endereco) - CONTINUA de onde a ultima chamada parou. Cada chamada consecutiva " +
    "avanca um passo na sequencia: a 1a (`XGO <endereco>`) mira `BP`; a 2a mira `BP1`; a 3a, `BP2`; a " +
    "4a, `BP3`; a 5a em diante, so' `BPF`. **Se o breakpoint da vez nao estiver definido, cai pro " +
    "`BPF`** (se este estiver definido) - senao, roda " + Chr(34) + "livre" + Chr(34) + " (ver abaixo). " +
    "So' funciona depois de pelo menos um `XGO <endereco>` bem-sucedido." + #CRLF$ + #CRLF$ +
    "**Rodando " + Chr(34) + "livre" + Chr(34) + "** (nenhum breakpoint definido pra esta chamada) - " +
    "pedido explicito do usuario: para no que vier primeiro entre:" + #CRLF$ +
    "- **Fim do programa** - o `RET` que devolve pra ALEM da pilha de onde este `XGO` comecou (mesmo " +
    "criterio do `STEP OUT` do debugger grafico)." + #CRLF$ +
    "- **`ESC`** - interrompe manualmente a qualquer momento." + #CRLF$ +
    "- **`HALT`** - instrucao `HALT` sem interrupcao configurada pra retomar." + #CRLF$ +
    "- Um teto de seguranca de instrucoes (protecao final contra loop infinito sem nenhum dos " +
    "criterios acima)." + #CRLF$ + #CRLF$ +
    "*Com um breakpoint definido pra esta chamada, so' ele para a execucao - um `RET` no meio do " +
    "caminho NAO conta.*")

  MamuteHelp_Add("XTR", "Comandos",
    "**Trace passo a passo** - pedido explicito do usuario. Comeca em `<endereco>`, executa UMA " +
    "instrucao, mostra o endereco/bytes/mnemonico dela mais os registradores, e fica esperando: " +
    "`ENTER` executa a proxima instrucao (mostra de novo e espera outra vez), `ESC` interrompe." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XTR <endereco>" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Cada passo mostra 3 linhas:" + #CRLF$ +
    "```" + #CRLF$ +
    "4000  3E 05        LD A,05H" + #CRLF$ +
    "AF=0500 BC=0000 DE=0000 HL=0000" + #CRLF$ +
    "IX=0000 IY=0000 SP=F380" + #CRLF$ +
    "```" + #CRLF$ +
    "(mesmo formato endereco+bytes+mnemonico do `L`/`LP`, registradores no mesmo formato compacto do " +
    "comando `X` - sem os " + Chr(34) + "secretos" + Chr(34) + "/`BP`s do `XRG`, pra nao encher o log " +
    "numa sessao de trace longa; use `XRG` a qualquer momento, inclusive no meio de um trace, se " +
    "precisar ver tudo)." + #CRLF$ + #CRLF$ +
    "Se a `CPU` **haltar** (instrucao `HALT` sem interrupcao configurada pra retomar) o trace se " +
    "encerra sozinho, sem esperar `ESC`." + #CRLF$ + #CRLF$ +
    "*Diferente do `XGO`, `XTR` nao aceita sufixo de slot/VRAM - so' um endereco puro (mesmo escopo do " +
    "`TR` original). Pra rodar num slot especifico, troque a `PAGE` antes com o comando `PAGE`.*")

  MamuteHelp_Add("XSD", "Comandos",
    "**Super disassembler** - gera uma listagem em disco a partir de um bloco de memoria: OU uma " +
    "listagem assembly de verdade (pra realimentar um compilador Z80 externo), OU um despejo de bytes " +
    "crus em 3 formatos de texto diferentes - pedido explicito do usuario. **Sempre abre o dialogo " +
    "" + Chr(34) + "Salvar como" + Chr(34) + "**, sugerindo `<arquivo>` como nome (diferente do `XI`, " +
    "que grava direto sem dialogo)." + #CRLF$ + #CRLF$ +
    "**Sintaxe:**" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "MON>XSD <arquivo>,<inicio>[#slot[-sub]|#V|#S],<final>[,B|D|X]" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "`<inicio>` aceita o sufixo de alvo completo (ver `XD`) - slot/sub-slot/VRAM, igual `XD`/`XM`/`XA`/" +
    "`XI` (isto e' so' LEITURA de memoria, nao precisa da limitacao de slot primario que o `XGO` tem " +
    "por precisar EXECUTAR). `<final>` e' sempre um endereco puro, no MESMO alvo." + #CRLF$ + #CRLF$ +
    "- **Sem `,B`/`,D`/`,X`** - listagem assembly de verdade, uma instrucao decodificada por linha " +
    "(sem coluna de endereco/bytes, diferente do `XI`), com `ORG <inicio>H` no topo:" + #CRLF$ +
    "```" + #CRLF$ +
    "        ORG 4000H" + #CRLF$ +
    "        LD A,05H" + #CRLF$ +
    "        CALL 0A2H" + #CRLF$ +
    "```" + #CRLF$ +
    "- **`,B`** - bytes crus em `DEFB` (sintaxe Z80 assembler), 8 por linha:" + #CRLF$ +
    "```" + #CRLF$ +
    "DEFB 3EH,05H,CDH,A2H,00H,C9H,00H,00H" + #CRLF$ +
    "```" + #CRLF$ +
    "- **`,D`** - `DATA` em BASIC, 8 por linha, `<linha>` comecando em `10000` (subindo de 10 em 10) - " +
    "**sempre com prefixo `&H`** (sem ele nao seria hexadecimal nenhum pro interpretador BASIC). Ganha " +
    "uma linha extra no final com o loop de carga:" + #CRLF$ +
    "```" + #CRLF$ +
    "10000 DATA &H3E,&H05,&HCD,&HA2,&H00,&HC9,&H00,&H00" + #CRLF$ +
    "10010 FOR I=&H4000 TO &H4007:READ A:POKE I,A:NEXT I" + #CRLF$ +
    "```" + #CRLF$ +
    "**`,D` nao aceita VRAM** (`?ERRO DE SINTAXE`) - o loop gerado faz `POKE` (memoria comum), que nao " +
    "faz sentido nenhum pros MESMOS numeros de endereco se a origem for VRAM (precisaria de `VPOKE`)." + #CRLF$ +
    "- **`,X`** - dados embutidos no formato do X-BASIC (`'#` na frente, sem virgula antes do 1o " +
    "valor - o proprio X-BASIC ja sabe carregar isso sozinho, sem loop nenhum):" + #CRLF$ +
    "```" + #CRLF$ +
    "10000 '#&H3E,&H05,&HCD,&HA2,&H00,&HC9,&H00,&H00" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "Extensao sugerida quando `<arquivo>` nao tiver nenhuma: `.asm` (sem modo/`,B`) ou `.bas` (`,D`/" +
    "`,X`). Cancelar o dialogo mostra `CANCELADO`, sem gravar nada.")

  MamuteHelp_Add("EDIT", "Comandos",
    "**Abre uma janela separada** com um editor de linhas pro **programa-fonte Z80**, modelado no " +
    "editor de BASIC do ZX-81/ZX Spectrum (pedido explicito do usuario) - a LISTAGEM e' a propria " +
    "tela (sem log de comandos nem mensagem " + Chr(34) + "OK" + Chr(34) + "), com um cursor `>` " +
    "marcando a linha atual." + #CRLF$ + #CRLF$ +
    "**Sintaxe de cada linha** (formato do manual original do MegaAssembler):" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "NN Label: instrucao operando ;comentario" + #CRLF$ +
    "```" + #CRLF$ + #CRLF$ +
    "- **`NN`** - numero da linha, **obrigatorio**. Digitar de novo o mesmo numero **substitui** a " +
    "linha (mesma edicao " + Chr(34) + "como se fosse BASIC" + Chr(34) + " do manual)." + #CRLF$ +
    "- **`Label:`** - opcional, termina em `:`." + #CRLF$ +
    "- **`instrucao`** - um mnemonico Z80 valido ou uma das pseudo-instrucoes `ORG`/`DEFB`/`DEFW`/" +
    "`DEFM`/`DEFS`/`EQU`/`END`. `EQU` exige `Label:`." + #CRLF$ +
    "- **`;comentario`** - opcional, ate o fim da linha." + #CRLF$ + #CRLF$ +
    "**Numeros** - mudanca em relacao ao manual original: **sem sufixo, um numero agora e' " +
    "HEXADECIMAL por padrao** (o manual original usava decimal), pra ficar uniforme com o resto do " +
    "Mamute. Se comecar com letra (A-F), precisa de um `0` na frente - senao vira label. Sufixos " +
    "opcionais no final: `H` (hexa, redundante com o padrao), `B` (binario), `D` (decimal - unico " +
    "jeito de escrever decimal agora)." + #CRLF$ + #CRLF$ +
    "**Navegacao e edicao, ao estilo ZX-81:**" + #CRLF$ + #CRLF$ +
    "- **Setas Cima/Baixo** movem o cursor `>` pela listagem." + #CRLF$ +
    "- **ENTER com o campo VAZIO** puxa a linha do cursor `>` pro campo, pronta pra editar." + #CRLF$ +
    "- **ENTER com o campo preenchido** grava a linha digitada (nova ou substituindo por `NN`)." + #CRLF$ +
    "- **ESC** descarta o que estiver no campo, sem gravar nada." + #CRLF$ +
    "- **Tela cheia**: ao digitar linhas novas, quando a tela enche ela e' limpa e rola **meia tela** " +
    "automaticamente, pra caber mais." + #CRLF$ +
    "- **`LIST`** (digitado no campo, sem `NN` na frente): limpa a tela e lista a partir da 1a linha. " +
    "Se o programa nao couber inteiro, pergunta " + Chr(34) + "Rolar mais uma tela? (S/N)" + Chr(34) +
    " no rodape (responda no mesmo campo + ENTER) - respondendo Sim, mostra a proxima tela CHEIA com o " +
    "cursor na 1a linha dela, perguntando de novo se ainda sobrar programa." + #CRLF$ + #CRLF$ +
    "*Diferente do ZX-81 real, nao ha teclas tokenizadas (cada palavra-chave BASIC numa unica tecla) - " +
    "sem sentido com teclado de PC de verdade, digite normalmente.*" + #CRLF$ + #CRLF$ +
    "**Comandos de gerenciamento** (tambem digitados no campo, sem `NN` na frente):" + #CRLF$ + #CRLF$ +
    "- **`NEW`** - apaga o programa inteiro da memoria, sem confirmacao." + #CRLF$ +
    "- **`DELETE <lininic>[-[<linfin>]]`** - apaga uma linha (`DELETE 50`), um intervalo inclusive " +
    "(`DELETE 50-90`), ou da linha ate o fim do programa (`DELETE 50-`, sem numero final)." + #CRLF$ +
    "- **`RENUM [<novali>[,<antigali>[,<incr>]]]`** - renumera a partir da linha ANTIGA `antigali` pra " +
    "uma nova sequencia comecando em `novali` com passo `incr` (`RENUM` sozinho: tudo, comecando em " +
    "10, passo 10). So os numeros de linha mudam - referencias por LABEL (`JR SALT`, por exemplo) " +
    "continuam funcionando normalmente." + #CRLF$ +
    "- **`CHANGE '<string1>'[,'<string2>']`** - troca todas as ocorrencias de `<string1>` por " +
    "`<string2>` em qualquer lugar de cada linha (label, instrucao, operando ou comentario); se " +
    "`<string2>` for omitido, apaga as ocorrencias de `<string1>`." + #CRLF$ +
    "- **`SAVE`**/**`LOAD`** - abrem os dialogos nativos " + Chr(34) + "Salvar como" + Chr(34) + "/" +
    Chr(34) + "Abrir" + Chr(34) + " (sem digitar nome) - gravam/leem o programa-fonte inteiro num " +
    "arquivo `.mza` em **ASCII simples** (formato desta porta, nao o formato binario proprietario do " +
    "MegaAssembler original - suporte a ele fica pra uma sessao futura). `LOAD` SUBSTITUI o programa " +
    "em memoria pelo conteudo do arquivo." + #CRLF$ +
    "- **`MERGE`** - igual ao `MERGE` do BASIC: mostra o MESMO dialogo do `LOAD`, mas NAO apaga o " +
    "programa em memoria - funde os dois. Uma linha do arquivo com o MESMO numero de uma linha ja " +
    "existente SOBREPOE a existente; numeros que so existem de um lado ficam como estao." + #CRLF$ +
    "- **`SEARCH '<string>'`** (entre aspas) - busca LITERAL, case-sensitive. **`SEARCH <string>`** " +
    "(sem aspas) - busca LIVRE, case-insensitive (strings, comandos, labels, etc). Bem-sucedida, a " +
    "TELA passa a mostrar SO as linhas encontradas (mesmas setas/`ENTER` de sempre navegam entre " +
    "elas) - digite `LIST` (ou qualquer outro comando) pra voltar ao programa completo." + #CRLF$ +
    "- **`LSEARCH`** - igual ao `SEARCH` (mesmas duas formas com/sem aspas), mas em vez de filtrar a " +
    "tela, manda a listagem das linhas encontradas pra um PDF (mesmo mecanismo do `L`/`LP`/`P`/`V`)." + #CRLF$ +
    "- **`FIND`** - apelido de `SEARCH` (mesmas duas formas, mesmo resultado). No manual original " +
    "buscava so no inicio da linha, mais rapido que o `SEARCH` - otimizacao sem sentido num PC, entao " +
    "essa distincao nao existe aqui." + #CRLF$ +
    "- **`QUIT`** - fecha a janela do `EDIT` e volta pro `MON>`, SEM apagar o programa da memoria - " +
    "abrir `EDIT` de novo continua exatamente de onde parou.")

  ; Topico separado (nao mais parte do MamuteHelp_Add("EDIT", ...) acima) -
  ; pbcompiler.exe rejeita literal string composta com mais de 8192
  ; caracteres numa UNICA chamada (limite encontrado ao acrescentar a opcao
  ; "S" nesta sessao); dividir em duas chamadas contorna o limite e da
  ; quebra pra um sub-topico mais focado (comando A e suas opcoes).
  MamuteHelp_Add("EDIT - Montar (comando A)", "Comandos",
    "- **`A`** - mostra `PASSO-1` e depois `PASSO-2` (mesma sequencia do Mega Assembler original) e " +
    "MONTA (compila) o programa-fonte de verdade, reaproveitando o assembler Z80 nativo do projeto " +
    "(`Z80Asm.pbi`, compativel M80/Nestor80). So' valida - o resultado vira uma LISTAGEM detalhada, " +
    "coluna a coluna: numero da linha, endereco (ou o valor de um `EQU`), ate 4 bytes de codigo-objeto " +
    "em hexa (linhas extras se a instrucao/diretiva gerar mais de 4 bytes) e o conteudo original da " +
    "linha - a mesma tela cheia/rolagem do `LIST` (`Rolar mais uma tela? (S/N)`) se nao couber tudo de " +
    "uma vez. `ORG`/`END` nao aparecem na listagem. Em caso de erro, mostra a mensagem descritiva e o " +
    "cursor `>` pula direto pra linha com problema (sem listagem nesse caso)." + #CRLF$ +
    "- **`A O`** - igual ao `A` (mesma sequencia PASSO-1/PASSO-2/listagem), mas alem de validar " +
    "ESCREVE o codigo-objeto na RAM simulada, no endereco do `ORG`, resolvido pelo mapeamento de " +
    "`PAGE` ativo agora (se o `ORG` cair numa pagina mapeada pra RAM, os bytes vao parar la' de " +
    "verdade - mesma regra do `DM`/`SCR`)." + #CRLF$ +
    "- **`A N`** - igual ao `A`, mas a listagem NAO mostra a coluna do numero da linha (o resto e' " +
    "identico - endereco/valor de `EQU`, bytes hexa e conteudo continuam iguais)." + #CRLF$ +
    "- **`A P`** - igual ao `A`, mas ALEM de mostrar a listagem na tela, manda a MESMA listagem pra um " +
    "PDF (dialogo " + Chr(34) + "Salvar como" + Chr(34) + ", mesma infra do `LSEARCH`/`L`/`LP`/`P`/`V` - " +
    "nao ha driver de impressora de verdade, so' um PDF A4 simples). Cancelar o dialogo e' silencioso - " +
    "segue exatamente como um `A` sem `P`." + #CRLF$ +
    "- **`A I`** - igual ao `A`, mas ALEM disso grava o codigo-objeto recem montado em DISCO, no " +
    "formato real do BSAVE/BLOAD do MSX (cabecalho `FE` + endereco inicial/final/execucao, 2 bytes " +
    "cada). Abre a MESMA janela do comando `SAVE` do `MON>` (arquivo, slot 0-3, os tres enderecos), ja' " +
    "com tudo pre-preenchido (slot sugerido a partir do mapeamento `PAGE` ativo agora, enderecos vindos " +
    "da montagem) - tudo editavel antes de gravar de verdade. Diferente de `A O`, `A I` NAO precisa que " +
    "os bytes ja' estejam na RAM simulada - grava direto do resultado da montagem, funciona sozinho. " +
    "Cancelar o dialogo e' silencioso - as outras opcoes (`O`/`N`/`P`) continuam valendo normalmente." + #CRLF$ +
    "- **`A R`** - igual ao `A`, mas ALEM disso ANEXA ao final da listagem uma REFERENCIA CRUZADA dos " +
    "simbolos (ordem alfabetica): nome, valor (constante `EQU` ou endereco de definicao do rotulo - o " +
    "mesmo layout serve pros dois) e todos os enderecos onde foi usado (ate 4 por linha, continua nas " +
    "linhas seguintes se precisar). Vira parte da MESMA listagem/rolagem - nao um passo separado." + #CRLF$ +
    "- **`A S`** - igual ao `A`, mas ALEM disso ANEXA ao final da listagem uma lista alfabetica SIMPLES " +
    "dos simbolos (nome + valor/endereco de definicao), SEM os enderecos de uso (isso e' o `R`). Se `R` " +
    "e `S` estiverem ativos juntos, o bloco de `S` aparece depois do bloco de `R`." + #CRLF$ +
    "- **`A D`** - igual ao `A S`, mas a lista de simbolos vem em ORDEM DE APARICAO no fonte (a ordem em " +
    "que cada um foi DEFINIDO), nao em ordem alfabetica. Se `S` e `D` estiverem ativos juntos, o bloco " +
    "de `D` aparece depois do bloco de `S`." + #CRLF$ +
    "- **`A SH`/`A DH`** - manda SO' a(s) lista(s) de labels (nao a listagem inteira, isso e' o `P`) pra " +
    "um PDF SEPARADO - **`H` precisa vir com `S` e/ou `D`**, sozinho e' rejeitado (nao ha lista pra " +
    "imprimir). Se `S` e `D` estiverem ativos junto com `H`, as duas listas vao pro MESMO PDF, " +
    "separadas por 1 linha em branco." + #CRLF$ +
    "- **`A O/<offset>`** - monta o programa como se TODO `ORG` tivesse `<offset>` (hexa, 0000-FFFF) " +
    "somado ao valor original - ex. `A O/8000` com `ORG 0C100H` vira `ORG 0C100H+8000H`. O programa " +
    "INTEIRO acompanha o deslocamento (rotulos, saltos, listagem) - nao e' so' um resumo de endereco, " +
    "e' a montagem de verdade recalculada com o novo `ORG`. A `/` fica SEPARADA das letras de opcao " +
    "(tudo depois dela e' o offset, nao mais uma flag) - combina com qualquer outra opcao no mesmo " +
    "bloco (`A O/8000`, `A ONR/1000`)." + #CRLF$ +
    "- Todas as opcoes acima combinam livremente no MESMO bloco, em qualquer ordem: **`A ON`**, " +
    "**`A NP`**, **`A ONPIRSDH/1000`**, etc - grava na RAM, omite numeros de linha, manda pra PDF, " +
    "grava em disco, anexa referencia cruzada, listas de labels, imprime so' os labels e/ou desloca o " +
    "`ORG` ao mesmo tempo, conforme as letras/offset presentes. A unica opcao do manual original ainda " +
    "nao implementada e' `U` (nao lista o programa)." + #CRLF$ +
    "- **`MAP`** - mostra o endereco inicial e final do codigo-objeto da ULTIMA montagem bem-sucedida " +
    "(`A` sozinho ja' basta, nao precisa de `A O` - os dois calculam o mesmo intervalo). Se nada foi " +
    "montado com sucesso ainda, pede pra rodar `A` (ou `A O`) primeiro; `NEW` invalida esse resultado " +
    "guardado, ja' que apaga o programa que o gerou." + #CRLF$ + #CRLF$ +
    "Exemplo (do manual original, adaptado pra hexa por padrao):" + #CRLF$ + #CRLF$ +
    "```" + #CRLF$ +
    "10              ORG 0C100H" + #CRLF$ +
    "20 CHPUT:       EQU 0A2H" + #CRLF$ +
    "30              LD HL,PRINT" + #CRLF$ +
    "100 PRINT:      DEFM 'MEGA ASSEMBLER'" + #CRLF$ +
    "120             END" + #CRLF$ +
    "```")
EndProcedure
