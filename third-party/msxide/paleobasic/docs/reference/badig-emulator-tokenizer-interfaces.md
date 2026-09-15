# Referência: interfaces de tokenizer e emulador (badig/msx/*_interface.py)

> Complementa `docs/SPEC.md` módulos 11 (saída tokenizada) e 12 (controle do openMSX). A leitura do
> código revelou que a implementação **real** do controle do openMSX é mais simples do que o plano
> descrito na conversa original (`transcricao.md`), que especulava sobre hooks de erro via memória
> e breakpoints de debug. O badig original **já resolve isso de um jeito mais direto** — vale usar
> essa abordagem como primeira opção no port, e só considerar a rota via debug/memória (mais
> poderosa mas mais trabalhosa) se a abordagem simples se mostrar insuficiente.

## `tokenizer_interface.py` (163 linhas)

Camada fina: `Settings` (config via `.ini`/cmdl/remtag, mesmo padrão de prioridade do resto do
projeto) + `Tokenizer.run()` (linha 135) que só **importa e chama** `msxbatoken.Main()`
diretamente em processo (não é subprocess — é import Python direto), configurando
`file_load`/`file_save`/`file_list` a partir do arquivo `.amx` recém-gerado pelo Badig.

**Para o port**: como o tokenizador vai ser nativo (ver `docs/SPEC.md` módulo 11), essa camada de
"interface" desaparece — a chamada vira uma chamada de função direta dentro do mesmo binário
PureBasic, sem processo/import separado. Simplifica em relação ao original.

## `emulator_interface.py` (358 linhas) — controle real do openMSX

### Sequência de comandos efetivamente enviada (`Emulator.run()`, linha 209)

Confirmar que o protocolo é XML sobre stdin/stdout do processo openMSX (`-control stdio`), como
descrito no `SPEC.md`. A sequência real de comandos (linha 297-336), na ordem:

1. `<command>set renderer SDLGL-PP</command>` — força um renderer específico (evita problemas de
   janela/driver).
2. `<command>set throttle off</command>` — desliga o limite de velocidade **antes** de carregar
   (carregamento do disco fica instantâneo).
3. `<command>debug set_watchpoint write_mem 0xfffe {[debug read "memory" 0xfffe] == 1} {set
   throttle on}</command>` — **truque de performance**, não de detecção de erro: arma um
   watchpoint que, quando o programa escreve `1` no endereço `0xFFFE`, liga o throttle de volta
   automaticamente. É como o programa carregado sinaliza "terminei de carregar, pode voltar à
   velocidade normal".
4. `<command>set power on</command>`
5. `type_via_keybuf` com dois `\r` — pula o prompt de data/hora da BIOS de disco.
6. `type_via_keybuf load"ARQUIVO` — comando de carga, usando o nome do arquivo **truncado para 8+3
   caracteres** (ver validação de conflito de nome antes disso, linha 225-235, que já tenta mitigar
   colisões de nomes truncados).
7. Se `nothrottle` **não** foi pedido: `type_via_keybuf poke-2,1` — escreve `1` no endereço
   `0xFFFE` (`-2` em complemento de 16 bits = `0xFFFE`) **a partir do próprio BASIC carregado**,
   dando o sinal que o watchpoint do passo 3 está esperando. É o mecanismo real por trás do "throttle
   off só durante o load".
8. `type_via_keybuf cls:run` — limpa tela e roda o programa.

### Monitoramento de erro em runtime (`Emulator.output()`, linha 163, e o loop em `run()`, linha 341+)

**Não usa breakpoint de memória nem hook de erro instalado via poke** (diferente do que o plano em
`transcricao.md` especulava). O mecanismo real:
- Só funciona em **Mac/Linux** (`if CURRENT_SYSTEM == INI_WIN: return` no início de `output()`, e
  aviso explícito *"Execution monitoring not yet supported on Windows"* no loop principal) — stdout
  do processo filho não é lido/parseado da mesma forma no Windows.
- openMSX é iniciado com `-script openmsx_output.tcl` (script Tcl carregado dentro do emulador,
  arquivo `badig/msx/openmsx_output.tcl` — não lido em detalhe nesta sessão, mas é o que faz a tela
  do MSX ecoar para o stdout do processo).
- O loop principal lê linha a linha o stdout do openMSX (`self.proc.stdout.readline`) e procura por
  **byte `\x07` (BEEP)** na linha sem `\x0c` — exatamente o mecanismo documentado em
  `MODULE_TOOLS.md`: *"always use a CHR$(7) (BEEP) character and pass the line number at the end of
  the string on the error message"*. Ou seja: a **convenção é do lado do programa BASIC** (o
  usuário deve fazer seu `ON ERROR` imprimir `CHR$(7)` + número da linha), não uma instrumentação
  automática de baixo nível.
- Ao achar essa marca, extrai o **último token da linha** de saída como o número de linha atual e
  procura em `self.stg.line_list` (mapa linha-clássica → linha-Dignified/arquivo/texto, construído
  em `Main.dignified()`/`Main.classic()` de `badig.py`) para reportar o erro **já traduzido** para
  a linha do arquivo `.dmx` original, com o texto da linha e um `^` apontando a posição — mesmo
  formato visual dos erros do próprio parser Dignified.
- Linhas de saída que começam com `Parei` ou `Break` são tratadas como aviso (`bullet='  - '`), não
  erro.

### Implicação para o port

A abordagem **simples e já comprovada** é: rodar openMSX com `-control stdio` (protocolo XML) +
`-script openmsx_output.tcl` (fazer a tela ecoar pro stdout), e depender da convenção
`CHR$(7)+linha` no `ON ERROR` do programa do usuário para localizar erros — nada de instalar hook
de erro via `POKE` nem configurar breakpoint de debug/Tcl na memória (isso é uma alternativa **mais
poderosa mas não implementada em lugar nenhum do projeto original** — ficaria como evolução futura
opcional, não como abordagem inicial). Recomenda-se copiar/portar o **conteúdo real** de
`openmsx_output.tcl` antes de implementar o módulo 12 do `SPEC.md` — ainda não lido nesta sessão de
documentação.

**Limitação herdada a decidir**: o monitoramento não funciona no Windows na implementação Python
original. Como a IDE aqui é primariamente Windows (PureBasic, `pbcompiler.exe`, `C:\dos\...`), isso
é um ponto em aberto — precisa investigar se dá para ler o stdout do openMSX no Windows a partir de
PureBasic (pode ser só uma limitação de como o Python lida com pipes bloqueantes no Windows, não
necessariamente uma limitação do openMSX em si).

## Pendências para uma futura sessão

- Ler `badig/msx/openmsx_output.tcl` (não lido nesta sessão).
- Confirmar se `-control stdio` + leitura de stdout funciona de forma não-bloqueante no Windows via
  `RunProgram`/`ReadProgramString` do PureBasic (`SaveTokenized()` em `BadigEditor.pb` já usa esse
  padrão para chamar Python, então a mecânica de pipe já é conhecida no projeto).
