# Outline — estado do projeto (checkpoint pra retomar em outro PC)

> Gerado em 2026-08-20, fim de sessão neste notebook. O usuário vai continuar em outro desktop até
> segunda-feira, depois na Alienware. Este arquivo é só um checkpoint de continuidade — a fonte de
> verdade de arquitetura/decisões continua sendo `docs/SPEC.md`, o histórico completo é
> `CHANGELOG.md`, e o guia de uso é `docs/MANUAL.md`. `CLAUDE.md` tem as instruções operacionais
> (comandos de build, convenções do repositório) pra qualquer sessão nova do Claude Code.

## ⚠️ Antes de continuar em outro PC

**6 commits locais NÃO estão no `origin/main`** (`git status` mostra `ahead 6`). Se o outro PC clonar/
puxar do remoto sem isso ter sido enviado antes, o trabalho de hoje (release 8.3.0 + todos os fixes
depois) **não vai estar lá**. Antes de trocar de máquina, ou:
- Rodar `git push` neste notebook (nunca feito nesta sessão a pedido explícito do usuário - "não envie
  pro repo ainda" - confirmar que já pode agora), ou
- Levar o repositório de outra forma (USB, sincronização manual, etc.) pro próximo PC.

Commits locais aguardando push (mais recente primeiro):
```
2f8e005 Editor: simplifica auto-indentacao (so copia linha anterior); Dignified: mensagem do limite de 255 caracteres melhorada
107e2ee Dignified: corrige "Label mal formado" com espaco dentro de {nome}
5617b92 Editor: auto-indentacao entende FOR/IF escondido depois de ":" na mesma linha
eb5f9e1 Editor: auto-indentacao no estilo FOR/NEXT chega pra abas .dmx/.bas
fdc4d22 Pacote Novo Removido
baaed72 Pacote Novo
```
(os dois últimos, "Pacote Novo"/"Pacote Novo Removido", foram commits do próprio usuário, não desta
sessão de trabalho - ver `docs/SPEC.md`/histórico do git pra contexto.)

## Versão atual

**8.3.0** (`build.ps1` → `$Version`) — release formal mais recente é a **8.2.0 "ESQUELETO NOVO"**
em `docs/RELEASE_NOTES.md`; a 8.3.0 ainda não ganhou uma entrada formal de release notes própria (só
está documentada sessão-a-sessão no `CHANGELOG.md` e módulo-a-módulo no `SPEC.md`, módulos 37-41) -
se for fechar um release formal da 8.3.0 numa sessão futura, considerar consolidar isso numa entrada
`## 8.3.0` no topo do `RELEASE_NOTES.md`.

## O que aconteceu nesta sessão (2026-08-20)

Sessão longa, várias frentes na mesma conversa - console do openMSX, auto-indentação do editor, bugs
reais no pré-processador Dignified. Detalhe técnico completo em `docs/SPEC.md`, módulos 37 a 41.

1. **Console do openMSX** (`módulo 37`) — display de FPS + atalho de Power na barra inferior (sempre
   visível), FPS parou de poluir os logs das abas Console/Status Info, paleta de 23 teclas especiais
   na aba Input Text (tags `⟦NOME⟧`) + combos de tecla (`⟦SHIFT+F1⟧`, segura todas antes de soltar) com
   "Modo Combo". **Dois bugs reais corrigidos**: `SetGadgetText()` nunca atualizava nenhum
   `ButtonImageGadget` (afetava 9 botões de estado dinâmico desde que foram criados) e o botão STOP
   pressionava TAB em vez de STOP (máscara errada). → release **8.3.0 "TECLA FANTASMA"**.
2. **Auto-indentação no editor principal** (`módulos 38/41`) — pedido, implementado com detecção de
   bloco (`FOR`/`IF`/`FUNC`/rótulo de loop), depois **revertido/simplificado** a pedido do usuário
   depois de dois rounds de falso-positivo (linha terminando em `:` sem bloco nenhum ainda indentava).
   **Estado final: só copia a indentação da linha anterior, sem nenhuma lógica de bloco.** Não tentar
   reintroduzir a lógica de somar/tirar nível sem um pedido novo e explícito.
3. **Bugs reais no pré-processador Dignified** (`módulos 39/40`), achados com um programa real de 1988
   ("Hyper Copy", Marcelo Fontolan):
   - `{ nome }` com espaço dentro das chaves falhava com "Label mal formado" - corrigido (tolera
     espaço em `{nome}`, mas DE PROPÓSITO não em rótulo de loop `nome{`, que colidiria com instruções
     clássicas tipo `RESTORE {label}`).
   - Limite de 255 caracteres por linha gerada (máximo real do MSX-BASIC) **já existia** - só a
     mensagem de erro não informava o tamanho real; melhorada.
   - Confirmado contra a documentação oficial (`BASIC_DIGNIFIED.md` do repo `farique1/basic-dignified`)
     que `##`/`###...###`/`''...''` (comentários) já funcionam certos no port nativo - um `#` único
     (não `##`) NÃO é comentário válido, isso já explicava uma "poluição" de texto vista antes.
4. **Achado de bônus**: todos os 16 harnesses de console em `src/editor/tools/*.pb` tinham
   `XIncludeFile` apontando pro layout antigo de diretórios desde a reorganização 8.2.0 - 15 corrigidos
   (`OpenMsxBridgeTestCli.pb` continua quebrado por um motivo diferente/pré-existente, ver lacunas).

## Pendências conhecidas (ver `docs/SPEC.md`, seção "Lacunas conhecidas", pra lista completa)

- `OpenMsxBridgeTestCli.pb` não compila (`Structure field not found: EmSetting` - stub de config
  desatualizado nesse harness específico).
- Mamute Assembler comando `G` (execução real de Z80) - Fase 1 pronta, Fases 2/3 não iniciadas -
  **usuário disse que já tem uma ideia de abordagem, não decidir sozinho**.
- Fossauro: MSX2 puro trava num segundo loop de polling ainda não identificado (MSX2+ funciona 100%).
- Fossauro: controlador de disquete (WD1793) real ainda não integrado - itens de menu existem mas não
  fazem nada.
- `others/`: 5 diretórios sem referência no código, candidatos a remoção, ainda não apagados.
- 8.3.0 ainda sem entrada formal em `docs/RELEASE_NOTES.md` (ver "Versão atual" acima).

## Orientação rápida pra uma sessão nova (qualquer PC)

- Ler `CLAUDE.md` primeiro (comandos de build, convenções do repo, achados recentes documentados lá).
- `docs/SPEC.md` é a fonte de verdade de arquitetura - módulos numerados, mais recente no fim.
- Compilar: `.\build.ps1` (Windows) / `./build.sh` (WSL/Linux) - caminho do `pbcompiler` fica salvo em
  `build.config.json`/`build.config.linux.json` (gitignored, por máquina - **vai precisar reconfigurar
  em cada PC novo com `-C "<caminho>"` na primeira vez**).
- Testar mudanças no pré-processador/tokenizador: `src/editor/tools/DigTestCli.exe` contra
  `dist/sample/teste.dmx` (regressão real, ~900 linhas, "Change Graph Kit" de Fred Rique).
- Verificação de GUI ao vivo: **nunca clique real de mouse** (`SetCursorPos`/`mouse_event`) - só
  mensagem direcionada a um HWND específico (`WM_COMMAND`/`BM_CLICK`/`WM_CHAR`) - ver incidente
  documentado no módulo 37 e a memória `gui_screenshot_verification.md`.
