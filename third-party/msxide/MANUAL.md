# Manual do msxIDE

Guia de instalação, compilação e uso do msxIDE. Para arquitetura/decisões de projeto veja
[SPEC.md](SPEC.md); para o histórico de versões veja [CHANGELOG.md](CHANGELOG.md).

## 1. O que é

Um ambiente de desenvolvimento em modo texto (TUI) pra MSX BASIC (via a suíte **Basic Dignified**) e
Z80 Assembly (via **asMSX**), com editor multi-janela, compilação/execução no **openMSX**, sistema de
projetos, ajuda integrada com dez documentos de referência MSX, e um monitor/assembler Z80 interativo
completo (**Mamute Assembler**), com editor de linhas estilo ZX-81 e assembler nativo próprio.

## 2. Dependências

| Dependência | Necessário para | Como obter |
|---|---|---|
| **FreeBASIC** (`fbc64.exe`) | Compilar o msxIDE | [freebasic.net](https://www.freebasic.net/) |
| **PowerShell** | Rodar `build.ps1` e os scripts de teste | Já vem no Windows 10/11 |
| **sqlite3.dll** | Rodar o msxIDE (persistência) | Baixado automaticamente pelo `build.ps1` na primeira execução |
| **asMSX** (`asmsx.exe`) | Compilar Z80 Assembly | Já incluso em `asMSX/` |
| **Basic Dignified Suite** | Documentação (`Ajuda`) e arquivos de configuração padrão — o pipeline de compilação MSX BASIC em si é nativo do msxIDE, não chama a suíte Python | Já incluso em `basic-dignified/` |
| **openMSX** | Executar os programas compilados | Instalar à parte e apontar o caminho em `Configurar -> Emulador` |
| **newt-freebasic** | Só se for compilar com `--Backend newt` | Já incluso em `newt-freebasic/` |

O msxIDE roda em Windows (console nativo, backend `win`) e experimentalmente em outros terminais via
backend `newt` (mouse virtual por teclado — `F8` liga/desliga, setas/HJKL movem, Espaço/Enter clicam).

## 3. Download e instalação

1. Clone o repositório (ou baixe o `.zip`).
2. Instale o FreeBASIC e anote o diretório de instalação (ex.: `C:\dos\freebasic`).
3. Não é preciso instalar SQLite manualmente — o `build.ps1` baixa `sqlite3.dll` sozinho na primeira
   compilação, se ela ainda não existir na pasta do projeto.
4. (Opcional, pra rodar programas) instale o [openMSX](https://openmsx.org/) e configure o caminho em
   `Configurar -> Emulador` dentro do próprio msxIDE, ou na chave `cfg.emulator.windows.emulator_path`.

### 3.1. Instalação simples (sem compilar nada)

Quem só quer usar o msxIDE, sem mexer no código-fonte, tem dois caminhos prontos (gerados por
`.\build-distribute.ps1` — ver seção 4.1):

- **`distribute/`** — uma cópia portátil já pronta: só descompactar em qualquer pasta e rodar
  `msxide.exe` de dentro dela. Sem instalação nenhuma.
- **`installer.exe`** — instalador guiado: copia os arquivos pra
  `%LOCALAPPDATA%\msxIDE` (ou outro caminho à sua escolha), cria um atalho no Menu Iniciar e registra
  uma entrada em "Aplicativos e recursos" do Windows (com desinstalador). Rode `installer.exe` e
  responda a pergunta de pasta de instalação (Enter aceita o padrão sugerido), ou passe o caminho
  direto por linha de comando pra uma instalação silenciosa: `installer.exe C:\caminho\desejado`.

Nenhum dos dois precisa de FreeBASIC, Python ou qualquer outra dependência instalada — `distribute/`
já vem com tudo que o msxIDE lê em tempo de execução (ver manifesto completo em
[SPEC.md](SPEC.md#1-visão-geral-da-arquitetura)).

## 4. Compilação

Primeira vez (grava compilador e pasta do FreeBASIC como padrão em `.build-config.json`):

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 --Basic C:\dos\freebasic --Compiler fbc64.exe --Backend win
```

Depois disso, builds seguintes só precisam de:

```powershell
.\build.ps1
```

Outras opções úteis:

```powershell
.\build.ps1 --Backend newt          # compila com o backend newt em vez do nativo do Windows
.\build.ps1 --Run                   # compila e ja executa msxide.exe
.\build.ps1 --Version 1.2.3         # define uma versao manual
.\build.ps1 --Version release       # incrementa o patch (X.Y.Z+1)
.\build.ps1 --Version minor         # incrementa o minor, zera o patch (X.Y+1.0)
.\build.ps1 --Version major         # incrementa o major, zera minor/patch (X+1.0.0)
.\build.ps1 --Help                  # lista todas as opcoes
```

Se o código-fonte mudar e `--Version` não for informado, o script incrementa o patch automaticamente
(release auto). A versão atual fica gravada em `src/version.bi` (gerado a cada build) e aparece na
barra de status do editor.

O build compila `src/main.bas src/editor.bas src/compiler.bas src/db.bas src/project.bas
src/console.bas` (os backends `console_win.bas`/`console_newt.bas` entram via `#Include` dentro de
`console.bas`) e gera `msxide.exe` na raiz do projeto.

### 4.1. Gerando a distribuição (`distribute/` + `installer.exe`)

Depois de um `.\build.ps1` normal (precisa de `msxide.exe`/`sqlite3.dll` já gerados):

```powershell
.\build-distribute.ps1
```

Isso recria `distribute/` do zero (cópia portátil com tudo que o msxIDE lê em runtime — `ajuda/`,
`docs/`, `basic-dignified/`, `asMSX/`, já sem os arquivos que só servem pra compilar/desenvolver essas
ferramentas) e compila `installer.exe` a partir de `installer/installer.bas`. Nenhum dos dois arquivos
vai pro controle de versão (`.gitignore`) — são gerados a cada release.

## 5. Executando

```powershell
.\msxide.exe                        # abre com o documento padrao (msx00.dmx)
.\msxide.exe arquivo1.dmx arquivo2.asm   # abre um ou mais arquivos
```

Testes headless (não precisam de teclado/mouse, seguros pra rodar em automação):

```powershell
.\msxide.exe --smoke-help           # valida o sistema de ajuda/referencia inteiro
.\msxide.exe --smoke-mamute         # valida o round-trip da config de memoria do Mamute (usa um banco descartavel proprio)
.\msxide.exe --smoke-editor         # valida selecao/clipboard/undo-redo/busca/navegacao do editor de textos
.\msxide.exe --smoke-keys           # valida a traducao Ctrl/Alt+tecla (backend win) sem precisar de teclado real
```

Suíte de testes completa:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-tests.ps1                    # regressao + smoke
powershell -ExecutionPolicy Bypass -File .\tests\regression\run-regression.ps1    # so regressao
powershell -ExecutionPolicy Bypass -File .\tests\smoke\run-help-smoke.ps1         # so smoke de help
```

## 6. Visão geral dos menus

- **Arquivo**: novo documento (Basic Dignified, asMSX, Markdown, Editor de Fontes MSX ou Editor de
  Sprites MSX), abrir/salvar/fechar, e o sistema de projetos (`.msxproj`).
- **Configurar**: ajustes de Basic Dignified, MSX Basic (tokenizer), Emulador, configurador de
  memória do Mamute Assembler, Impressora, e Editor (quantidade de espaços que o `Tab` insere).
- **Compilar**: MSX-Basic clássico, Basic Dignified, tokenizar AMX, compilar+executar no emulador, e o
  log de compilação.
- **Ajuda**: documentação dos dialetos suportados, dicionário MSX BASIC completo, e o guia do próprio
  editor (atalhos de teclado — veja também a seção 7 abaixo).
- **Referência**: dez documentos técnicos MSX (Red Book, manuais, BIOS, openMSX, Nestor Basic, SEE
  Tracker, MSXBAS2ROM).
- **Mamute**: abre o terminal `MON>` do Mamute Assembler.
- **Ajuda**: além da documentação dos dialetos e do guia do editor, também traz a referência completa do
  Mamute Assembler (todos os comandos do monitor, o editor `EDIT` e o comando `A`) — digite `HELP` no
  próprio terminal `MON>` ou use `Ajuda -> Mamute Assembler`.
- **Inserir**: grade de caracteres especiais MSX (acentos/gráficos 128-255 e os símbolos que viram
  letra, mesmo conjunto do "Translate" do Basic Dignified Suite) — `Alt+I`.

## 7. Atalhos essenciais

| Tecla | Ação |
|---|---|
| `F10` | Abre o menu Arquivo |
| `F1` | Abre o menu Ajuda |
| `Shift+F1` | Verbete do dicionário MSX BASIC para a palavra sob o cursor |
| `F2` / `F3` / `F4` / `F5` | Salvar / Abrir / Novo / Fechar |
| `F6` | Alterna para a próxima janela aberta |
| `F8` / `F9` | Abre o menu Compilar / Configurar |
| `Ctrl+L` | Abre o log de compilação direto |
| `Esc` | Fecha menu/diálogo aberto, ou sai do msxIDE |
| Roda do mouse | Rola o texto (edição e ajuda) |

Edição de texto ao estilo Microsoft Edit/VS Code: `Shift`+movimento seleciona (`Ctrl+Seta` seleciona
por palavra, `Ctrl+Shift+Seta` por parágrafo, `Shift+PgUp/PgDn` por tela, `Ctrl+A` o documento
inteiro), `Ctrl+C`/`Ctrl+X`/`Ctrl+V` (ou `Ctrl+Insert`/`Shift+Delete`/`Shift+Insert`, o trio clássico
dos editores MS-DOS) copiam/recortam/colam (área de transferência real do Windows,
funciona com outros programas), `Ctrl+Z`/`Ctrl+Y` desfazem/refazem, `Ctrl+F`/`Ctrl+H`
localizam/substituem, e `Ctrl+Seta`/`Ctrl+Seta vertical`/`Ctrl+PgUp/PgDn` andam por palavra/
parágrafo/meia tela.

Menus: `Alt+letra` abre qualquer um dos sete direto (`A` Arquivo, `O` Configurar, `C` Compilar, `R`
Referência, `M` Mamute, `J` Ajuda, `I` Inserir); com um menu aberto, `Seta esquerda/direita` troca de
menu, `Seta cima/baixo` navega os itens e `Enter` confirma.

Lista completa e sempre atualizada: `Ajuda -> Editor` dentro do próprio programa.

## 8. Persistência

Banco `msxide.db` (SQLite) na pasta do executável — tabelas `settings`, `projects`, `documents`, mais
métricas de performance por segundo (`perf_metrics_sec`). Um `.msxproj` (sistema de projetos) é um
segundo banco SQLite independente, autocontido, que pode ser levado pra outra máquina.

## 9. Estrutura de diretórios (resumo)

```
src/            codigo-fonte FreeBASIC do msxIDE (ver apelidos dos modulos em SPEC.md)
asMSX/          assembler Z80 (binario + doc + fontes)
basic-dignified/ suite Basic Dignified (compilador/tokenizer MSX BASIC)
ajuda/          dados de referencia MSX (Red Book, manuais, BIOS, etc.) usados pelo menu Referencia
docs/help/      paginas de ajuda em markdown simples (Nestor Basic, SEE Tracker, MSXBAS2ROM, Editor, Markdown)
roms/           roms/dumps usados em runtime (msx1.alf = fonte MSX1 padrao do Editor de Fontes)
newt-freebasic/ backend newt (so necessario para --Backend newt)
tests/          regressao + smoke tests
build.ps1       script de build/versionamento
```
