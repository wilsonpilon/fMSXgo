# Manual da IDE — MSX BASIC + Z80

> Manual de uso da ferramenta em si (compilar, executar, editor de texto, telas de
> configuração). Para a linguagem **Basic Dignified** (o que você escreve dentro do
> editor), veja [`BADIG-USER.md`](BADIG-USER.md), [`DIGNIFIER-USER.md`](DIGNIFIER-USER.md)
> e [`BATOKEN-USER.md`](BATOKEN-USER.md). Para a especificação/arquitetura do projeto,
> veja [`SPEC.md`](SPEC.md).
>
> Documento vivo — cresce conforme novas partes da IDE (editores visuais, etc.) forem ficando
> prontas. Hoje cobre o editor de texto, o pipeline de conversão/tokenização/renumeração de
> MSX-BASIC clássico, o gerenciador de disco, o editor de sprites, o editor de alfabetos
> (Graphos III e Aquarela), o editor de som, o editor de música, o editor de DRAW Screen 2, o
> assembler Z80 (nativo e a integração com N80/LinkStor80/LibStor80), o sistema de projeto, a
> ajuda embutida de MSX BASIC/MSX2+, o suporte a NestorBASIC e a MSXBAS2ROM, o editor
> hexadecimal e o processo de build.

---

## Índice

1. [Compilação](#compilação)
2. [Execução](#execução)
3. [O editor de texto](#o-editor-de-texto)
   - [Atalhos de teclado](#atalhos-de-teclado)
   - [Buscar / Substituir / Ir para linha](#buscar--substituir--ir-para-linha)
   - [Arquivo](#arquivo)
   - [Projeto](#projeto)
   - [Desfazer / refazer](#desfazer--refazer)
   - [Executar](#executar)
   - [Criar (editores visuais)](#criar-editores-visuais)
   - [Outros atalhos](#outros-atalhos)
   - [Ajuda → Editor...](#ajuda--editor)
   - [Barra de status](#barra-de-status)
4. [MSX-BASIC clássico: converter, tokenizar e renumerar](#msx-basic-clássico-converter-tokenizar-e-renumerar)
   - [Executar → Renumerar...](#executar--renumerar)
5. [Telas de configuração](#telas-de-configuração)
   - [Temas](#temas)
   - [Botões com ícones](#botões-com-ícones)
   - [Associações de arquivo](#associações-de-arquivo)
6. [Auto completar](#auto-completar)
   - [Auto-indentação](#auto-indentação)
7. [Gerenciador de disco MSX](#gerenciador-de-disco-msx)
   - [Menu Criar → Disco... (gerenciador gráfico)](#menu-criar--disco-gerenciador-gráfico)
   - [Linha de comando (`--diskmanipulator`)](#linha-de-comando---diskmanipulator)
8. [Sistema de projeto (arquivo `.msxproject`)](#sistema-de-projeto-arquivo-msxproject)
   - [Projeto implícito "noname"](#projeto-implícito-noname)
   - [Menu Projeto → Novo projeto... / Abrir projeto...](#menu-projeto--novo-projeto--abrir-projeto)
   - [Menu Projeto → Salvar projeto / Salvar projeto como...](#menu-projeto--salvar-projeto--salvar-projeto-como)
   - [Menu Projeto → Índice de recursos...](#menu-projeto--índice-de-recursos)
   - [Abrir um `.msxproject` com duplo clique](#abrir-um-msxproject-com-duplo-clique)
   - [Cópia das abas de texto e diretório de trabalho](#cópia-das-abas-de-texto-e-diretório-de-trabalho)
   - [Ao sair](#ao-sair)
9. [Editor de sprites](#editor-de-sprites)
   - [Grade, tamanho e modo de cor](#grade-tamanho-e-modo-de-cor)
   - [Ferramentas de desenho](#ferramentas-de-desenho)
   - [Barra de projeto (registrar, navegar, copiar/colar)](#barra-de-projeto-registrar-navegar-copiarcolar)
10. [Editor de alfabetos](#editor-de-alfabetos)
   - [Tabela de caracteres e grade de edição](#tabela-de-caracteres-e-grade-de-edição)
   - [Marcar bloco (aplicar um efeito num intervalo de caracteres de uma vez)](#marcar-bloco-aplicar-um-efeito-num-intervalo-de-caracteres-de-uma-vez)
   - [Desfazer / refazer](#desfazer--refazer-1)
   - [Efeitos de glifo (espelhar, girar, estreitar, itálico, negrito, largo)](#efeitos-de-glifo-espelhar-girar-estreitar-itálico-negrito-largo)
   - [Copiar/colar um alfabeto inteiro](#copiarcolar-um-alfabeto-inteiro)
   - [Arquivo .ALF (Graphos III)](#arquivo-alf-graphos-iii)
   - [Barra de projeto e o alfabeto padrão ("projeto 0")](#barra-de-projeto-e-o-alfabeto-padrão-projeto-0)
11. [Editor de som (PSG)](#editor-de-som-psg)
    - [Canais A/B/C, ruído e envelope](#canais-abc-ruído-e-envelope)
    - [Sequência de passos](#sequência-de-passos)
    - [Tocar / Parar](#tocar--parar)
    - [Gerar código e injetar no editor](#gerar-código-e-injetar-no-editor)
    - [Barra de projeto](#barra-de-projeto)
12. [Editor SEE Tracker](#editor-see-tracker)
    - [A grade e o painel de edição](#a-grade-e-o-painel-de-edição)
    - [Patterns: inserir, apagar, mover, copiar](#patterns-inserir-apagar-mover-copiar)
    - [Tocar / Parar](#tocar--parar-1)
    - [Gerar código, Injetar no cursor, Copiar](#gerar-código-injetar-no-cursor-copiar)
    - [Importar .SEE...](#importar-see)
    - [Barra de projeto](#barra-de-projeto-1)
13. [Editor de música (MML/PLAY)](#editor-de-música-mmlplay)
    - [Montando uma linha](#montando-uma-linha)
    - [Lista de linhas por canal](#lista-de-linhas-por-canal)
    - [Tocar / Parar](#tocar--parar-2)
    - [Gerar código e injetar no editor](#gerar-código-e-injetar-no-editor-1)
    - [Barra de projeto](#barra-de-projeto-2)
14. [Editor de alfabetos Aquarela](#editor-de-alfabetos-aquarela)
    - [Tabela de 46 caracteres e grade 16x16](#tabela-de-46-caracteres-e-grade-16x16)
    - [Arquivo .FNT](#arquivo-fnt)
15. [Editor de DRAW Screen 2](#editor-de-draw-screen-2)
    - [Canvas, paleta e cor de tinta/fundo](#canvas-paleta-e-cor-de-tintafundo)
    - [Ferramentas de desenho](#ferramentas-de-desenho-1)
    - [Parâmetros STEP e LINE -(x,y)](#parâmetros-step-e-line--xy)
    - [Ferramenta TEXTO — quadro elástico arrastável](#ferramenta-texto--quadro-elástico-arrastável)
    - [Lista de comandos e mini buffers](#lista-de-comandos-e-mini-buffers)
    - [Gerar código e injetar no editor](#gerar-código-e-injetar-no-editor-2)
    - [Barra de projeto](#barra-de-projeto-3)
16. [Graphos III — Tela SCREEN 2](#graphos-iii--tela-screen-2)
    - [Canvas e color clash](#canvas-e-color-clash)
    - [Paleta INK/PAPER e ferramentas](#paleta-inkpaper-e-ferramentas)
17. [Assembler Z80](#assembler-z80)
    - [Aba Assembly (.asm)](#aba-assembly-asm)
    - [Montar (Ctrl+F5)](#montar-ctrlf5)
    - [O que já é suportado](#o-que-já-é-suportado)
    - [Montar relocável (.REL)](#montar-relocável-rel)
    - [Linkar (.REL) → binário](#linkar-rel--binário)
    - [Biblioteca Z80 (.LIB)](#biblioteca-z80-lib)
    - [Assembly Sub Project (Makefile primitivo)](#assembly-sub-project-makefile-primitivo)
    - [O que ainda não é suportado](#o-que-ainda-não-é-suportado)
18. [Ajuda MSX BASIC (dicionário e manual, MSX1 e MSX2+)](#ajuda-msx-basic-dicionário-e-manual-msx1-e-msx2)
    - [Abrindo e navegando](#abrindo-e-navegando)
    - [O que está coberto](#o-que-está-coberto)
19. [Suporte a NestorBASIC](#suporte-a-nestorbasic)
    - [Arquivo → Novo Nestor Basic...](#arquivo--novo-nestor-basic)
    - [Executar → Nestor Basic](#executar--nestor-basic)
    - [Ajuda → Nestor Basic...](#ajuda--nestor-basic)
20. [Suporte a MSXBAS2ROM](#suporte-a-msxbas2rom)
    - [Arquivo → Novo MSXBas2Rom...](#arquivo--novo-msxbas2rom)
    - [Configurar → MSXBas2Rom...](#configurar--msxbas2rom)
    - [Ajuda → MSXBas2Rom...](#ajuda--msxbas2rom)
21. [N80, LinkStor80 e LibStor80](#n80-linkstor80-e-libstor80)
    - [Configurar → N80...](#configurar--n80)
    - [Ajuda → N80...](#ajuda--n80)
22. [asMSX](#asmsx)
    - [Arquivo → Novo asMSX...](#arquivo--novo-asmsx)
    - [Executar → Montar Fonte asMSX...](#executar--montar-fonte-asmsx)
    - [Configurar → asMSX...](#configurar--asmsx)
    - [Ajuda → asMSX...](#ajuda--asmsx)
23. [Base de conhecimento MSX (manuais antigos, livros técnicos)](#base-de-conhecimento-msx-manuais-antigos-livros-técnicos)
    - [Ajuda → Manuais MSX...](#ajuda--manuais-msx)
    - [Ajuda → MSX-Basic/DOS/CP-M (RuMSX)...](#ajuda--msx-basicdoscp-m-rumsx)
    - [Ajuda → BIOS MSX: Chamadas / Hardware / Documentação (RuMSX)...](#ajuda--bios-msx-chamadas--hardware--documentação-rumsx)
    - [Ajuda → Livro Vermelho...](#ajuda--livro-vermelho)
    - [Ajuda → MSX2 Technical Handbook...](#ajuda--msx2-technical-handbook)
24. [Ajuda Basic Dignified (sintaxe da linguagem e configurações desta IDE)](#ajuda-basic-dignified-sintaxe-da-linguagem-e-configurações-desta-ide)
    - [O que está coberto](#o-que-está-coberto-1)
25. [Ajuda SEE Tracker (manual original e formato de arquivo)](#ajuda-see-tracker-manual-original-e-formato-de-arquivo)
    - [O que está coberto](#o-que-está-coberto-2)
26. [Editor Hexa](#editor-hexa)
    - [Abrir/Salvar e a grade hex/ASCII](#abrirsalvar-e-a-grade-hexascii)
    - [Reconhecimento de formato](#reconhecimento-de-formato)
    - [Galeria de templates](#galeria-de-templates)
    - [Intervalo marcado e operações de bloco](#intervalo-marcado-e-operações-de-bloco)
    - [Barra de rolagem](#barra-de-rolagem)
27. [Inserir → Caractere Especial](#inserir--caractere-especial)
    - [A grade e a prévia](#a-grade-e-a-prévia)
    - [Campo acumulador e o botão Inserir](#campo-acumulador-e-o-botão-inserir)
28. [Editor de tela SCREEN 0](#editor-de-tela-screen-0)
    - [Largura, fonte e cor (INK/PAPER único pra tela inteira)](#largura-fonte-e-cor-inkpaper-único-pra-tela-inteira)
    - [Ferramentas](#ferramentas)
    - [Gerar código e injetar no editor](#gerar-código-e-injetar-no-editor-3)
    - [Barra de projeto](#barra-de-projeto-4)
29. [Editor de tela SCREEN 1](#editor-de-tela-screen-1)
    - [Fonte e a tabela ASCII do alfabeto (cor por octeto)](#fonte-e-a-tabela-ascii-do-alfabeto-cor-por-octeto)
    - [Ferramentas](#ferramentas-2)
    - [Gerar código e injetar no editor](#gerar-código-e-injetar-no-editor-4)
    - [Barra de projeto](#barra-de-projeto-5)
30. [Editor de tela SCREEN 1+2](#editor-de-tela-screen-12)
    - [3 alfabetos, um por terço da tela](#3-alfabetos-um-por-terço-da-tela)
    - [Cor por linha de scanline (o modo mais complexo)](#cor-por-linha-de-scanline-o-modo-mais-complexo)
    - [Ferramentas](#ferramentas-3)
    - [Gerar código e injetar no editor](#gerar-código-e-injetar-no-editor-5)
    - [Barra de projeto](#barra-de-projeto-6)
31. [Mamute Assembler](#mamute-assembler)
    - [Configurar → Mamute Assembler...](#configurar--mamute-assembler)
    - [Comandos disponíveis](#comandos-disponíveis)
    - [DM - navegação e edição](#dm---navegação-e-edição)
    - [M e S - edição rápida de memória](#m-e-s---edição-rápida-de-memória)
    - [ZAP - editor de setores de disco](#zap---editor-de-setores-de-disco)
    - [SCR - display gráfico da memória](#scr---display-gráfico-da-memória)
    - [SH - busca de bytes ou texto](#sh---busca-de-bytes-ou-texto)
    - [MS - grava uma string na memória](#ms---grava-uma-string-na-memória)
    - [LOAD e SAVE](#load-e-save)
    - [C, D, P e V - despejo formatado de memória](#c-d-p-e-v---despejo-formatado-de-memória)
    - [T e F - transferir e preencher blocos](#t-e-f---transferir-e-preencher-blocos)
    - [G e X - execução e registradores](#g-e-x---execução-e-registradores)
    - [R, L e LP - referência de fita e disassembler](#r-l-e-lp---referência-de-fita-e-disassembler)
    - [EDIT - editor do programa-fonte Z80](#edit---editor-do-programa-fonte-z80)
    - [A - montar o programa](#a---montar-o-programa)
    - [Comandos do SUPER-X (prefixo X)](#comandos-do-super-x-prefixo-x)
32. [Fossauro (emulador MSX nativo)](#fossauro-emulador-msx-nativo)
    - [O que já funciona hoje](#o-que-já-funciona-hoje)
    - [Linha de comando](#linha-de-comando)
    - [O que o manual original do Fossauro descreve mas ainda não existe](#o-que-o-manual-original-do-fossauro-descreve-mas-ainda-não-existe)

---

## Compilação

O executável é gerado pelo compilador do PureBasic (`pbcompiler.exe`) através do script
[`build.ps1`](../build.ps1), na raiz do projeto. Não é necessário abrir a IDE do
PureBasic — o script cuida de tudo pelo PowerShell.

```powershell
.\build.ps1
```

Isso compila `editor\BadigEditor.pb` e gera `editor\PaleoBasic.exe`.

### Onde o script encontra o `pbcompiler.exe`

Nesta ordem de prioridade:

1. Opção `-C` / `--compiler` na linha de comando.
2. Valor salvo em `build.config.json` (criado automaticamente ao lado do script, na
   primeira vez que `-C`/`--compiler` é usado — não versionado no git, é específico de
   cada máquina).
3. Caminho padrão: `%PROGRAMFILES%\PureBasic\Compilers\pbcompiler.exe`.

```powershell
# Primeira vez numa maquina nova (caminho fica salvo para as proximas execucoes)
.\build.ps1 -C "C:\Basic\Compilers\pbcompiler.exe"

# Depois, basta:
.\build.ps1
```

### Parâmetros

`-H`/`--help`, `-C`/`--compiler` e `-R`/`--run` seguem o formato Unix (letra curta +
nome longo com `--`). Os demais ficam no estilo nativo do PowerShell (só forma longa,
um traço).

| Parâmetro | Descrição |
|---|---|
| `-C`, `--compiler <caminho>` | Caminho para o `pbcompiler.exe`. |
| `-R`, `--run` | Executa o programa automaticamente após uma compilação sem erros. |
| `-H`, `--help` | Mostra a lista de opções e sai. |
| `-V`, `--version <versão>` | Versão embutida no executável (padrão `7.1.1`). |
| `-i`, `--sourcefile <arquivo>` | Arquivo fonte a compilar (padrão `editor\BadigEditor.pb`). |
| `-o`, `--outputexe <arquivo>` | Caminho do executável de saída (padrão `editor\PaleoBasic.exe`). |

```powershell
# Compila e ja abre o programa
.\build.ps1 -R
.\build.ps1 --run

# Marca uma nova versao
.\build.ps1 -V "5.8.0" -R

# Lista as opcoes
.\build.ps1 -H
```

### Versão e build

A cada compilação, o script grava no executável (via `/CONSTANT` do `pbcompiler.exe`):

- **Versão** — string livre (`-V`/`--version`, padrão `7.1.1`).
- **Build** — data/hora **UTC** do momento da compilação, convertida para **hexadecimal**
  (segundos desde a época Unix, ex.: `6A57EA80`). Cada build tem um identificador único e
  ordenável.

Essas informações aparecem dentro do programa em **Ajuda → Sobre...**.

---

## Execução

Depois de compilado, basta rodar o executável gerado:

```powershell
.\editor\PaleoBasic.exe
```

ou usar `.\build.ps1 -Run` para compilar e abrir em um único passo.

Na primeira execução vale abrir **Configurar → Editor...** para escolher fonte e tema, e
**Configurar → Basic Dignified...** para apontar (ou baixar) o toolchain Python de
referência — ver [Telas de configuração](#telas-de-configuração).

---

## O editor de texto

### Atalhos de teclado

O editor usa o teclado padrão Scintilla/Windows — o mesmo estilo de VSCode, Sublime Text
ou qualquer editor moderno. (Até uma versão anterior o editor tinha um modo próprio de
teclado no estilo WordStar/JOE; foi removido a favor do padrão abaixo.)

| Tecla | Ação |
|---|---|
| Setas | Move o cursor — com `Shift`, seleciona |
| `Ctrl+Seta esquerda/direita` | Pula uma palavra — com `Shift`, seleciona a palavra |
| `Home` / `End` | Início / fim da linha |
| `Ctrl+Home` / `Ctrl+End` | Início / fim do arquivo |
| `Page Up` / `Page Down` | Rola uma tela |
| `Ctrl+A` | Seleciona tudo |
| `Ctrl+C` / `Ctrl+X` / `Ctrl+V` | Copiar / recortar / colar |
| `Delete` / `Backspace` | Apaga caractere — com `Ctrl`, apaga a palavra |
| `Insert` | Alterna entre inserção e sobrescrita (ver [Barra de status](#barra-de-status)) |
| `Tab` / `Shift+Tab` | Indenta / remove indentação da seleção |

### Buscar / Substituir / Ir para linha

| Tecla | Ação |
|---|---|
| `Ctrl+F` | Buscar |
| `F3` | Buscar a próxima ocorrência |
| `Ctrl+H` | Substituir (tudo de uma vez ou confirmando ocorrência por ocorrência) |
| `Ctrl+G` | Ir para uma linha específica |

Também disponíveis pelo menu **Editar**.

### Arquivo

| Tecla | Ação |
|---|---|
| `Ctrl+S` | Salva o arquivo |
| `Ctrl+O` | Abre um arquivo |
| `Ctrl+W` | Fecha a aba atual (avisa se há alterações não salvas) |
| `Ctrl+Alt+S` | **Salvar Tudo** — salva todas as abas abertas e o projeto |

**Arquivo → Salvar Tudo** (`Ctrl+Alt+S`) salva todas as abas abertas, uma por uma (na ordem das abas,
pedindo "Salvar como..." pra qualquer aba ainda sem nome — igual `Ctrl+S` faria com ela individualmente,
só que pra todas de uma vez), e depois salva o projeto atual (`.msxproject`) também, se fizer sentido: um
projeto já salvo em arquivo permanente é sempre atualizado; um projeto ainda temporário ("noname") só é
salvo se já tiver algo de fato dentro dele (sprite, alfabeto, som, MML, tela, sub-projeto Assembly) — do
contrário "Salvar Tudo" não fica forçando um diálogo "Salvar projeto como..." vazio toda vez que você só
quer salvar uns arquivos de texto soltos. Se você cancelar o diálogo "Salvar como..." de alguma aba sem
nome, as demais abas (e o projeto) continuam sendo salvos normalmente — não trava tudo por causa de uma
aba cancelada.

**Tipos de arquivo**: o menu **Arquivo** tem comandos de "criar novo" que definem o tipo da aba —
**Novo** (`Ctrl+N`, MSX-BASIC/Dignified, `.dmx`), **Novo Assembly** (`Ctrl+Shift+N`, Z80 Assembly,
`.asm`), **Novo asMSX...** (Z80 Assembly, `.asm`, já com cabeçalho/diretivas pertinentes ao dialeto
asMSX — ver [asMSX](#asmsx)) e **Novo MSXBas2Rom...** (ASCII clássico numerado, `.bas` — ver [Suporte a
MSXBAS2ROM](#suporte-a-msxbas2rom)). Cada aba lembra seu próprio tipo (detectado automaticamente pela
extensão ao abrir um arquivo existente — `.asm`/`.z80`/`.mac` viram Assembly, `.bas` vira MSXBas2Rom, o
resto vira Dignified) e aplica o destaque de sintaxe certo: o dialeto Dignified numa aba `.dmx`
(estendido com os comandos/funções do MSXBAS2ROM — `CMD TURBO`, `SCREEN LOAD`, `HEAP()`,
`COLLISION()` etc. — só numa aba `.bas`, pra não confundir uma variável comum chamada `TURBO` num
programa Dignified qualquer), ou o vocabulário do assembler **N80/Nestor80** (mnemônicos, registradores,
diretivas, literais numéricos em qualquer radix) numa aba `.asm` — **Novo asMSX...** usa o mesmo
destaque de sintaxe Z80 (o lexer não distingue dialeto, só a diretiva com ponto muda de significado). O
motor que monta `.asm` em binário Z80 é nativo desta IDE (compatível M80/L80) — ver [Assembler
Z80](#assembler-z80). A IDE também consegue baixar o **N80/LinkStor80/LibStor80** de terceiro (mesmo
dialeto, mesmo autor do NestorBASIC) e o **asMSX** de terceiro (dialeto próprio) — ver [N80, LinkStor80 e
LibStor80](#n80-linkstor80-e-libstor80) e [asMSX](#asmsx). O asMSX já tem um botão próprio que monta
chamando o executável de verdade (**Executar → Montar Fonte asMSX...**); o N80/LinkStor80/LibStor80
ainda não têm — servem só pra uso via linha de comando fora da IDE por enquanto.

### Projeto

| Tecla | Ação |
|---|---|
| `Ctrl+Alt+N` | Novo projeto... |
| `Ctrl+Alt+O` | Abrir projeto... |
| `Ctrl+Alt+R` | Índice de recursos... |

Esses comandos (mais **Salvar projeto**/**Salvar projeto como...**/**Configurações do
projeto...**, sem tecla dedicada) ficam no menu **Projeto**, separado do **Arquivo** — ver
[Sistema de projeto](#sistema-de-projeto-arquivo-msxproject) para o detalhe de cada um.

### Desfazer / refazer

| Tecla | Ação |
|---|---|
| `Ctrl+Z` | Desfazer |
| `Ctrl+Y` | Refazer |

### Executar

| Tecla | Ação |
|---|---|
| `F5` | Executar BASIC no openMSX |
| `Shift+F5` | Executar Nestor Basic |
| `F6` | Renumerar... |
| `Ctrl+F5` | Montar Assembly (.bin)... |
| `Ctrl+Shift+F5` | Montar Assembly relocável (.REL)... |
| `Ctrl+Alt+F5` | Linkar (.REL) → binário... |
| `F7` | Editor Hexa... |
| `F8` | openMSX (console de comandos)... |
| `F9` | Ver MD/TXT... |
| `Shift+F9` | Ver MD+TXT... (lado a lado) |

Também disponíveis pelo menu **Executar**.

### Criar (editores visuais)

| Tecla | Ação |
|---|---|
| `Ctrl+Shift+D` | Disco... |
| `Ctrl+Shift+P` | Sprite... |
| `Ctrl+Shift+A` | Alfabeto Graphos III... |
| `Ctrl+Shift+G` | Som (PSG)... |
| `Ctrl+Shift+T` | SEE Tracker... |
| `Ctrl+Shift+M` | Música (PLAY)... |
| `Ctrl+Shift+2` | Draw Screen 2... |
| `Ctrl+Shift+0` | Screen 0... |
| `Ctrl+Shift+1` | Screen 1... |

Os itens restantes do menu **Criar** — Alfabeto Aquarela, Graphos III Screen 2, Screen 1+2,
Biblioteca Z80 (.LIB) e Assembly Sub Project — são variantes menos usadas dos editores acima e
ficaram só no menu (não valia a pena um terceiro/quarto modificador só para caber mais uma tecla).

### Outros atalhos

| Tecla | Ação |
|---|---|
| `Ctrl+Alt+I` | Inserir → Caractere Especial... (ver [Inserir → Caractere Especial](#inserir--caractere-especial)) |
| `Ctrl+Alt+E` | Configurar → Editor... |
| `F1` | Ajuda → Editor... (esta referência de atalhos) |

### Ajuda → Editor...

O menu **Ajuda → Editor...** (também `F1`) abre uma janela à parte com a referência dos atalhos
acima, organizada por seção (Cursor e seleção, Editar, Buscar, Arquivo, Executar, Criar, Inserir/
Configurar/Ajuda). Diferente da antiga tela embutida no estilo WordStar/JOE, é uma janela normal —
fecha pelo botão **Fechar** ou pelo X da janela, sem tomar o lugar do editor.

### Barra de status

O rodapé da janela mostra, sempre atualizado:

| Campo | Conteúdo |
|---|---|
| Modo | `INS` (inserção) ou `SBR` (sobrescrita — tecla `Insert`). |
| Nome do arquivo | Nome da aba ativa, com `*` se houver alterações não salvas. |
| Linha/Coluna | Posição atual do cursor no documento ativo. |

---

## MSX-BASIC clássico: converter, tokenizar e renumerar

Além do fluxo principal (Dignified → ASCII → tokenizado, disparado por **Executar → BASIC**/`F5`, ver
[Execução](#execução)), o menu **Arquivo** tem quatro comandos pra gerar/editar diretamente os formatos
intermediários — úteis pra inspecionar o resultado, gerar um `.bmx`/`.amx` sem abrir o openMSX, ou
trabalhar com um listing MSX-BASIC clássico (numerado, sem Dignified) que já existia antes, vindo de
uma revista/outro editor:

- **Dignified → ASCII nativo (.amx)...** — roda só o pré-processador (resolve labels/loops/`DEFINE`/
  `DECLARE`/`INCLUDE`/remtags) e salva o resultado como ASCII clássico numerado, sem tokenizar.
- **Dignified → tokenizado nativo (.bmx)...** — encadeia pré-processador + tokenizador nativo, gera o
  binário `.bmx` direto a partir do Dignified da aba atual.
- **ASCII clássico já aberto → tokenizado nativo (.bmx)...** — para quando a aba **já é** ASCII clássico
  (não Dignified): tokeniza direto, sem passar pelo pré-processador. Se a aba parecer Dignified (não
  começa com número), avisa e sugere o comando acima no lugar.
- **ASCII clássico já aberto → renumerar e criar .BAS...** — pega o mesmo tipo de aba e **renumera** as
  linhas para a sequência mais compacta possível (`1,2,3...` — números baixos ocupam menos bytes no
  `.bmx` final), corrigindo automaticamente todo `GOTO`/`GOSUB`/`THEN`/`ELSE`/`RESTORE`/`RESUME`/
  `RETURN`/`RUN` (inclusive listas `ON...GOTO`/`ON...GOSUB`) para apontar pra linha renumerada certa, e
  removendo espaços redundantes. Deixa salvar como `.bas` (extensão padrão que o MSX-DOS/MSX-BASIC
  reconhece), `.amx` (convenção interna desta IDE) ou, encadeando com o tokenizador, `.bmx`.

**Detecção automática**: os dois últimos comandos (e o F5 normal) reconhecem sozinhos se a aba é ASCII
clássico — a primeira linha com conteúdo começa com um número. Um `.bas` do MSXBAS2ROM (ver [Suporte a
MSXBAS2ROM](#suporte-a-msxbas2rom)) já é reconhecido assim, sem precisar de nenhum comando especial.

### Executar → Renumerar...

Atalho: `F6`.

Equivalente nativo do comando `RENUM` real do MSX-BASIC — ao contrário dos comandos de **Arquivo**
acima (que sempre exportam pra um arquivo novo), este **renumera o programa digitado na própria aba, no
lugar**, exatamente como o `RENUM` faz ao vivo na máquina. Pede os mesmos 3 parâmetros do comando
original, um de cada vez:

1. **Nova linha inicial** (padrão `10`)
2. **Incremento entre as linhas** (padrão `10`)
3. **Renumerar a partir de qual linha** (número antigo — deixe em branco pra renumerar o programa
   inteiro)

Linhas antes da "linha a partir de qual renumerar" mantêm o número **original**, mas continuam entrando
na resolução de `GOTO`/`GOSUB` — uma referência que aponte pra uma dessas linhas preservadas continua
correta. Se a nova numeração escolhida for colidir com a faixa preservada (ficar fora de ordem), o
comando recusa com um erro em vez de gerar um programa quebrado — mesma recusa que o `RENUM` real faz.
O resultado fica no editor normalmente (desfazer com `Ctrl+U` funciona, e a aba é marcada como
modificada) — não salva sozinho, revise e salve como de costume.

---

## Telas de configuração

- **Configurar → Editor...** (atalho `Ctrl+Alt+E`) — fonte (só monoespaçadas, com botão para baixar fontes
  [Nerd Fonts](https://www.nerdfonts.com/) direto de dentro da IDE), tema (4 opções — ver
  [Temas](#temas)), fonte de ícones (opcional — ver [Botões com ícones](#botões-com-ícones)),
  estilo de abas, caminho de instalação do editor.

### Temas

O combo **Tema** em **Configurar → Editor...** tem 4 opções — todas claras desde a 7.33.10 (os 5 temas
escuros foram removidos: os controles nativos que o PureBasic não deixa recolorir — combo, lista,
checkbox, scrollbar — ficavam com contraste ruim contra um fundo escuro; contra um fundo claro o
mesmo cinza nativo passa despercebido). Cada uma com sua própria paleta de cores da área de edição,
abas, régua de colunas e destaque de sintaxe:

| Tema | Estilo |
|---|---|
| Neve | Claro neutro — o padrão da IDE |
| Bege | Claro, papel envelhecido (estilo Solarized Light) |
| Neblina | Claro, azulado e frio |
| Linho | Claro, lilás/lavanda |

A troca vale só depois de **Salvar** — não tem pré-visualização ao vivo enquanto o combo está aberto.

**O que muda e o que não muda**: a área do editor (Scintilla), as abas, a régua de colunas, o fundo
de toda janela de diálogo e os próprios botões (ver [Botões com ícones](#botões-com-ícones)) seguem
o tema escolhido de verdade. O que continua com a aparência padrão do Windows em qualquer tema —
limitação do PureBasic, não do tema escolhido — são os controles que não dá pra redesenhar: combos,
campos de texto, listas e checkboxes; desde a 7.33.10 o executável é compilado com `/XP` (manifesto de
tema moderno do Windows), então pelo menos esses controles usam o visual nativo atual do Windows em
vez do estilo antigo sem tema.

### Botões com ícones

Todas as janelas de diálogo da IDE (telas de **Configurar**, editores visuais — Sprite, Alfabetos,
Som, SEE Tracker, Telas, Música, DRAW Screen 2 — gerenciador de disco, console do openMSX, telas
de Ajuda, Editor Hexa etc.) tematizam seus próprios botões em vez de usar o botão nativo do Windows
(que ignora `Color_*`) — cada um é desenhado na hora: fundo e borda na cor do tema, texto
centralizado na mesma fonte já escolhida em **Configurar → Editor...**. A janela em si também
segue o fundo do tema (antes ficava branca/cinza nativa, destoando do editor).

Desde a 7.33.10 os botões mostram ícone **por padrão**, sem precisar configurar nada: uma
[Nerd Font](https://www.nerdfonts.com/) (`resource/fonts/SymbolsNerdFontMono-Regular.ttf`) vem
empacotada junto com o executável e é usada automaticamente. Os botões que representam uma ação
universalmente reconhecível (Fechar, Salvar, Copiar, Tocar, Parar, Ejetar, Inserir, Limpar,
Conectar/Desconectar, Voltar etc. — mais de 140 ao todo) mostram um ícone de verdade (não um
desenho genérico à mão), com o nome continuando disponível no tooltip ao passar o mouse. Ações bem
específicas de um módulo (ex.: "Gerar código PLAY", "Gravar disco MSX") ficam de propósito só com
texto — um ícone genérico ali confundiria mais do que ajudaria. O combo **Fonte de ícones** (mesma
tela **Configurar → Editor...**) tem três tipos de opção: **"(Nenhuma - usa texto)"** desliga os
ícones inteiramente, **"(Padrão - ícones embutidos)"** é o padrão descrito acima, e qualquer outra
entrada troca pra uma Nerd Font diferente já instalada no sistema (baixe uma pelo botão
**Baixar fontes (Nerd Fonts)...** logo acima, ou coloque um `.ttf`/`.otf` já patcheado na pasta de
fontes customizadas).
- **Configurar → Basic Options...** — liga/desliga o auto completar de abas MSX-BASIC/Dignified
  (`.dmx`/`.bas`) e ajusta quantas letras precisam ser digitadas antes dele aparecer, além da caixa
  das palavras-chave sugeridas — ver [Auto completar](#auto-completar).
- **Configurar → Assembly...** — a mesma coisa, mas para abas Assembly (`.asm`): liga/desliga,
  quantidade de letras, caixa dos mnemônicos/diretivas sugeridos. Independente da tela acima —
  cada modo guarda sua própria preferência de caixa (útil pra quem gosta de BASIC em minúsculas e
  Assembly em maiúsculas, ou vice-versa) — ver [Auto completar](#auto-completar).
- **Configurar → Basic Dignified...** — três abas:
  - **Basic Dignified** — opções do pré-processador/tokenizador e diretório de instalação do
    toolchain Python de referência (com botão para baixar via `git clone` ou `.zip` do GitHub).
  - **MSX** — opções específicas do dialeto/tokenizador MSX.
  - **Emulador** — caminho do executável do openMSX, **Máquina** e **Extensão de disco** (cada
    campo tem um botão "..." que lista as máquinas/extensões disponíveis em `share/machines`/
    `share/extensions` a partir do caminho do openMSX configurado, sem precisar digitar o nome de
    cabeça), e a opção **"Abrir o openMSX e rodar o código após gerar"**: quando marcada, o menu
    **Arquivo → Dignified → tokenizado nativo (.bmx)...** passa a montar um disquete com o programa
    gerado (mais um `AUTOEXEC.BAS` para rodar automaticamente) e abrir o openMSX direto nele, já
    com a máquina/extensão escolhidas.
- **Configurar → openMSX...** — tela própria só com os campos do emulador (executável, máquina,
  extensão) — os mesmos campos da aba **Emulador** acima, lendo e gravando exatamente o mesmo
  `badig_settings.json`. As duas telas nunca ficam dessincronizadas: mudar num lugar já reflete no
  outro na próxima vez que abrir, porque é literalmente o mesmo dado. Mantidas as duas de propósito,
  pra quem prefere acessar o ajuste do emulador direto sem entrar em "Basic Dignified...".
- **Configurar → MSXBas2Rom...** — baixa a versão mais recente do compilador de terceiro
  [MSXBAS2ROM](https://github.com/amaurycarvalho/msxbas2rom) e gera a Ajuda a partir do que foi
  baixado (ver [Suporte a MSXBAS2ROM](#suporte-a-msxbas2rom)).
- **Configurar → N80...** — baixa as versões mais recentes do N80/LinkStor80/LibStor80 de terceiro
  (e o manual M80L80) e gera a Ajuda a partir do que foi baixado (ver [N80, LinkStor80 e
  LibStor80](#n80-linkstor80-e-libstor80)).
- **Configurar → asMSX...** — caminho editável do executável (aponta pra uma instalação já existente,
  ou baixa a versão mais recente do [asMSX](https://github.com/Fubukimaru/asMSX) de terceiro direto do
  GitHub) — ver [asMSX](#asmsx).
- **Ajuda → Sobre...** — versão, build e data de compilação (ver
  [Versão e build](#versão-e-build)).

### Associações de arquivo

**Configurar → Associações de arquivo...** liga/desliga a associação de tipo de arquivo do Windows —
hoje só `.msxproject`, marcando a caixa correspondente faz o Windows abrir esse tipo de arquivo direto
no Paleobasic quando você dá 2 cliques nele no Explorer (ver [Abrir um `.msxproject` com duplo
clique](#abrir-um-msxproject-com-duplo-clique)). Grava em `HKEY_CURRENT_USER\Software\Classes` — não
precisa rodar como administrador, e não mexe em associações de outros programas: desmarcar só remove a
associação se ela ainda apontar pro Paleobasic. Se o `.exe` for movido/renomeado depois de associado, a
tela avisa que a associação ficou "desatualizada" (aponta pra uma cópia antiga) — desmarcar e marcar de
novo resolve. Só disponível no Windows.

---

## Auto completar

Enquanto você digita numa aba MSX-BASIC/Dignified (`.dmx`/`.bas`) ou Assembly (`.asm`), a IDE mostra
uma lista de sugestões assim que a palavra que você está digitando atinge um número mínimo de letras
(3 por padrão). A lista some sozinha se você continuar digitando um trecho que não bate com nada, ou se
apagar letras até ficar abaixo do mínimo de novo.

**Navegação** (comportamento nativo do Scintilla, não precisa decorar nada novo):

| Tecla | Ação |
|---|---|
| `Enter` | Aceita a opção destacada (a primeira da lista, por padrão) |
| `Tab` | Igual `Enter` |
| `↑` / `↓` / `Page Up` / `Page Down` | Navega pela lista |
| `Esc` | Cancela e fecha a lista, sem inserir nada |
| (continuar digitando) | A lista se estreita sozinha conforme mais letras batem com o que sobrou |

Liga/desliga e o mínimo de letras são configurados separadamente para BASIC e Assembly (ver
[Telas de configuração](#telas-de-configuração)):

- **`Configurar → Basic Options...`** — vale para abas `.dmx`/`.bas`.
- **`Configurar → Assembly...`** — vale para abas `.asm`.

Cada tela também tem uma opção de **caixa** (maiúsculas/minúsculas) para as palavras-chave sugeridas:

| Opção | Efeito |
|---|---|
| **Como digitado** (padrão) | Acompanha a caixa do que você já digitou — `pri` sugere `print`, `PRI` sugere `PRINT`. Se a caixa do que foi digitado for ambígua/mista (ex.: `Pri`), cai em maiúsculas. |
| **Sempre maiúsculas** | Sugestões sempre em maiúsculas, não importa como foi digitado. |
| **Sempre minúsculas** | Sugestões sempre em minúsculas, não importa como foi digitado. |

Essa opção de caixa só afeta **palavras-chave/mnemônicos** — variáveis, rótulos Assembly e os
wrappers `.NB_*` do NestorBASIC (ver abaixo) sempre aparecem exatamente com a grafia que você já usou
em algum lugar do documento, nunca reformatados.

### O que é sugerido em abas BASIC/Dignified (`.dmx`/`.bas`)

- Palavras-chave clássicas do MSX-BASIC (`PRINT`, `FOR`, `GOTO`, `INPUT`...) e funções (`LEFT$`,
  `MID$`, `ABS`...).
- Instruções exclusivas do Basic Dignified (`DEFINE`, `DECLARE`, `INCLUDE`, `FUNC`, `RET`, `EXIT`...).
- Em abas `.bas` (projeto MSXBAS2ROM), também os comandos/funções estendidos do MSXBAS2ROM
  (`CMD TURBO`, `HEAP()`, `COLLISION()` etc.) — não aparecem numa aba `.dmx` comum, pra não confundir
  com uma variável qualquer chamada `TURBO`.
- Os 87 wrappers **`.NB_*` do NestorBASIC** (`.NB_ReadByte`, `.NB_FillVram`... — mesma lista de
  `Ajuda → NestorBASIC...`), disponíveis em qualquer aba `.dmx`. Como o `.` não faz parte do que o
  Scintilla considera "palavra", basta digitar a partir do `N` (ex. `.NB_Rea` já sugere depois de
  digitar `Rea`) — o `.` que você já tinha digitado não é tocado.
- **Variáveis** — qualquer identificador que já apareça em algum lugar do documento e não seja
  palavra-chave reservada, coletado ao vivo do texto da aba (não precisa ter sido declarado com
  `DECLARE`).

### O que é sugerido em abas Assembly (`.asm`)

- Mnemônicos Z80 (`LD`, `PUSH`, `CALL`...), registradores/condições de desvio (`A`, `HL`, `NZ`...) e
  diretivas do assembler nativo desta IDE, incluindo as com ponto do dialeto N80 (`.PHASE`, `.RADIX`
  etc. — mesma observação do `.NB_*` acima: digite a partir da letra depois do ponto).
- **Rótulos** já definidos no documento (`MYLABEL:`, `.local`), pela mesma regra clássica MACRO-80/Z80
  que o destaque de sintaxe já usa: a primeira palavra de uma linha que não é mnemônico/registrador/
  diretiva conhecido é rótulo.

---

## Auto-indentação

Em abas MSX-BASIC/Dignified (`.dmx`/`.bas`), pressionar `Enter` mantém a mesma indentação da linha que
você acabou de terminar — não precisa mais pressionar `Tab` toda hora pra realinhar o código. É só
isso: a IDE copia a indentação da linha anterior e posiciona o cursor lá, sem tentar adivinhar se deve
somar ou tirar um nível sozinha (uma versão anterior tentava fazer isso depois de `FOR`/`IF`/etc., mas
gerava indentação indevida em outros casos — como pedido, foi simplificado pra só copiar, sem lógica
nenhuma de blocos).

---

## Gerenciador de disco MSX

### Menu Criar → Disco... (gerenciador gráfico)

Atalho: `Ctrl+Shift+D`.

O menu **Criar → Disco...** abre uma janela com dois painéis (estilo Norton/Total Commander) para
montar imagens de disco MSX (`.dsk`) sem sair do editor:

- **Campo "Arquivo do disco"** (topo) — o botão **"..."** abre o diálogo padrão do Windows para
  escolher um `.dsk` já existente (abre para edição) ou digitar um caminho novo (cria um disco em
  branco de 720 KB).
- **Painel esquerdo** — sistema de arquivos local, começando no diretório onde o `PaleoBasic.exe`
  está rodando. Duplo-clique numa pasta entra nela; duplo-clique em `..` sobe um nível.
- **Painel direito** — conteúdo do disco aberto/em criação.
- **`Adicionar >>` / `<< Extrair`** — transferem os arquivos selecionados (seleção múltipla suportada)
  entre os dois painéis. **Sempre por cópia** — o arquivo de origem nunca é apagado.
- **`Remover local` / `Remover disco`** — excluem de verdade os arquivos selecionados (do sistema de
  arquivos do Windows ou de dentro do disco, respectivamente), pedindo confirmação antes por serem
  ações destrutivas. `Remover disco` fica desabilitado até que um disco esteja aberto.
- **Salvar / Salvar como... / Duplicar... / Excluir disco... / Cancelar** — todas as operações acima
  acontecem numa **cópia de rascunho temporária**; o arquivo `.dsk` escolhido no topo só é gravado de
  verdade num destes botões:
  - **Salvar** — grava no arquivo escolhido e fecha a janela.
  - **Salvar como...** — pergunta um caminho novo e grava lá (a janela continua fechando ao final).
  - **Duplicar...** — grava uma cópia extra num caminho escolhido **sem** fechar a sessão — o
    trabalho continua no disco original.
  - **Excluir disco...** — apaga o arquivo `.dsk` de destino (se já existir) e reinicia a janela do
    zero, pronta para outro disco.
  - **Cancelar** (ou fechar a janela) — descarta o rascunho sem tocar no arquivo escolhido no topo.

### Linha de comando (`--diskmanipulator`)

O mesmo motor de disco também está disponível como utilitário de linha de comando, sem abrir
nenhuma janela — útil em scripts:

```powershell
PaleoBasic.exe --diskmanipulator create disco.dsk
PaleoBasic.exe --diskmanipulator list disco.dsk -l
PaleoBasic.exe --diskmanipulator add disco.dsk arquivo.bas *.txt
PaleoBasic.exe --diskmanipulator extract disco.dsk -d pasta_saida *.bas
PaleoBasic.exe --diskmanipulator delete disco.dsk arquivo.bas
```

| Comando | Descrição |
|---|---|
| `create <disco.dsk> [boot.bin]` | Cria uma imagem de disco MSX em branco (720 KB), com setor de boot customizado opcional. |
| `list <disco.dsk> [-l]` | Lista os arquivos do disco (`-l` mostra tamanho e data/hora). |
| `add <disco.dsk> <arquivo...>` | Adiciona um ou mais arquivos locais (aceita curingas como `*.BAS`). |
| `extract <disco.dsk> [-d pasta] [máscara...]` | Extrai arquivos do disco, opcionalmente filtrando por máscara. |
| `delete <disco.dsk> <arquivo>` | Remove um arquivo de dentro do disco. |

Diferente da versão gráfica, a CLI grava direto no arquivo informado (sem cópia de rascunho) — mesmo
comportamento do utilitário `msxdisk.exe` original.

---

## Sistema de projeto (arquivo `.msxproject`)

Um **projeto** MSX inteiro — os sprites do [editor de sprites](#editor-de-sprites), os alfabetos do
[editor de alfabetos](#editor-de-alfabetos), uma cópia do conteúdo das abas de texto já salvas em disco
e o diretório de trabalho (outros tipos de conteúdo — Basic, Assembly, telas, sons, músicas, listagens
LM — entram conforme ganharem editor próprio) — fica guardado num único arquivo `.msxproject` (um banco
SQLite).

### Projeto implícito "noname"

Ao abrir a IDE **sem passar nenhum parâmetro na linha de comando** (o uso normal, clicando no `.exe`),
um projeto implícito chamado **`noname.msxproject`** já é criado de cara, num arquivo temporário. Não
é preciso criar ou escolher um projeto antes de usar o editor de sprites/alfabetos — tudo que for
registrado vai sendo gravado nesse projeto automaticamente.

### Menu Projeto → Novo projeto... / Abrir projeto...

Atalhos: `Ctrl+Alt+N` (Novo projeto...) e `Ctrl+Alt+O` (Abrir projeto...).

- **Novo projeto...** — pede um caminho (diálogo padrão do Windows, escolhe pasta e nome de uma vez) e
  troca para um projeto novo e vazio nesse local. Se o projeto atual ainda for o `noname` temporário e
  já tiver conteúdo registrado, pergunta antes se você quer salvá-lo permanentemente (cancelar esse
  diálogo de salvar cancela a troca de projeto também — nada é descartado sem avisar).
- **Abrir projeto...** — mesma lógica, mas abre um arquivo `.msxproject` já existente em vez de criar
  um novo.

### Menu Projeto → Salvar projeto / Salvar projeto como...

- **Salvar projeto** — se o projeto atual já tem um caminho permanente, não faz nada visível (o
  `.msxproject` já grava cada sprite/alfabeto/documento registrado na hora, não existe estado "sujo" em
  memória à espera de um save); se ainda for o `noname` temporário, cai no mesmo fluxo do item abaixo.
- **Salvar projeto como...** — sempre pergunta um caminho novo (sugerindo o atual, se já for
  permanente) e promove/copia o projeto pra lá — é como se salva **uma cópia do projeto com outro
  nome**. Se o nome digitado não tiver extensão, `.msxproject` é acrescentada automaticamente.

### Menu Projeto → Índice de recursos...

Atalho: `Ctrl+Alt+R`. Abre uma janela com **tudo** que o `.msxproject` atual guarda, numa lista só —
pensada pra quem empacota vários programas/artigos num projeto (ex.: digitando os type-ins de uma
revista) e quer ver rápido "o que tem aqui dentro" sem precisar decorar nome de arquivo:

- **Documentos** — cada `.dmx`/`.bas`/`.asm`/`.md` já salvo pelo menos uma vez enquanto este projeto
  estava aberto (rotulados "Programa (...)" ou, no caso de `.md`, "Artigo (Markdown)").
- **Recursos numerados** — sprites, alfabetos, sons (PSG), SFX (SEE Tracker), músicas (MML), telas
  (Screen 0/1/2/1+2), Graphos III (Tela/Layout/Shape) e Assembly Sub-Projects, cada um listado como
  "Tipo — #N".
- **Discos** — qualquer `.dsk` que esteja na mesma pasta do `.msxproject` (esses não ficam guardados
  *dentro* do banco do projeto como os demais itens acima — são catalogados escaneando a pasta).

Dois cliques (ou selecionar e clicar **Abrir**) leva pro lugar certo: um documento troca pra aba dele
(abrindo do disco se ainda não estiver aberta); um disco abre o **Gerenciador de disco** já com o
arquivo escolhido no seletor; qualquer outro recurso abre o editor daquele tipo — como nenhum editor
visual ainda aceita "abrir direto no número X", pode ser preciso navegar até o número certo depois de
aberto. **Atualizar** reconsulta o projeto (útil se você registrou algo novo com a janela já aberta).

### Abrir um `.msxproject` com duplo clique

Em **Configurar → Associações de arquivo...** (ver [Associações de arquivo](#associações-de-arquivo))
dá pra ligar a associação de `.msxproject` com o Paleobasic no Windows — depois disso, dar 2 cliques
num `.msxproject` no Explorer abre esse projeto direto (equivalente a **Abrir projeto...**), sem passar
pelo projeto implícito `noname` primeiro.

### Cópia das abas de texto e diretório de trabalho

Além dos sprites e alfabetos, o projeto também guarda automaticamente:

- Uma **cópia sempre atualizada** do conteúdo de cada aba de texto (`.dmx`/`.amx`/`.asm`) já salva em
  disco pelo menos uma vez — sincronizada a cada `Ctrl+K D`/"Salvar como" de uma aba, além do arquivo
  físico que já ia para o disco. Abas ainda não salvas ("nonameN") não entram, por não terem um
  caminho ainda.
- O **diretório de trabalho** — a pasta do último arquivo salvo, ou o diretório corrente enquanto nada
  foi salvo ainda.

### Ao sair

Se o projeto atual ainda for o `noname` temporário **e** já tiver algo registrado (pelo menos um
sprite ou alfabeto), a IDE pergunta, ao fechar, se você quer salvá-lo — respondendo que sim, abre o
mesmo diálogo de "escolher pasta e nome definitivo" do **Novo projeto...**. Se não houver nada
registrado, ou se o projeto já estiver salvo num arquivo permanente, a IDE fecha direto, sem perguntar
nada.

---

## Editor de sprites

Atalho: `Ctrl+Shift+P` (Criar → Sprite...).

![Editor de sprites (Criar → Sprite...) com grade 16×16, paleta MSX1, barra de projeto (número, navegação, tag) e prévia em escala reduzida](../images/msxbasica-04.png)

O menu **Criar → Sprite...** abre o editor gráfico de sprites MSX, numa janela própria.

### Grade, tamanho e modo de cor

- **Tipo de sprite** — radio **8×8** / **16×16**, os dois tamanhos reais de sprite do VDP do MSX. A
  área de desenho (canvas) tem sempre o mesmo tamanho em pixels; é o tamanho de cada bloco que muda ao
  trocar entre os dois.
- **Modo** — radio **MSX1** / **MSX2**, controla a regra de cor do hardware real:
  - **MSX1**: o sprite inteiro só pode ter **uma cor**. Trocar a cor atual (ou pintar) recolore
    instantaneamente tudo que já estava pintado.
  - **MSX2**: **cada linha** pode ter a sua própria cor (recurso real do VDP do MSX2), mas só uma cor
    dentro da mesma linha — pintar um bloco numa linha recolore automaticamente o resto da linha para
    bater com a cor usada.
- **Cor atual** — seletor com as 16 cores fixas da palheta original do MSX1 (TMS9918); o primeiro
  quadro (com um "X") é o índice 0, transparente.
- **Prévia** — canto da janela mostra o sprite em escala reduzida, mais perto do tamanho real (sem as
  linhas de grade da área de edição).

### Ferramentas de desenho

Barra de ícones logo abaixo da grade — só uma ferramenta fica ativa por vez:

| Ícone | Ferramenta | Como usar |
|---|---|---|
| Lápis | Pinta um bloco por vez | Clique, ou arraste com o botão esquerdo pressionado para riscar continuamente. |
| Borracha | Apaga um bloco por vez | Mesmo gesto do lápis, mas apagando. |
| Pincel | Pinta um bloco 2×2 por vez | Mesmo gesto do lápis, "mais grosso". |
| Balde | Preenche uma área conectada | Clique dentro de uma região fechada — pinta tudo que estiver conectado com a mesma cor. |
| Reta | Traça uma linha reta | Marque o ponto inicial (fica piscando) e o final — veja abaixo. |
| Retângulo (vazio/cheio) | Desenha um retângulo | Marque dois cantos opostos. |
| Elipse/círculo (vazio/cheio) | Desenha uma elipse | Marque dois cantos da caixa delimitadora. |

**Ferramentas de dois pontos** (reta, retângulo, elipse): o primeiro clique marca o ponto inicial — um
marcador fica **piscando** nele — e, conforme o mouse se move, a forma que seria traçada aparece **em
prévia** sobre a grade. O segundo clique confirma. Para **cancelar sem traçar nada**, aperte **Esc**
ou clique com o **botão direito** do mouse.

Abaixo das ferramentas de desenho:

- **Rotacionar** (com "quebra" nas bordas — o que sai de um lado reaparece do outro) e **Deslocar**
  (sem quebra — o que sai se perde, o espaço liberado vira transparente), nas quatro direções.
- **Inverter** todos os pontos, **Limpar** tudo.

### Barra de projeto (registrar, navegar, copiar/colar)

Barra no topo da janela, ligada ao [sistema de projeto](#sistema-de-projeto-arquivo-msxproject):

- **Número do sprite** — mostrado como `#N`; cada sprite registrado tem um número sequencial.
- **Tag** — nome curto (até 16 caracteres) para identificar o sprite.
- **Navegação** — botões **Primeiro** / **Anterior** / **Próximo** / **Último**, andam entre os
  sprites já registrados no projeto atual (param nas pontas, não dão volta).
- **Novo** — cria o próximo sprite da sequência (maior número já registrado + 1), com a grade em
  branco.
- **Registrar** — grava (ou atualiza, se já existir) o sprite atual no projeto.
- **Copiar** / **Colar** — copiam o sprite atual (grade, tamanho e modo) para colar em outro número —
  útil para duplicar um sprite parecido antes de fazer variações.

Alterações feitas num sprite e ainda não registradas pedem confirmação antes de trocar de sprite ou
fechar a janela, para não perder trabalho sem querer.

---

## Editor de alfabetos

Atalho: `Ctrl+Shift+A` (Criar → Alfabeto Graphos III...).

O menu **Criar → Alfabeto...** abre o editor de charsets (fontes de caracteres 8×8) MSX, no formato
de arquivo **`.ALF` do [Graphos III](https://www.msx.org/wiki/Graphos)**, numa janela própria.

Todos os botões de ação da janela são **ícones monocromáticos** (sem texto) — passe o mouse por cima
para ver uma dica explicando a função exata. Vários botões de escopo diferente reaproveitam o mesmo
desenho (ex.: o ícone de "copiar" é o mesmo para copiar um caractere, um alfabeto inteiro ou um bloco)
— a posição na janela e a dica ao passar o mouse é que indicam o escopo. Nas seções abaixo, os nomes em
**negrito** correspondem ao texto da dica de cada ícone, não a um rótulo visível no botão.

### Tabela de caracteres e grade de edição

- **Tabela** — os 256 caracteres do alfabeto (16 colunas × 16 linhas), cada um mostrado como uma
  miniatura do seu desenho 8×8 atual. O cabeçalho de linha/coluna é hexadecimal — a própria posição na
  grade já é o código do caractere (linha = byte alto, coluna = nibble baixo), como um mapa de
  caracteres clássico. Clicar num caractere carrega o desenho dele na grade grande à direita; o
  selecionado ganha um contorno vermelho.
- **Grade de edição** — versão bem ampliada (8×8 quadrados grandes) do caractere selecionado. Clique
  liga/desliga um pixel; arrastar com o botão esquerdo pressionado pinta uma sequência de pixels com o
  mesmo valor do primeiro clique (não fica alternando a cada pixel passado por cima). Os 8 bytes
  hexadecimais resultantes aparecem ao lado, atualizados a cada pixel alterado.
- **Registrar** — grava os pixels editados de volta nos 8 bytes do caractere selecionado (e atualiza a
  miniatura dele na tabela). **Editar sem clicar em "Registrar" não muda o alfabeto** — trocar de
  caractere ou fechar a janela com edições pendentes pede confirmação.
- **Limpar** — apaga todos os pixels da grade de edição (ainda precisa de "Registrar" para valer).
- **Copiar** / **Colar** (caractere) — copiam o caractere em edição para uma área de transferência da
  sessão (dura enquanto a janela estiver aberta) e colam de volta em qualquer outro caractere, do mesmo
  alfabeto ou de um alfabeto diferente (navegue para outro alfabeto e o valor copiado continua
  disponível). Colar substitui a grade de edição — ainda precisa de "Registrar" para valer no alfabeto.
- **Inverter** — com **nenhum bloco marcado** (ver abaixo), inverte só os pixels da grade de edição do
  caractere atual (ainda precisa de "Registrar"). Com um **bloco marcado**, inverte de uma vez **todos
  os caracteres do intervalo**, direto no alfabeto em memória (não passa pela grade de edição nem
  precisa de "Registrar" por caractere — mas o alfabeto inteiro ainda precisa de "Registrar alfabeto"
  para valer no projeto). Os efeitos de glifo descritos mais abaixo seguem exatamente o mesmo padrão.

### Marcar bloco (aplicar um efeito num intervalo de caracteres de uma vez)

Abaixo da tabela: **Marcar início** / **Marcar fim** marcam o caractere atualmente selecionado na
tabela como início/fim de um intervalo (por exemplo, clique em "A", **Marcar início**, clique em "Z",
**Marcar fim**). O botão **All** faz a mesma coisa de uma vez só, marcando o alfabeto inteiro (todos os
256 caracteres) sem precisar clicar duas vezes. O intervalo marcado aparece com um contorno azul na
tabela, e o texto de status mostra algo como `Bloco: $41..$5A (26 caracteres)`. Com o intervalo
marcado, **todos os botões de efeito** (Inverter, Espelhar, Girar, Apagar, Estreitar, Itálico, Negrito,
Largo e variantes — ver [Efeitos de glifo](#efeitos-de-glifo-espelhar-girar-estreitar-itálico-negrito-largo)
abaixo) passam a aplicar de uma vez em todos os caracteres do intervalo, em vez de só no caractere
atual. **Limpar bloco** desmarca o intervalo, voltando todos os efeitos ao comportamento normal (só o
caractere atual). O intervalo marcado é independente do alfabeto sendo editado no momento — navegar
entre alfabetos não desmarca o bloco, então dá para repetir o mesmo efeito em vários alfabetos sem
remarcar.

- **Copiar bloco** — copia todos os caracteres do intervalo marcado (não só um) para a área de
  transferência da sessão. Precisa de um intervalo marcado primeiro (Marcar início/Marcar fim).
- **Colar bloco** — cola o intervalo copiado a partir do **caractere atualmente selecionado** na
  tabela (o destino), substituindo tantos caracteres quantos foram copiados. Depois de colar, o
  intervalo de destino vira automaticamente o novo bloco marcado — dá pra clicar **Inverter** na
  sequência sem precisar remarcar. Exemplo do fluxo completo: marcar A..Z, **Copiar bloco**, clicar no
  caractere "a" na tabela, **Colar bloco** (a..z passam a ter os mesmos desenhos de A..Z, e o intervalo
  a..z já fica marcado), **Inverter** (inverte só a..z) — resultado: A..Z normais e a..z como a mesma
  fonte invertida, prontos para usar como dois conjuntos diferentes no mesmo alfabeto.

### Desfazer / refazer

**Desfazer** / **Refazer** trabalham sobre o **alfabeto inteiro**, não sobre pixel individual — cada
vez que uma alteração é de fato gravada no alfabeto (Registrar um caractere, qualquer efeito de glifo
aplicado com um bloco/All marcado, Colar bloco, Colar alfabeto), o estado anterior é guardado numa
pilha (até 50 níveis). **Desfazer** volta pro estado anterior; **Refazer** avança de novo, se nada foi
alterado no meio. Pixels ainda não registrados (sem clicar em "Registrar") não entram na pilha — a
mesma regra de sempre: editar sem registrar não muda o alfabeto, então não há o que desfazer ali. Os
botões ficam desabilitados quando não há nada pra desfazer/refazer, e a pilha é zerada ao trocar de
alfabeto (navegar, Novo alfabeto, Carregar do Graphos III) — desfazer não atravessa alfabetos
diferentes.

### Efeitos de glifo (espelhar, girar, estreitar, itálico, negrito, largo)

Uma segunda fileira de botões, ao lado de Registrar/Limpar/Inverter/Copiar/Colar, com mais efeitos que
seguem o **mesmo padrão dual** do Inverter: sem bloco marcado, afetam só o caractere em edição (ainda
precisa de "Registrar"); com um bloco marcado (ou **All**), aplicam de uma vez em todo o intervalo,
direto no alfabeto.

- **Espelhar horizontal** / **Espelhar vertical** — espelham o desenho do glifo na horizontal/vertical.
- **Girar 90°** — gira o glifo 90 graus no sentido horário.
- **Apagar** — mesmo efeito de "Limpar", só que também funciona com bloco/All marcado (apagando todos
  os caracteres do intervalo de uma vez).
- **Estreitar** — condensa as 5 colunas da metade esquerda do glifo em só 3 colunas (colunas 0-1 viram
  a coluna 0, a coluna 2 vira a coluna 1, as colunas 3-4 viram a coluna 2; o resto some) — truque
  clássico de fonte MSX pra caber **64 colunas** de texto na tela onde caberiam só 32.
- **Itálico** — desloca as linhas do glifo pra direita em quantidades decrescentes: as 2 linhas de
  cima deslocam 2 pixels, as 3 seguintes deslocam 1 pixel, e as 3 últimas ficam paradas — resultado é
  um efeito de inclinação.
- **Negrito** — engrossa cada traço vertical em 1 pixel, combinando cada linha do glifo com uma cópia
  dela mesma deslocada 1 pixel pra direita.
- **Largo** — estica o glifo horizontalmente em 1 pixel, combinando a metade esquerda original com uma
  cópia deslocada 1 pixel pra direita.
- **Bold (esquerda)** / **Bold (direita)** — parecidos com "Largo", mas engrossando um lado específico
  do glifo em vez de só esticar (esquerda engrossa o lado esquerdo, direita o lado direito).
- **Largo (bold)** — aplica "Largo" e, em seguida, "Negrito" em cima do resultado — glifo esticado e
  engrossado ao mesmo tempo.

### Copiar/colar um alfabeto inteiro

Acima da tabela: **Copiar alfabeto** / **Colar alfabeto** copiam os 256 caracteres do alfabeto em
edição para uma área de transferência da sessão e colam de volta em outro alfabeto (por exemplo,
"Novo alfabeto" seguido de "Colar alfabeto" duplica um alfabeto inteiro para um número novo). "Copiar
alfabeto" aplica antes qualquer pixel pendente do caractere selecionado, para não deixar nada de fora;
"Colar alfabeto" substitui o alfabeto inteiro em edição — ainda precisa de "Registrar alfabeto" para
valer no projeto.

### Arquivo .ALF (Graphos III)

- **Carregar do Graphos III...** — lê um arquivo `.alf` de verdade, no formato binário clássico do
  MSX: um cabeçalho de 7 bytes (byte de tipo `&HFE`, endereços inicial/final/execução, 2 bytes cada)
  seguido dos 2048 bytes de dados (256 caracteres × 8 bytes) — originalmente carregado no endereço de
  VRAM `&H9200`, a Pattern Generator Table. Um cabeçalho com byte de tipo ou tamanho inválido é
  rejeitado com mensagem de erro, em vez de carregar dados sem sentido silenciosamente. O alfabeto
  importado sempre vira um **alfabeto novo** no projeto (numeração automática, igual a "Novo
  alfabeto") — nunca sobrescreve um banco já registrado sem querer. Depois de carregar, use **Registrar
  alfabeto** (barra de projeto abaixo) pra gravá-lo de fato no `.msxproject`; assim dá pra ter vários
  alfabetos Graphos III diferentes no mesmo projeto.
- **Salvar como...** — grava o alfabeto em edição num arquivo `.alf` de verdade, no mesmo formato. Se o
  nome digitado não tiver extensão, `.alf` é acrescentada automaticamente. Independente do sistema de
  projeto abaixo — serve pra exportar um `.alf` compatível com o Graphos III de verdade, não pra
  guardar o alfabeto no `.msxproject`.

### Barra de projeto e o alfabeto padrão ("projeto 0")

Barra no topo da janela, ligada ao [sistema de projeto](#sistema-de-projeto-arquivo-msxproject) — mesmo
padrão da barra de projeto do editor de sprites:

- **Número do alfabeto** — mostrado como `#N`; cada alfabeto registrado tem um número sequencial.
- **Tag** — nome curto (até 16 caracteres) para identificar o alfabeto.
- **Navegação** — botões **Primeiro** / **Anterior** / **Próximo** / **Último**, andam entre os
  alfabetos já registrados no projeto atual (param nas pontas, não dão volta).
- **Novo alfabeto** — cria o próximo alfabeto da sequência (maior número já registrado + 1), **sempre
  partindo do charset padrão do MSX** (nunca em branco — diferente do "Novo" do editor de sprites).
- **Registrar alfabeto** — grava (ou atualiza, se já existir) o alfabeto inteiro (os 256 caracteres) no
  projeto. Também aplica antes qualquer edição pendente do caractere que estiver selecionado, para não
  deixar pixels não registrados de fora.

O **charset padrão do MSX** usado como ponto de partida (ao abrir a janela sem nenhum alfabeto ainda
registrado no projeto, e sempre em "Novo alfabeto") vem de um **alfabeto embutido no próprio
executável** — não depende de nenhum arquivo externo em tempo de execução. Internamente ele mora num
**"projeto 0"**: um banco de dados separado, sempre em memória, nunca salvo em disco, recriado do zero
a cada vez que a IDE é aberta — só serve como fonte interna de conteúdo padrão.

---

## Editor de som (PSG)

Atalho: `Ctrl+Shift+G` (Criar → Som (PSG)...).

![Editor de som PSG (Criar → Som (PSG)...) com os 3 canais, ruído/envelope compartilhados, lista de passos e código BASIC gerado](../images/msxbasica-06.png)

O menu **Criar → Som (PSG)...** abre o editor de efeitos sonoros para o chip de som do MSX
(AY-3-8910/YM2149), numa janela própria. Ele espelha, registrador por registrador, exatamente o que o
comando `SOUND` do MSX-BASIC escreve no chip — o que você ouve na janela é sintetizado pelo mesmo
motor de emulação que gera o código, então o resultado real no MSX/openMSX deve soar muito parecido.

Um **som** é um **mini-sequenciador de passos**: uma lista curta onde cada passo guarda os 14
registradores do PSG (tom, ruído, volume, envelope) mais uma duração em quadros — é o time-line de UM
efeito/instrumento (tiro, explosão, bipe etc.), sem os recursos de loop/eventos de um tracker de
verdade (para isso, ver o **Editor SEE Tracker** logo abaixo).

### Canais A/B/C, ruído e envelope

- **Canal A / B / C** — cada um com **Frequência (Hz)** (convertida automaticamente para o período de
  registrador do PSG), **Volume (0-15)**, **Usar envelope** (ignora o campo Volume e usa o gerador de
  envelope compartilhado abaixo) e dois interruptores de mixer: **Tom** (oscilador de onda quadrada) e
  **Ruído** (gerador de ruído, compartilhado pelos 3 canais).
- **Ruído (compartilhado)** — **Período (0-31)**: quanto menor, mais agudo o ruído.
- **Envelope (compartilhado)** — **Período** (1 a 65535) e a **forma** (lista com as 10 formas de
  hardware do chip, cada uma com uma descrição curta — ex. "9 - decai e para", "12 - sobe repetindo").
  Só afeta os canais com **Usar envelope** marcado.

Todos esses campos são digitáveis diretamente (não são controles de "setinha") — digite o valor e
troque de campo ou clique em **Adicionar passo**/**Atualizar passo** para aplicar.

### Sequência de passos

- **Adicionar passo** — acrescenta um novo passo ao fim da sequência, com os valores atuais do painel.
- **Atualizar passo** — aplica os valores atuais do painel ao passo selecionado na lista.
- **Remover** — apaga o passo selecionado.
- **▲** / **▼** — move o passo selecionado para cima/baixo na sequência.
- **Duplicar passo** — insere uma cópia do passo selecionado logo depois dele.

Clicar num passo da lista carrega os valores dele de volta no painel para edição. A lista mostra um
resumo de cada passo (ex. `A=440Hz v12  10q`) — só os canais que realmente produzem som (tom ligado e
volume maior que zero, ou usando envelope) aparecem no resumo.

### Tocar / Parar

**Tocar** sintetiza a sequência inteira em áudio PCM — motor próprio por acumulador de fase (osciladores
de tom dos 3 canais, LFSR de ruído de 17 bits, gerador de envelope com tabela de volume logarítmica de
16 níveis, mesmo clock do PSG do MSX) — e toca via um arquivo `.wav` temporário, sem depender de
nenhuma biblioteca de áudio externa. **Parar** interrompe a reprodução. Cada clique em Tocar renderiza
de novo do zero, então qualquer alteração no painel ou na lista de passos já sai atualizada na próxima
reprodução.

### Gerar código e injetar no editor

- **Gerar código BASIC** — produz linhas `SOUND n,valor` prontas para colar: o primeiro passo escreve
  os 14 registradores, os passos seguintes só escrevem os registradores que **mudaram** em relação ao
  anterior (um registrador não tocado mantém o valor de antes no hardware real). Entre passos, uma
  espera aproximada via `FOR/NEXT` (a constante de calibração é aproximada, não sample-accurate contra
  hardware real — ajuste conforme necessário).
- **Gerar bytes crus** — produz um bloco `DATA` com os 14 bytes de registrador mais a duração de cada
  passo, pensado para uma futura rotina Z80 que escreva direto nas portas do PSG (mais rápido que várias
  chamadas `SOUND` em runtime).
- **Injetar no cursor** — insere o código gerado (mostrado na caixa de texto abaixo dos botões) direto
  no cursor da aba de texto ativa no editor.
- **Copiar** — copia o código gerado para a área de transferência do Windows.

### Barra de projeto

Barra no topo da janela, ligada ao [sistema de projeto](#sistema-de-projeto-arquivo-msxproject) — mesmo
padrão da barra de projeto dos editores de sprite e alfabeto:

- **Número do som** — mostrado como `#N`; cada som registrado tem um número sequencial.
- **Tag** — nome curto (até 16 caracteres) para identificar o som.
- **Navegação** — botões **Primeiro** / **Anterior** / **Próximo** / **Último**, andam entre os sons já
  registrados no projeto atual (param nas pontas, não dão volta).
- **Novo** — cria o próximo som da sequência (maior número já registrado + 1), com a lista de passos
  vazia.
- **Registrar** — grava (ou atualiza, se já existir) o som atual — todos os passos da sequência — no
  projeto.

Alterações feitas num som e ainda não registradas pedem confirmação antes de trocar de som ou fechar a
janela, para não perder trabalho sem querer.

---

## Editor SEE Tracker

Atalho: `Ctrl+Shift+T` (Criar → SEE Tracker...).

![Editor SEE Tracker (Criar → SEE Tracker...) com um efeito de 8 patterns tocando — cursor de playback verde no pattern 0, botões Limpar/Limpar linha/Limpar bloco e o seletor visual de forma do envelope à direita](../images/msxbasica-16.png)

O menu **Criar → SEE Tracker...** abre um tracker de efeitos sonoros **compatível com o formato .SEE**
(Sound Effect Editor, Fuzzy Logic 1991/95 — ver **Ajuda → SEE Tracker...** para o manual original e o
formato de arquivo). Diferente do editor de Som (PSG) acima, um efeito aqui é uma sequência de
**patterns com comandos de controle** (espera, loop, retomada) — o mesmo modelo do SEE original, gerando
um **driver de replay Z80 nativo** desta IDE junto com os dados, pronto pra tocar via NestorBASIC. Um
**cursor de playback** mostra em tempo real qual pattern está tocando (ver **Tocar/Parar** abaixo), e a
**forma do envelope** do PSG pode ser escolhida visualmente numa grade com as 16 curvas reais do chip
(ver o campo **Forma** logo abaixo).

### A grade e o painel de edição

A grade à esquerda mostra uma linha por **pattern** (numerados a partir de 0), com uma prévia compacta
de cada canal nas colunas: `Evt` (evento), `Snd1-3` (frequência dos 3 canais de som, com `^`/`v` se
houver slide de afinação), `R1-3` (`R` = este canal usa o ruído compartilhado, `-` = não usa), `V1-3`
(volume, com `W` se usa o envelope de hardware), `Wv`/`Time` (forma/período do envelope). Clicar numa
linha seleciona aquele pattern para edição completa no painel à direita. As cores da grade seguem o
tema do editor (**Configurar → Editor...**) — fundo claro no tema Light, fundo escuro (mas não preto) com
letras claras no tema Dark, pra manter boa legibilidade nos dois casos:

- **Evento** — combo com os 7 comandos do formato (`HALT`/`FOR`/`NEXT`/`START`/`RERUN`/`TMP`) mais
  `-- (nada)`/`END`, e um campo **Valor** (0-15: quadros do `HALT`, repetições do `FOR`, ou o `TMP`).
- **Freq 1/2/3** — frequência PSG (0-4095) de cada canal, com checkboxes **Som** (liga o oscilador de
  tom), **Rustle** (este canal usa o ruído compartilhado) e **Up**/**Down** (slide de afinação, relativo
  ao valor real do pattern anterior — não ao valor absoluto digitado aqui). Digitar uma frequência ou
  volume diferente de zero **liga "Som" sozinho** se ainda estiver desmarcado (nunca desliga sozinho,
  só desmarcando à mão) — sem isso, seria fácil digitar um valor e não ouvir nada por esquecer desse
  passo extra, diferente do editor SEE original (lá, digitar um valor já liga o canal).
- **Rustle** — período de ruído compartilhado (0-31, só ouvido nos canais com **Rustle** marcado) mais
  **Up**/**Down**.
- **Vol 1/2/3** — volume (0-15) de cada canal, com **Wave** (usa o envelope de hardware do PSG em vez de
  volume fixo — quando marcado, os slides deste canal são ignorados, o hardware manda sozinho) e
  **Up**/**Down**.
- **Período do envelope** / **Forma** — regs. 11/12 (0-65535) e reg. 13 (0-15) do envelope de hardware do
  PSG, usados pelos canais de volume com **Wave** marcado. Ao lado do campo **Forma** fica um preview
  compacto com a curva da forma atual, atualizado a cada seleção/edição; o botão **...** abre uma janela
  com as **16 formas reais do PSG** numa grade (rótulo hex 0-F + a curva de cada uma) — clicar numa
  já escolhe e fecha, mais fácil que decorar o número de cada forma de cabeça.

Mudar qualquer campo aplica na hora (sem botão "Aplicar" separado, mesmo padrão do resto da IDE).

### Patterns: inserir, apagar, mover, copiar

- **Inserir pattern** / **Apagar pattern** — insere um pattern em branco depois do selecionado (ou
  **antes**, se o selecionado tiver evento `END` — um pattern novo depois de um `END` nunca seria
  alcançado, já que o playback sempre começa no pattern 0), ou apaga o selecionado (sempre sobra pelo
  menos 1). Um SFX novo já começa com 2 patterns (um em branco, editável na hora, e um `END` depois
  dele) — nunca só 1 pattern `END`, pelo mesmo motivo.
- **Mover p/ cima** / **Mover p/ baixo** — troca o pattern selecionado de posição com o vizinho.
- **Copiar pattern** / **Colar pattern** — copia os 15 bytes do pattern atual para uma área de
  transferência interna; colar substitui o pattern selecionado por essa cópia (um pattern de cada vez —
  copiar/colar um **intervalo** fica para uma versão futura).
- **Limpar** — apaga **todos** os patterns deste SFX, voltando ao estado inicial (1 pattern em branco +
  `END`) — mantém o número/tag do SFX (diferente de **Novo**, que também zera mas troca pra um número de
  SFX novo). Pede confirmação se houver alterações não registradas.
- **Limpar linha** — zera os 15 bytes do pattern **selecionado**, sem remover a linha nem afetar a ordem
  dos outros patterns (diferente de **Apagar pattern**, que remove a linha de vez e desloca os de baixo
  pra cima).
- **Limpar bloco** — abre uma janelinha pedindo um intervalo (**De**/**Até**, pré-preenchido com o
  pattern selecionado nos dois campos — clicar **Limpar** sem editar equivale a limpar 1 linha só) e zera
  todos os patterns daquele intervalo, também sem remover nenhuma linha. Útil pra apagar um trecho
  inteiro de um efeito de uma vez sem contar clique por clique.

### Tocar / Parar

**Tocar** interpreta a sequência inteira de patterns — inclusive `HALT`/`FOR`/`NEXT`/`START`/`RERUN` —
exatamente como o driver de replay real processaria quadro a quadro, e sintetiza o resultado com o
mesmo motor do editor de Som (PSG) acima. Um efeito com `RERUN` (loop sem fim, a parte "sustain" de um
efeito) é tocado até um teto de segurança (~60s) para não travar a prévia — o código **gerado** continua
fiel ao original (o `RERUN` real só para quando outro código cortar o som). Volume mestre (`Max Volume`
do SEE original) não é aplicado na prévia (sempre toca no volume cheio); o código gerado aplica a escala
de verdade no hardware real.

Enquanto toca, um **cursor de playback** (borda verde + faixa na lateral esquerda da linha, distinto do
realce amarelo/dourado de "pattern selecionado") mostra em tempo real **qual pattern está soando naquele
instante** — útil pra acompanhar visualmente `HALT`s longos, loops de `FOR`/`NEXT` reaplicando o mesmo
pattern várias vezes, ou pra confirmar que um `RERUN` está realmente ficando "preso" no trecho esperado.
A grade rola sozinha se o cursor sair da área visível (efeitos com mais de 18 patterns). O cursor some
sozinho quando a reprodução termina (naturalmente ou por **Parar**).

### Gerar código, Injetar no cursor, Copiar

**Gerar código** monta duas coisas e produz um listing BASIC pronto:

1. O **driver de replay** (Z80 nativo desta IDE, montado na hora pelo assembler embutido) como
   `DATA`+`POKE` carregando em `&HC000`.
2. Os **dados do SFX atual**, já no formato binário `.SEE` real (cabeçalho + tabela de posições +
   patterns), como `DATA`+`POKE` carregando em `&H8000`.

Mais as linhas `DEFUSR`/`USR()` prontas para ligar o driver, tocar o SFX, cortar o som e desligar o
driver — endereços já calculados para o SFX/tela atual. **Injetar no cursor** insere esse listing na aba
de texto ativa; **Copiar** copia para a área de transferência.

### Importar .SEE...

Lê um arquivo `.SEE` de verdade, gerado pelo editor **SEE original** (não um arquivo criado por esta
IDE) — útil pra recuperar efeitos sonoros de projetos antigos. Um arquivo `.SEE` pode conter **vários**
efeitos; depois de escolher o arquivo, uma janela lista todos os SFX que ele define (número + pattern
inicial) — dê duplo-clique ou selecione e confirme em **Importar** para trazer os patterns daquele SFX
pros patterns do SFX atualmente aberto (substituindo o conteúdo dele — pede confirmação se houver
alterações não registradas). A extração segue os patterns sequencialmente a partir do início do efeito
escolhido até encontrar o evento `END` (mesmo jeito que todo exemplo do manual original organiza um
efeito). Se o arquivo escolhido não começar com a identificação `SEE3`, ou não tiver nenhum SFX definido,
a IDE avisa e não importa nada.

### Barra de projeto

Mesmo padrão dos demais editores ([sistema de projeto](#sistema-de-projeto-arquivo-msxproject)): número
do SFX (`#N`), navegação Primeiro/Anterior/Próximo/Último, campo **Tag**, **Novo** (próximo número,
começa com 1 pattern `END`) e **Registrar** (grava o SFX atual, com todos os patterns, no projeto).
Alterações não registradas pedem confirmação antes de trocar de SFX ou fechar a janela.

---

## Editor de música (MML/PLAY)

Atalho: `Ctrl+Shift+M` (Criar → Música (PLAY)...).

![Editor de música MML (Criar → Música (PLAY)...) com os 3 canais em paralelo, lista de linhas por canal e código PLAY gerado](../images/msxbasica-07.png)

O menu **Criar → Música (PLAY)...** abre o editor de MML (Music Macro Language) para o comando `PLAY`
do MSX-BASIC, numa janela própria com os **3 canais A/B/C lado a lado, em paralelo**. `PLAY` toca até 3
vozes simultâneas, cada uma controlada por uma string MML própria — o motor de áudio deste editor
reaproveita quase por completo o motor do [editor de som](#editor-de-som-psg) (mesmo chip PSG, mesmo
gerador de envelope compartilhado pelos 3 canais), então o que você ouve na prévia deve soar muito
parecido com o `PLAY` real rodando no MSX/openMSX.

### Montando uma linha

Cada canal tem uma **linha atual** (campo de texto editável — os botões abaixo acrescentam nela, mas
também dá pra digitar direto):

- **Notas** — botões `C D E F G A B` e **`R`** (pausa) na mesma fileira. O **acidente** (Natural/
  Sustenido/Bemol), a **duração** (campo `D`, vazio = usa a duração padrão `L`) e os **pontos de
  aumento** (campo `.`, 0-3 — cada ponto multiplica a duração por 1,5×) ficam ao lado e valem para a
  **próxima** nota ou pausa clicada.
- **`N`** — nota absoluta por número (1-96, cromática, cobre as 8 oitavas de uma vez). Campo + botão
  `+` insere.
- **`O`** — define a oitava atual (1-8). Campo + botão `+` define; botões **`>`**/**`<`** sobem/descem
  1 oitava direto, sem precisar digitar.
- **`L`** — duração padrão (1-64) das notas/pausas que não têm duração explícita.
- **`T`** — andamento em BPM (32-255).
- **`V`** — volume do canal (0-15) — volta ao modo de volume fixo (desliga o envelope neste canal).
- **`M`** / **`S`** — período e forma do envelope de hardware (mesmos registradores do editor de som);
  escrever `S` liga o modo envelope neste canal e retrigga o gerador (só existe **um** gerador de
  envelope, compartilhado pelos 3 canais — mesma limitação do hardware real).

Todos os campos parametrizados (N, O, L, T, V, M, S) têm um botão **`+`** compacto ao lado — o rótulo
de uma letra já diz o comando MML, o `+` só confirma "acrescenta na linha atual".

- **Limpar linha** — apaga a linha atual (recomeça do zero).
- **Inserir nova linha** — fecha a linha atual como uma nova entrada na lista do canal (abaixo) e limpa
  o campo pra começar a próxima.
- **Atualizar** — aplica a linha atual sobre a linha selecionada na lista (em vez de criar uma nova).

### Lista de linhas por canal

Cada canal tem sua própria lista — clicar numa linha carrega o texto dela de volta no campo pra
edição. **`-`** remove a linha selecionada; **▲**/**▼** movem a linha selecionada pra cima/baixo.

### Tocar / Parar

**Tocar** sintetiza os **3 canais juntos** (as linhas já inseridas mais a linha em edição de cada
canal, permitindo ouvir uma prévia antes de "Inserir nova linha") e toca via `.wav` temporário, sem
depender de biblioteca de áudio externa. **Parar** interrompe a reprodução.

### Gerar código e injetar no editor

- **Gerar código PLAY** — concatena o texto MML de cada canal (sem separador — cada linha já é um
  trecho válido por si só) no comando final `PLAY "...","...","..."`, omitindo canais vazios à direita
  (ex.: só os canais A e B usados gera `PLAY "...","..."`, sem a terceira string).
- **Injetar no cursor** — insere o código gerado direto no cursor da aba de texto ativa no editor.
- **Copiar** — copia o código gerado para a área de transferência do Windows.

### Barra de projeto

Mesmo padrão de barra de projeto dos demais editores (som, sprite, alfabeto) — número da música (`#N`),
tag, navegação **Primeiro**/**Anterior**/**Próximo**/**Último**, e os botões de ícone **Novo** (cria a
próxima música da sequência, com os 3 canais vazios) e **Registrar** (grava a música atual — todas as
linhas dos 3 canais — no projeto). Alterações ainda não registradas pedem confirmação antes de trocar
de música ou fechar a janela.

---

## Editor de alfabetos Aquarela

O menu **Criar → Alfabeto Aquarela...** abre um segundo editor de charset, para o formato `.FNT` de
outro editor de fonte MSX chamado **Aquarela** (alternativa ao Graphos III do [editor de
alfabetos](#editor-de-alfabetos) acima). O formato foi descoberto por engenharia reversa (documentado
em detalhe em `docs/reference/aquarela.md`) — não há especificação oficial disponível.

Ao contrário do editor de alfabetos Graphos III, este é uma ferramenta **independente do sistema de
projeto**: não existe "Registrar alfabeto" nem número/tag — o fluxo é sempre **Novo**/**Abrir...**/
**Salvar**/**Salvar como...** direto num arquivo `.fnt`, como um editor de imagem comum.

### Tabela de 46 caracteres e grade 16x16

- **Tabela** — 46 caracteres editáveis (grade de 8 colunas × 6 linhas — as 2 últimas células ficam sem
  uso), na ordem `A-Z`, `&`, `?`, `!`, `"`, `0-9`, `.`, `:`, `-`, `(`, `)`, `,`. Essa é a única faixa da
  tabela de caracteres do Aquarela confirmada por teste real contra o programa de verdade rodando num
  emulador — o Aquarela suporta mais caracteres além destes (minúsculas, por exemplo), mas a posição
  exata deles na tabela ainda não foi confirmada, então não são editáveis aqui.
- **Grade de edição** — diferente do editor Graphos III (8×8), aqui o glifo é **16×16 de verdade**: a
  grade de edição sempre mostra as 16 colunas inteiras, mesmo para os glifos "8×8" do Aquarela (a
  maioria das fontes reais) que só desenham na metade esquerda.
- **Registrar** / **Limpar** / **Inverter** / **Copiar** / **Colar** — mesmo comportamento e mesmos
  ícones do editor de alfabetos Graphos III (ver [Tabela de caracteres e grade de
  edição](#tabela-de-caracteres-e-grade-de-edição) acima) — sem os efeitos de bloco/All/desfazer do
  Graphos III, que existem só naquele editor.

### Arquivo .FNT

- **Novo** — começa um alfabeto Aquarela em branco (os 46 caracteres editáveis).
- **Abrir...** — carrega um `.fnt` real do Aquarela (lê só os primeiros 46 caracteres — o restante do
  arquivo, se houver, é ignorado).
- **Salvar** / **Salvar como...** — grava sempre no formato de 2304 bytes (72 registros), a variante
  confirmada carregando sem erro no Aquarela de verdade contra todo o corpus de amostras testado; os
  registros além dos 46 editáveis são preenchidos com o byte de posição-vazia padrão do formato.

## Editor de DRAW Screen 2

Atalho: `Ctrl+Shift+2` (Criar → Draw Screen 2...).

O menu **Criar → Draw Screen 2...** abre um editor gráfico WYSIWYG para o modo **SCREEN 2** do MSX
(256×192 pixels), com os comandos `PSET`, `PRESET`, `LINE`, `CIRCLE`, `PAINT`, `DRAW` e texto usando um
alfabeto do banco do projeto. A tela simula o **color clash** de verdade: cada faixa de 8×1 pixels (uma
scanline de uma célula de caractere) só pode mostrar 2 cores — se você desenhar 2 cores diferentes na
mesma faixa, a faixa inteira passa a mostrar a última cor gravada, exatamente como no hardware real
(TMS9918). Isso é intencional: o objetivo do editor é justamente deixar visível, enquanto você desenha,
onde o clash vai acontecer no MSX de verdade.

![Editor de DRAW Screen 2 com formas desenhadas (círculos, linhas, retângulos, pontos e um DRAW), lista de comandos à esquerda e código BASIC gerado à direita](../images/msxbasica-10.png)

### Canvas, paleta e cor de tinta/fundo

- O **canvas** (lado esquerdo) mostra a tela 256×192 ampliada 2× para facilitar o clique. Clicar dentro
  dele aciona a ferramenta da aba ativa (ver abaixo).
- As paletas **Tinta** e **Fundo** (topo direito) mostram as 16 cores fixas do MSX1 — clique numa cor
  para selecioná-la. "Tinta" é a cor usada por PSET/LINE/CIRCLE/DRAW/PAINT e pelo texto; "Fundo" é usada
  por PRESET e como cor de fundo do texto.

### Ferramentas de desenho

Sete abas, uma por ferramenta:

- **PSET** / **PRESET** — digite X/Y e clique em "Adicionar", ou simplesmente **clique no canvas**: o
  pixel liga (PSET, cor Tinta) ou apaga (PRESET, cor Fundo) na hora, já vira um comando na lista.
- **LINE** — reta, caixa (contorno) ou caixa cheia, conforme o botão marcado. No canvas, o **primeiro
  clique marca o ponto inicial** e o **segundo traça** a linha/caixa; antes do segundo clique, uma
  **linha elástica** amarela acompanha o mouse (com um marcador vermelho no ponto inicial) para você ver
  exatamente o que vai ser traçado.
- **CIRCLE** — círculo ou elipse, conforme o botão marcado. No **Círculo**, o primeiro clique marca o
  centro e o segundo define o raio (distância até o clique); na **Elipse**, os dois cliques marcam os
  cantos opostos do retângulo que envolve a elipse. Também tem linha elástica antes do segundo clique.
  Ângulo inicial/final e aspecto ficam disponíveis nos campos da aba, para arcos/fatias de pizza.
  Ambos aceitam qualquer aspecto positivo.
- **PAINT** — preenche a partir de um ponto (X,Y) com a cor Tinta, respeitando cor de borda opcional.
  Clicar no canvas só preenche os campos X/Y — o preenchimento em si precisa do botão "Adicionar PAINT".
- **DRAW** — monta uma linha da mini-linguagem `DRAW` do MSX-BASIC clicando nos botões `U D L R E F G H`
  (movimento, usando o valor do campo "Valor"), `B`/`N` (não traça / traça e volta), `M x,y` (move
  absoluto), `C` (cor = Tinta atual), `S` (escala) e `A`/`TA` (ângulo em passos de 90° / ângulo livre em
  graus) — cada clique acrescenta um pedaço à "Linha atual"; "Adicionar DRAW" fecha a linha como um
  comando e limpa o campo para a próxima.
- **TEXTO** — ver seção própria abaixo.

### Parâmetros STEP e LINE -(x,y)

Como no MSX-BASIC real, o editor mantém um **cursor gráfico** interno que cada comando de desenho
atualiza para a sua coordenada de referência ao terminar (LINE deixa no ponto final; CIRCLE/PSET/
PRESET/PAINT deixam no próprio ponto; DRAW deixa na posição final do desenho).

- Marcando a caixa **STEP** de um campo X/Y (disponível em PSET, PRESET, CIRCLE, PAINT e nos dois
  pontos da LINE), o valor digitado — ou o ponto clicado no canvas — passa a ser um **deslocamento a
  partir do cursor gráfico atual**, em vez de coordenada absoluta. No caso da LINE, o STEP do ponto 2 é
  relativo ao **ponto 1 da própria linha**, não ao cursor — igual ao `LINE (x,y)-STEP(dx,dy)` do
  MSX-BASIC de verdade.
- Marcando **"LINE -(x,y): sem ponto inicial"**, a LINE usa o cursor gráfico como estivesse, sem pedir
  um primeiro ponto — equivalente ao `LINE -(x2,y2)` do MSX-BASIC (um clique só já completa a linha).
- **Gerar código** emite `STEP(x,y)` e `LINE -(x,y)` literalmente quando essas caixas estão marcadas,
  reproduzindo a sintaxe real do MSX-BASIC.

### Ferramenta TEXTO — quadro elástico arrastável

Escolha o **Alfabeto** (um dos registrados em **Criar → Alfabeto Graphos III...**), o **Terço** (Cima/
Meio/Baixo — só define onde o quadro começa) e digite o **Texto**, depois clique em **"Posicionar
TEXTO..."**. Um quadro com o texto de verdade (os glifos reais do alfabeto escolhido, já nas cores
Tinta/Fundo selecionadas) passa a seguir o mouse pelo canvas:

- Por padrão, o quadro move **8 em 8 pixels**, encaixando sempre num tile de caractere (a única forma
  de o texto depois virar `LOCATE`/`PRINT` de verdade).
- Segurando **Ctrl**, o quadro move **pixel a pixel**, para alinhar fino com um desenho já existente.
- **Clique no canvas** fixa o texto naquele ponto (vira um comando na lista); **botão direito** cancela
  o posicionamento sem adicionar nada.

Se o ponto final cair no grid de 8px, "Gerar código" produz o carregador do alfabeto (`DATA`+`VPOKE` na
Pattern/Color Table do terço) mais `LOCATE`/`PRINT` — o mecanismo real e compacto do MSX-BASIC. Se você
posicionou fora do grid (usando Ctrl), `LOCATE` não consegue endereçar aquele ponto — nesse caso o
código gerado "queima" cada pixel do texto diretamente via `PSET`/`PRESET` (mais linhas de código, mas
funciona em qualquer posição).

### Lista de comandos e mini buffers

A lista **Comandos** (abaixo do canvas) mostra todos os comandos da tela, na ordem em que são
desenhados — **Remover** apaga o selecionado, **▲**/**▼** reordenam (útil quando um comando precisa ser
desenhado antes/depois de outro, por causa do color clash). PSET, PRESET, LINE e CIRCLE também têm um
**mini buffer** próprio na aba da ferramenta (uma lista filtrada só com aquele tipo de comando) com seu
próprio botão de remover — mais rápido que caçar um PSET específico no meio de uma lista grande e mista.

### Gerar código e injetar no editor

- **Gerar código** monta o BASIC final (`PSET`/`PRESET`/`LINE`/`CIRCLE`/`PAINT`/`DRAW`, mais o
  carregador de alfabeto e `LOCATE`/`PRINT` ou o pixel-a-pixel do texto), um comando por linha, na
  mesma ordem da lista.
- **Injetar no cursor** cola o código gerado na aba de texto ativa do editor, na posição do cursor.
- **Copiar** coloca o código gerado na área de transferência.

### Barra de projeto

Mesma barra dos demais editores (sprites, alfabetos, som, música): número da tela, tag, navegação
**Primeira/Anterior/Próxima/Última**, **Novo** (começa uma tela em branco, numerada automaticamente),
**Registrar** (grava a lista de comandos no projeto), **Copiar**/**Colar** (clipboard de sessão para
duplicar uma tela inteira). Diferente do editor de sprites/alfabetos, o que fica salvo é a **lista de
comandos** (não uma imagem/framebuffer) — permitindo reabrir a tela depois e continuar editando,
reordenando ou removendo comandos individuais.

## Graphos III — Tela SCREEN 2

**Criar → Graphos III Screen 2...** é o início de uma réplica do **Graphos III**, um editor de vídeo
clássico do MSX (Renato Degiovani, 1987) que só trabalha em SCREEN 2 — o manual original completo está
em `graphos/graphos.txt`. Diferente do **Editor de DRAW Screen 2** (seção anterior), que monta uma
*lista de comandos* `PSET`/`LINE`/`CIRCLE`/etc. pra gerar código BASIC, o Graphos III edita o
**framebuffer diretamente**, pixel a pixel — mais parecido com um editor de bitmap de verdade. Cada
função do Graphos III original ganha sua **própria opção** dentro de "Criar" nesta IDE: o editor de
alfabetos do Graphos III **já existe** (**Alfabeto Graphos III...**, mais atrás neste manual) e não faz
parte desta janela. O programa original usava as teclas **F1** a **F5** pra abrir os menus
DESENHO/TEXTO/TELA/AJUSTE/MISCELANEA — aqui cada operação vai virando um botão/ícone conforme é
implementada, no mesmo espírito do editor de sprites.

> Esta é a **primeira fase**: só a tela e as ferramentas mais básicas. O resto do menu DESENHO (BLOCO,
> LINHA, RETÂNGULO, RAIO, CÍRCULO, PINTURA, SPRAY, FILL), os menus TEXTO/TELA/AJUSTE/MISCELÂNEA, os
> shapes e os formatos de arquivo do Graphos III (`.SCR`/`.LAY`/`.VTC`+`.ATC`) ainda não existem —
> ficam para os próximos cortes. Esta janela ainda não registra nada no `.msxproject`.

### Canvas e color clash

O canvas mostra a tela inteira (256×192 pixels, ampliada 2× pra facilitar o clique) com o **color
clash idêntico ao hardware real do MSX**: cada faixa horizontal de 8 pixels (1 byte da Pattern Table)
só pode mostrar **2 cores ao mesmo tempo** — a cor de tinta (INK) dos pixels ligados e a cor de fundo
(PAPER) dos pixels desligados dessa faixa. Pintar um pixel com uma tinta diferente na mesma faixa muda
a cor de **todos** os pixels ligados da faixa, exatamente como uma TV ligada num MSX de verdade
mostraria. Esse comportamento não foi reescrito para esta janela — é o mesmo motor já usado e testado
pelo **Editor de DRAW Screen 2** (`src/editor/visual_editors/Screen2Synth.pbi`).

### Paleta INK/PAPER e ferramentas

- **Tinta (INK)** / **Fundo (PAPER)**: dois seletores de paleta com as 16 cores fixas do MSX1 — clique
  numa cor pra selecioná-la.
- **Lápis** (TRAÇO/INS no manual original): liga o pixel sob o cursor com a cor de Tinta selecionada.
  Clique uma vez ou segure o botão esquerdo e arraste pra riscar continuamente.
- **Borracha** (TRAÇO/DEL): apaga o pixel sob o cursor, gravando a cor de Fundo selecionada na faixa —
  mesmo comportamento de arrastar contínuo do Lápis. Lápis e Borracha são mutuamente exclusivos (só um
  fica "pressionado" por vez).
- **Limpar tela** (LIMPA TELA do menu TELA original): apaga a tela inteira e grava as cores de Tinta/
  Fundo atualmente selecionadas em toda ela — equivalente a começar uma tela nova já com as "cores de
  ATRIBUTOS" escolhidas.

## Assembler Z80

Assembler Z80 nativo, **compatível com M80/L80** (o Microsoft MACRO-80/LINK-80 clássico) — a
especificação de comportamento é portada do [Nestor80](https://github.com/Konamiman/Nestor80)
(Konamiman/Nestor Soriano), um assembler moderno 100% compatível com M80/L80. Detalhe técnico completo
de como foi construído (decisões, testes, limitações) em
[`docs/resumo-asm.md`](resumo-asm.md); este é o guia de uso.

### Aba Assembly (.asm)

**Arquivo → Novo Assembly** (`Ctrl+Shift+N`) abre uma aba de código Z80 assembly, com realce de
sintaxe próprio (mnemônicos, registradores, condições de desvio, diretivas, rótulos, números em
qualquer base, strings). Abrir um arquivo `.asm`/`.z80`/`.mac` já existente também entra automaticamente
nesse modo. As caixas de diálogo de Abrir/Salvar já filtram/sugerem a extensão certa pra esse tipo de
aba.

### Montar (Ctrl+F5)

Com uma aba `.asm` ativa, **Executar → Montar Assembly (.bin)...** (atalho `Ctrl+F5`) monta o código em
modo **absoluto**. Se houver um erro, uma mensagem mostra a **linha** e a **descrição do problema** em
vez de travar ou dar um erro genérico. Se der certo, abre a janela **"Saída da montagem"** com quatro
caminhos (a mesma janela usada depois de **Linkar** e depois do **Assembly Sub Project**, ver seções
seguintes):

- **Salvar .bin no PC...**: pergunta o formato do arquivo antes do diálogo de salvar —
  - **Sim — com cabeçalho MSX BLOAD**: grava os 7 bytes clássicos (`0FEh` + endereço inicial + endereço
    final + endereço de execução, este último igual ao inicial) antes do código — é o formato que
    `BLOAD "ARQUIVO.BIN",R` do MSX-BASIC espera.
  - **Não — binário cru**: só os bytes montados, sem cabeçalho nenhum.
- **Gerar .COM (MSX-DOS, independente do BASIC)...**: grava o binário cru (sem cabeçalho, sem
  perguntar — um `.COM` clássico CP/M/MSX-DOS nunca tem cabeçalho) direto com extensão `.com`. Se o
  fonte usa `ORG 100h`, o resultado é idêntico ao "binário cru" acima; se o endereço de montagem for
  outro, avisa (sem bloquear) que o código provavelmente não vai rodar certo, já que o MSX-DOS sempre
  carrega um `.COM` em `0100h` independente do `ORG` do fonte. Este é o caminho pra rodar o código
  montado **sem passar pelo MSX-BASIC nenhum** — direto do prompt do MSX-DOS.
- **Gravar disco MSX (.dsk, BLOAD)...**: monta um disquete `.dsk` (reaproveitando `MSXDisk.pbi`, o mesmo
  mecanismo do "Rodar no openMSX") já com o binário (sempre com cabeçalho BLOAD, senão o `AUTOEXEC.BAS`
  não saberia o endereço de carga) e um `AUTOEXEC.BAS` de autorun (`10 BLOAD"NOME.BIN",R`) — abrir esse
  disco no openMSX já carrega e roda o código sozinho.
- **Gerar listing BASIC (DATA/POKE)...**: abre uma janela com um loop `FOR/READ/POKE` + blocos `DATA` em
  hexadecimal (16 bytes por linha) que carregam o binário no endereço de montagem, mais um comentário
  `DEFUSR=.../A=USR(0)` pronto pra chamar — útil pra colar o código Z80 dentro de um programa BASIC sem
  precisar carregar um arquivo à parte. Botões **Copiar**/**Injetar no cursor** (mesmo padrão dos
  editores de som/música/desenho).

As exportações que produzem um arquivo de verdade (`.bin`/`.com`/`.dsk`, não o listing) ficam
registradas no projeto atual (`.msxproject`) como a "última build" dessa aba — sem janela própria pra
consultar isso ainda, é só metadado interno usado pra futuras integrações (ex.: um "recarregar último
binário").

Pra código que precisa ficar guardado num endereço mas **rodar** em outro (ex.: rotina copiada da ROM
pra RAM antes de executar, ou justamente o próprio cabeçalho BLOAD — o cabeçalho tem que vir ANTES dos
bytes, mas o código dentro dele referencia labels como se já estivesse no endereço final de carga), use
**`.PHASE <endereço>`** / **`.DEPHASE`**: dentro do bloco, rótulos e `$` passam a valer como se o
código já estivesse no endereço indicado, mas os bytes continuam sendo escritos na posição real
(sequencial, sem pular nada) — ao fechar com `.DEPHASE`, volta ao endereço real de onde parou. Exemplo
completo em [`dist/sample/teste3_phase.asm`](../dist/sample/teste3_phase.asm) (o mesmo do manual original do
MACRO-80, seção "Relocation Before Loading").

### O que já é suportado

- **Todo o conjunto de instruções Z80 documentado**, incluindo os modos indexados `(IX+d)`/`(IY+d)` e
  as variantes de bit/rotação indexadas, mais o subconjunto indocumentado de uso comum `IXH`/`IXL`/
  `IYH`/`IYL` (os "meios registradores" de `IX`/`IY`).
- **Rótulos** (`nome:`/`nome::`), **`EQU`/`DEFL`/`ASET`** (constantes — `EQU` não pode ser redefinida,
  `DEFL`/`ASET` podem), **`ORG`** (define o endereço de carga), **`END`**, **`.PHASE`/`.DEPHASE`**
  (código montado num endereço mas com rótulos resolvendo como se rodasse noutro — ver seção "Montar"
  acima).
- **Diretivas de dados**: `DB`/`DEFB`/`DEFM` (bytes ou texto), `DW`/`DEFW` (palavras de 16 bits),
  `DS`/`DEFS` (reserva um bloco, com valor de preenchimento opcional), `DC` (como `DB`, mas o último
  byte marca fim de string com o bit mais alto ligado), `DZ`/`DEFZ` (como `DB`, mas com um `0` no
  final).
- **Condicionais**: `IF`/`IFT`/`IFE`/`IFF`/`IFDEF`/`IFNDEF`/`IF1`/`IF2`/`ELSE`/`ENDIF`.
- **Macros com parâmetros**: `nome MACRO param1,param2` (o `:` depois do nome é opcional) ... corpo
  ... `ENDM`, chamada como se fosse uma instrução (`nome arg1,arg2`), `EXITM` sai da expansão mais
  cedo, `LOCAL rotulo1,rotulo2` (logo na primeira linha do corpo) garante que cada chamada da macro
  gera rótulos internos únicos — sem isso, uma macro chamada duas vezes com um rótulo fixo dentro
  colidiria consigo mesma.
- **Expressões**: os operadores clássicos M80 (`+ - * / MOD SHR SHL AND OR XOR NOT HIGH LOW EQ NE LT
  LE GT GE`, mais os sinônimos `NEQ`/`LTE`/`GTE`), parênteses, números em decimal/hexadecimal
  (sufixo `H`, precisa começar com dígito — `0FFh`, não `FFh` — ou prefixo `0x`/`#`)/octal (`O`/`Q`)/
  binário (`B`, ou prefixo `0b`/`%`), strings de 1-2 caracteres como valor numérico, e `$` para "o
  endereço desta linha".

### Montar relocável (.REL)

**Executar → Montar Assembly relocável (.REL)...** monta a aba `.asm` ativa em código **relocável**
(`.REL`, formato Nestor80/LK80, `ASEG`/`CSEG`/`DSEG`/`COMMON`/`PUBLIC`/`ENTRY`/`GLOBAL`/`EXTRN`/`EXT`/
`EXTERNAL`/`.REQUEST` todos com efeito real) em vez de absoluto. O nome do "programa" dentro do `.REL`
é o nome do arquivo em maiúsculas — é esse nome que aparece depois em **Biblioteca Z80...** e nas
mensagens do linker. Diferente de "Montar Assembly (.bin)...", só pergunta onde salvar o `.rel` — não
faz sentido perguntar cabeçalho BLOAD nem oferecer disco/listing aqui, porque um `.REL` é um artefato
intermediário (não roda sozinho no MSX): o próximo passo é **Linkar** (seção seguinte) ou empacotar numa
biblioteca.

### Linkar (.REL) → binário

**Executar → Linkar (.REL) → binário...** abre a janela do linker: uma lista de arquivos `.REL` **na
ordem em que devem ser linkados** (a ordem importa — é a mesma ordem de concatenação de `CSEG`/`DSEG`/
`COMMON` que o LK80 real usa), com botões **Adicionar...**/**Remover**/**Subir**/**Descer**, mais um
campo opcional de **pasta de biblioteca** (onde um `.REQUEST` dentro de algum `.REL` vai procurar a
`.LIB` correspondente). O botão **Linkar...** resolve `PUBLIC`↔`EXTRN` entre os módulos (incl. `.REQUEST`
contra a biblioteca, trazendo só os programas que realmente resolvem algum símbolo pendente — linkagem
estática seletiva de verdade) e manda o binário final pra mesma janela "Saída da montagem" da seção
"Montar" acima (`.bin`/`.com`/disco `.dsk`/listing BASIC).

### Biblioteca Z80 (.LIB)

**Criar → Biblioteca Z80 (.LIB)...** gerencia bibliotecas de objetos relocáveis: **Nova...**/**Abrir...**
escolhem o arquivo `.lib`, a lista mostra cada programa já empacotado (nome, tamanho, símbolos
públicos), **Adicionar .REL...** empacota um ou mais `.rel` na biblioteca (cria o arquivo se ainda não
existir) e **Remover selecionado** tira um programa específico (apaga o arquivo inteiro se era o
último). Diferente do gerenciador de disco (**Criar → Disco...**), não há rascunho em cópia temporária
nem botão "Salvar" — cada operação já grava direto e de forma atômica no arquivo `.lib` escolhido.

Detalhe técnico completo do motor por trás dessas três janelas (algoritmo, formato de bit-stream,
testes byte a byte contra `N80.exe`/`LK80.exe`/`LB80.exe`) em [`docs/resumo-asm.md`](resumo-asm.md).

> **Nota sobre `.REQUEST`**: o linker sempre procura o arquivo pedido por um `.REQUEST <nome>` como
> `<nome>.rel` dentro da pasta de biblioteca — mesmo que você tenha salvo a biblioteca com extensão
> `.lib` pela janela acima. Chamando o linker/Sub Project diretamente com uma pasta de biblioteca
> manual, salve (ou renomeie) o arquivo com extensão `.rel`; o **Assembly Sub Project** (próxima
> seção) faz essa normalização sozinho, então esse detalhe só importa se você estiver montando a pasta
> de biblioteca manualmente.

### Assembly Sub Project (Makefile primitivo)

**Criar → Assembly Sub Project...** junta o fluxo completo — vários `.asm`, bibliotecas e o binário
final — numa única janela, "como um Makefile primitivo". Mesma barra de projeto dos demais editores
(número/tag/**Primeiro**/**Anterior**/**Próximo**/**Último**/**Novo**/**Registrar**).

- **Lista de arquivos .ASM** (esquerda): a ordem importa — é a ordem de link. **Adicionar...** (aceita
  selecionar vários de uma vez), **Remover**, **Subir**/**Descer** reordenam.
- **Lista de bibliotecas** (direita): bibliotecas `.rel`/`.lib` que algum `.asm` da lista referencia via
  `.REQUEST nome` — o nome do arquivo (sem extensão) precisa bater com o nome pedido. **Adicionar
  biblioteca...**/**Remover biblioteca**.
- **Gerar biblioteca a partir dos .ASM selecionados...**: marque algumas linhas na lista de `.asm`
  (clique com Ctrl/Shift pra selecionar várias) e clique aqui para montar só essas e empacotar numa
  biblioteca nova ou existente — sem nada marcado, usa a lista inteira do subprojeto. Depois de gerar,
  pergunta se quer adicionar essa biblioteca de volta à lista do subprojeto (útil pro caso comum de
  "algumas rotinas viram uma lib interna que o resto do próprio subprojeto usa via `.REQUEST`").
- **Montar tudo (Build)...**: monta cada `.asm` em `.REL`, resolve as bibliotecas da lista e linka tudo
  num binário final — mesma janela "Saída da montagem" das seções anteriores (`.bin`/`.com`, disco
  `.dsk` ou listing BASIC). Diferente de "Montar Assembly (.bin)..." (uma aba só), aqui não precisa ter
  nenhum arquivo aberto no editor — os `.asm` são lidos direto do disco pelos caminhos da lista.

Detalhe técnico completo (algoritmo de staging de biblioteca, achado sobre a extensão `.rel`, suíte de
testes) em [`docs/resumo-asm.md`](resumo-asm.md), seção "Assembly Sub Project".

### O que ainda não é suportado

- **`--code`/`--data`/`--align-code`/`--align-data`/`--code-before-data` do linker**, detecção de
  sobreposição de segmento entre programas e saída Intel HEX — fora do escopo dos cortes já feitos.
- **Consulta ao histórico de builds no projeto** — o `.msxproject` já guarda a última exportação de
  binário/disco por origem (ver seção "Montar" acima), mas ainda não existe uma janela pra navegar esse
  histórico (diferente de sprites/alfabetos/sons/músicas/telas, que têm barra de navegação própria).
- `REPT`/`IRP`/`IRPC`/`IRPS` (macros de repetição), `MODULE`/rótulos locais, saída em Intel HEX,
  arquivo de listagem `.LST`, R800/Z280 (só Z80 puro por enquanto).

## Ajuda MSX BASIC (dicionário e manual, MSX1 e MSX2+)

Menu **Ajuda → MSX BASIC...** abre uma janela de referência com todo o dicionário de comandos/
funções/instruções do MSX BASIC mais os capítulos de prosa dos manuais originais, pesquisável e
navegável sem sair do editor.

### Abrindo e navegando

A janela **não é modal** — pode ficar aberta do lado do editor enquanto você escreve código,
igual a **Ajuda → Nestor Basic...** (mesmo layout: busca no topo, árvore à esquerda, conteúdo à
direita).

- **Buscar**: digite parte do nome de um comando ou de um tópico — a árvore filtra em tempo real.
- **Árvore**: agrupada por seção (Parte I/III/Apêndices do manual MSX1, dicionário completo, manual
  MSX 2+, FM-Music, Cores do MSX). Clicar num item mostra o conteúdo à direita.
- **Voltar** (botão ou `Alt+seta-esquerda`): volta ao tópico anterior, empilhado num histórico —
  útil depois de seguir uma referência cruzada dentro do texto.

### O que está coberto

- **Dicionário MSX1** — as 141 palavras reservadas do livro *"Linguagem BASIC MSX"* (Denise
  Santoro Cruz, Editora Aleph/Gradiente, 1986): sintaxe, descrição, exemplos, página do livro de
  origem.
- **Manual MSX1** — tópicos de prosa e tabelas do mesmo livro (Parte I — estrutura do BASIC MSX;
  Parte III — aplicações especiais; Apêndices).
- **Dicionário MSX 2+** — 45 verbetes do cartucho MSX2+ FM (ACVS Eletrônica): comandos totalmente
  novos (`COLOR=`, `COLORSPRITE`, `COPY`, `SETPAGE`, os comandos de música FM como `CALL MUSIC`/
  `CALL VOICE`, etc.) e comandos do MSX1 que ganham comportamento extra no MSX2+ — esses aparecem
  como um **segundo verbete** logo depois do original, com o sufixo `(MSX2+)` no nome (ex.:
  `SCREEN` e depois `SCREEN (MSX2+)`).
- **Manual MSX 2+** — apresentação do cartucho, legenda de sintaxe do manual (com a categoria
  COMANDO, além de INSTRUÇÃO/FUNÇÃO), apresentação do FM-Music e os 4 apêndices (programação de
  instrumentos, dicas e macetes, relação dos 64 instrumentos, exemplos de música — as duas músicas
  completas do apêndice D são **descritas**, não transcritas nota a nota, por segurança contra erro
  de transcrição em strings de notas muito densas).
- **Cores do MSX** — página com as 16 cores do VDP em faixas coloridas, aproximando os lápis de cor
  da contracapa do livro Gradiente.

## Suporte a NestorBASIC

Integração com o **NestorBASIC 1.11** (Nestor Soriano/Konami Man): uma biblioteca de rotinas em
código de máquina que dá acesso, direto do BASIC, a memória mapeada, VRAM, disco, compressão
gráfica, execução de programas/código guardados em RAM, efeitos sonoros PSG e ao tocador
Moonblaster.

### Arquivo → Novo Nestor Basic...

Cria uma aba nova de Basic Dignified já com:

- O **loader**: código que carrega `NBASIC.BIN` (`BLOAD"NBASIC.BIN",R`) e checa se a instalação
  deu certo antes de continuar.
- A **biblioteca inteira de wrappers** `.NB_NomeDaFuncao(...)` — as 87 funções do NestorBASIC já
  prontas para chamar por nome, sem precisar decorar números de função nem mexer direto nos arrays
  `p()`/`f$()` que o NestorBASIC usa internamente. Cada wrapper devolve o(s) valor(es) principal(is)
  da chamada mais o código de erro por último; `.NB_ErrorText(codigo)` traduz esse código para uma
  mensagem legível.

O texto vem todo colado na aba (sem `INCLUDE`) — pode apagar as funções que não for usar, é só um
ponto de partida.

### Executar → Nestor Basic

Equivalente a **Executar → BASIC** (gera o disco, abre o openMSX já rodando o programa), mas
também copia `NBASIC.BIN`/`NBASIC.DAT` para o disco gerado — sem esses dois arquivos presentes, o
`BLOAD` do loader falha assim que o programa roda no emulador. Use este item (em vez de **Executar
→ BASIC**) sempre que a aba ativa usar alguma função `.NB_*`.

### Ajuda → Nestor Basic...

Janela de referência não-modal (mesma UI de busca/árvore/histórico da Ajuda MSX BASIC acima) com
as 87 funções do NestorBASIC organizadas pelas seções do manual original. Cada função mostra o nome
do wrapper Dignified e um exemplo de chamada pronto, antes da descrição completa dos parâmetros de
entrada e saída — útil para conferir rapidamente a assinatura de uma função sem procurar no manual
original.

![Suporte a NestorBASIC: template gerado por Arquivo → Novo Nestor Basic... ao lado da janela Ajuda → Nestor Basic...](../images/msxbasica-13.png)

---

## Suporte a MSXBAS2ROM

Integração com o [**MSXBAS2ROM**](https://github.com/amaurycarvalho/msxbas2rom) (Amaury Carvalho) — um
compilador de terceiro que transforma um programa **MSX-BASIC clássico** (`.bas`, numerado, sem
Dignified) direto num arquivo **`.rom`**, sem precisar do interpretador BASIC da máquina. A IDE não
embute o compilador — ela baixa a versão oficial mais recente e usa o conteúdo baixado pra gerar a
Ajuda; compilar o `.rom` em si ainda é feito rodando o `msxbas2rom` baixado pela linha de comando (fora
da IDE).

### Arquivo → Novo MSXBas2Rom...

Cria uma aba nova já em modo `.bas` (ASCII clássico numerado — ver [MSX-BASIC clássico: converter,
tokenizar e renumerar](#msx-basic-clássico-converter-tokenizar-e-renumerar)) com um esqueleto mínimo
pronto pra compilar:

```basic
10 REM ------------------------------------------------------------
20 REM  Projeto MSXBAS2ROM
30 REM  Compile com: msxbas2rom NOMEDOARQUIVO.BAS
40 REM  https://github.com/amaurycarvalho/msxbas2rom
50 REM ------------------------------------------------------------
60 SCREEN 0
70 PRINT "HELLO, MSX!"
80 END
```

O destaque de sintaxe numa aba `.bas` reconhece, além do MSX-BASIC clássico, os comandos e funções
**estendidos** do MSXBAS2ROM — `CMD TURBO`, `SCREEN LOAD`, `SET TILE PATTERN`, `HEAP()`, `MSX()`,
`COLLISION()`, `RESOURCE()`, as diretivas de recurso `FILE`/`TEXT` e por aí vai — sem misturar essas
palavras-chave nas abas Dignified comuns (onde `TURBO`, por exemplo, pode perfeitamente ser o nome de
uma variável).

### Configurar → MSXBas2Rom...

Único botão por enquanto: **Baixar versão mais recente**, que:

1. Consulta o GitHub e baixa o binário certo pro seu sistema operacional (Windows ou Linux);
2. Roda `msxbas2rom -h` e busca as páginas principais da wiki oficial (instalação, primeiros passos,
   uso, comandos/funções estendidos, diretivas de recurso...);
3. Monta a Ajuda a partir disso (ver abaixo).

Os arquivos baixados ficam em `dist/editor/tools/msxbas2rom/` (dentro de `dist/editor/`, ao lado de
`dist/PaleoBasic.exe` na raiz de `dist/`) — o binário
em si e a pasta `help/` com o conteúdo já convertido. Clicar em "Baixar" de novo no futuro atualiza os
dois.

### Ajuda → MSXBas2Rom...

Mesmo layout de busca/árvore/conteúdo dos outros helps da IDE, mas com uma diferença importante: o
conteúdo **não vem fixo dentro do `.exe`** — é lido ao vivo da pasta `tools/msxbas2rom/help/` baixada
acima. Sem nada baixado ainda, o menu avisa e pede pra usar **Configurar → MSXBas2Rom... → Baixar**
primeiro. O renderizador de Markdown reconhece títulos, blocos de código e **links clicáveis**
(`[texto](url)` abre no navegador padrão).

---

## N80, LinkStor80 e LibStor80

Downloads de terceiro do [**Nestor80**](https://github.com/Konamiman/Nestor80) (Konamiman/Nestor
Soriano — mesmo autor do NestorBASIC, ver seção acima): **N80** (assembler Z80/R800/Z280 compatível com
MACRO-80), **LinkStor80** (`LK80`, substituto do `LINK-80`) e **LibStor80** (`LB80`, substituto do
`LIB-80`). É o mesmo dialeto que o [assembler Z80 nativo desta IDE](#assembler-z80) porta o
comportamento de — os dois convivem lado a lado, o N80/LinkStor80/LibStor80 baixado aqui **não**
substitui o motor nativo (`Ctrl+F5`), é uma opção pra quem quiser rodá-los direto por fora, por
linha de comando.

### Configurar → N80...

Único botão: **Baixar versões mais recentes**. Diferente do MSXBas2Rom (uma release só), N80/LinkStor80/
LibStor80 vivem no mesmo repositório mas em **releases separadas** — o download resolve as 3 mais
recentes automaticamente (uma consulta só ao histórico de releases do GitHub) e baixa os 3 binários
standalone pra `tools/n80/`. Também baixa e monta a Ajuda:

- Saída de `--help` de cada um dos 3 programas;
- A referência de linguagem e o guia de código relocável do N80;
- O **manual M80L80** (`docs/MACRO-80.txt` do próprio repositório do Nestor80 — o manual original da
  Microsoft pro MACRO-80/LINK-80/CREF-80/LIB-80), convertido com uma normalização leve (linhas em CAIXA
  ALTA viram título; o resto do texto de largura fixa fica como está, pra não bagunçar o alinhamento
  dos exemplos de código).

### Ajuda → N80...

Mesmo motor de Ajuda do MSXBas2Rom (conteúdo lido ao vivo de `tools/n80/help/`, links clicáveis,
"Baixar" de novo atualiza sozinho), com 4 grupos na árvore: **N80**, **LinkStor80**, **LibStor80** e
**M80L80** (o manual completo).

---

## asMSX

Terceiro assembler Z80 suportado pela IDE, ao lado do [assembler nativo](#assembler-z80) e do
[N80/Nestor80](#n80-linkstor80-e-libstor80) acima: **[asMSX](https://github.com/Fubukimaru/asMSX)**,
mantido pelo "asMSX team" a partir do trabalho original de Eduardo "pitpan" Robsy Petrus. Não substitui
nenhum dos outros dois — é mais uma opção de dialeto pra quem já usa/prefere o asMSX, com um botão
próprio (**Executar → Montar Fonte asMSX...**) pra montar chamando o executável de verdade, sem precisar
sair da IDE. Diferença de sintaxe mais visível frente a Z80 "normal": colchetes `[ ]` em vez de
parênteses `( )` pra endereçamento indireto (a diretiva `.ZILOG` reverte pra parênteses, se preferir).

### Arquivo → Novo asMSX...

Cria uma aba `.asm` já com um cabeçalho de comentário e as diretivas mais pertinentes pra um programa MSX
típico: `.BASIC` (gera o cabeçalho pra carregar com `BLOAD"NOME.BIN",R` no MSX-BASIC — a forma mais
simples de testar) e `.ORG 8000h` (página 2, RAM em qualquer MSX padrão — troque conforme necessário).

### Executar → Montar Fonte asMSX...

Monta a aba `.asm` ativa chamando o executável do asMSX configurado — ao contrário de **Montar
Assembly (.bin)/(.REL)** (assembler *nativo* desta IDE), este comando roda o **asMSX de verdade** por
fora, então entende as diretivas próprias dele (`.BASIC`/`.ROM`/`.MegaROM`/`.MSXDOS`/etc. — o tipo do
arquivo gerado vem do que está escrito no fonte, não de uma opção da IDE). Pede pra salvar a aba num
`.asm` real primeiro (o asMSX só assembla arquivo em disco, nunca sobrescreve silenciosamente o arquivo
já aberto) e mostra a saída do programa (mensagens/erros/nomes dos arquivos gerados) ao final. Precisa
do caminho do executável configurado antes (**Configurar → asMSX...** logo abaixo, ou **Configurar →
Projeto...** pra uma configuração só deste projeto).

### Configurar → asMSX...

Campo de caminho **editável** (+ botão "..." pra apontar direto pra uma instalação já existente) e botão
**Baixar versão mais recente**. Diferente do N80/MSXBas2Rom (asset `.zip`), as releases do asMSX publicam
um executável avulso por sistema/arquitetura — o download busca a release mais recente no GitHub e salva
o executável certo pro seu sistema em `tools/asmsx/`. Mais abaixo, as opções de linha de comando usadas
por **Executar → Montar Fonte asMSX...**: sintaxe Zilog padrão sem precisar de `.ZILOG` no código (`-z`),
modo silencioso (`-s`), modo verboso (`-vv`) e um caminho/prefixo de saída opcional (`-o`, vazio = gera
ao lado do próprio fonte).

### Ajuda → asMSX...

O manual oficial do asMSX, navegável e pesquisável (busca por título ou seção), mesmo layout de
árvore + busca + conteúdo das outras janelas de Ajuda desta IDE. Ao contrário do N80/MSXBas2Rom (conteúdo
baixado e atualizado a cada "Baixar"), o conteúdo desta janela já vem embutido no `.exe` — não precisa
baixar nada antes de consultar.

---

## Controle remoto do openMSX

> Validado ao vivo contra um openMSX real (2026-07-30, ampliado 2026-08-08): pipe conecta, o boot
> automático (`unset renderer`/`set power on`) funciona, comandos manuais recebem resposta, e todos os
> mecanismos de descoberta dinâmica (dispositivo de som, conector MIDI, FPS) foram testados contra um
> openMSX de verdade rodando. Ver `docs/SPEC.md`, módulo 12, para os detalhes técnicos.

### Executar → BASIC (F5) e o console usam a MESMA instância

Desde a versão 7.27.3, **Executar → BASIC**/**Nestor Basic** não abrem mais uma janela nova do openMSX
a cada execução — reaproveitam a instância já aberta (a mesma que **Executar → openMSX...**, abaixo,
controla): rodar F5 duas vezes seguidas troca só o disco da unidade A e dá reset, como trocar o
disquete de um MSX de verdade, sem piscar uma segunda janela do emulador. Se o openMSX ainda não
estiver aberto, F5 sobe ele normalmente, já com a máquina/extensão configuradas.

> **Atenção**: máquina/extensão só valem no **lançamento** do openMSX — se você mudar esses campos em
> **Configurar → openMSX...** com o emulador já aberto, a mudança não se aplica sozinha na instância
> viva. Um aviso aparece na aba **Console** (abaixo) nesse caso; o botão **Reiniciar openMSX** encerra
> e sobe de novo já com a configuração atual.

### Executar → openMSX...

Abre um painel de controle de 6 abas pra essa mesma instância — útil tanto durante a edição (pra
transferir o programa atual sem sair da janela) quanto sozinho, sem nenhum arquivo aberto. Fechar esta
janela **não** fecha o openMSX — abrir o menu de novo reconecta na mesma instância.

No topo, sempre visível: **indicador de estado** ("Ligado/Desligado | Rodando/Pausado", atualiza
sozinho mesmo se o estado mudar por fora, ex. você pausando pela janela do próprio openMSX), botão
**Transferir programa atual** (pega o código da aba ativa do editor e roda na mesma instância — igual
F5) e um aviso automático se máquina/extensão configuradas divergirem da instância aberta (ver caixa
acima).

Embaixo, também sempre visível em qualquer aba: **Reiniciar openMSX**, um **display de FPS** dedicado
(estilo mini-display digital, atualiza ao vivo — o mesmo FPS que já existe na aba Vídeo, aqui sem
precisar trocar de aba), um atalho de **Power** (mesmo comando do Power da aba Outros comandos),
**Mostrar janela**, **Ajuda** e **Fechar**.

#### Aba Console

- Grupo **Mídia**: Disco A / Cartucho / Cassete, cada um com campo de caminho + "..." (escolher
  arquivo) + **Inserir** + **Ejetar**.
- **Log** de comandos e respostas + campo de comando livre (Enter ou botão **Enviar**) — qualquer
  comando que o openMSX aceita via `-control` (os mesmos do console interno dele, F10).

#### Aba Outros comandos

- **Velocidade de emulação**: barra manual (1% a 800%), botão **100%** e botão **Turbo** — segure o
  botão do mouse pra acelerar ao máximo (9999%), solte pra voltar a 100% automaticamente.
- **Power**, **Reset**, **Pause** — os dois primeiros alternam mostrando o estado atual no próprio
  rótulo do botão ("Power: Ligado"/"Desligado").
- **Firmware** — liga/desliga o software residente em memória (só existe em algumas máquinas MSX).
- **Conectores das portas de joystick** (Joystick 1 / Joystick 2): Nada, Mouse, Teclado (P1), Teclado
  (P2) (usa o teclado do PC como joystick — bom pra 2 jogadores locais) ou Paddle.
- **Ren Sha Turbo** — acelera o botão de tiro (auto fire de hardware, só em máquinas com suporte, ex.
  turboR).

#### Aba Vídeo

- **Renderer** (SDLGL-PP/none), **Escala** (2/3/4), **VSync**, **Modo TV** — dropdown com as 5 opções
  reais do openMSX (`simple`/`ScaleNx`/`hq`/`RGBtriplet`/`TV`), igual o seletor de scaler do Catapult
  original.
- Toggles: **Deinterlace**, **Limitar sprites**, **Tela cheia**, **Desabilitar sprites**, **Fonte de
  vídeo** (MSX/GFX9000/Video9000 — só faz efeito com uma extensão GFX9000/Video9000 conectada).
- **Efeitos de tela estilo CRT** — Scanlines, Blur, Glow, Gamma e Noise: cada um com barra, rótulo
  mostrando o valor atual (sincronizado ao vivo com o openMSX) e botão **Reset** que volta pro padrão
  de fábrica real do openMSX (scanline 20, blur 50, glow 0, gamma 1.1, noise 0).
- **Screenshot**: nome base + diretório opcional. Com diretório escolhido, o próprio editor calcula o
  próximo número sequencial livre (`nome0001.png`, `nome0002.png`...); sem diretório, usa a numeração
  nativa do openMSX na pasta padrão dele (`screenshots/`).
- **LEDs** (Power/Caps/Kana/Pause/Turbo/FDD) desenhados como círculos coloridos (verde = ligado, cinza
  = desligado, amarelo = ainda não sabido) + botão **STOP** (simula a tecla física STOP do teclado
  MSX, usada pra interromper um programa BASIC) + **FPS** ao vivo (o mesmo valor também aparece no
  display dedicado da barra inferior, visível em qualquer aba — ver acima).

#### Aba Volume

Mixer de som do openMSX com **descoberta dinâmica de dispositivo**: como o nome real de cada chip
varia por cartucho/ROM conectado (ex. `"Konami SCC+ Cartridge with expanded RAM (1)"`, não um nome
fixo tipo "SCC+"), a lista de dispositivos não vem pronta — aparece sozinha conforme o openMSX avisa
que algo mudou, ou você adiciona manualmente digitando o nome (campo **Adicionar** acima da lista;
consulte o nome exato no próprio menu do openMSX, **Configurações → Áudio → Mostrar ajustes dos chips
de som**). `PSG`, `keyclick` e `cassetteplayer` são nomes fixos que sempre existem.

Selecionando um dispositivo na lista: **Volume** (0-100) e **Balance** (-100 = canal esquerdo, 0 =
centro/estéreo normal, 100 = canal direito — substitui o antigo esquema Mute/Left/Right/? do Catapult,
que foi removido do openMSX atual em favor deste controle contínuo) + botão **Mudo**.

Seção **MIDI**: entrada (arquivo `.mid` pra tocar como MIDI IN) e saída (log de eventos MIDI OUT em
arquivo), cada uma com **Conectar**/**Desconectar** — os conectores MIDI reais também variam por
hardware (descobertos automaticamente ao abrir a aba). **Log de áudio geral** grava um `.wav` da sessão
inteira (clique de novo pra parar).

#### Aba Input Text

Área grande de texto + botão **Type** (digita o conteúdo no MSX como se fosse teclado de verdade —
quebra de linha vira Enter, mesmo mecanismo do Catapult) e **Clear** (só esvazia a área, não afeta o
openMSX). Útil pra colar um programa inteiro direto na linha de comando do BASIC sem precisar montar
um disco.

**Paleta de teclas especiais**: 23 botões (ESC, F1-F5, TAB, BS, DEL, INS, HOME, SELECT, STOP, ENTER,
setas, GRAPH, CODE, CTRL, SHIFT, CAPS) que inserem, na posição do cursor, uma tag `⟦NOME⟧` (colchetes
duplos especiais, não confundir com `[` `]` do teclado normal) — o botão **Type** reconhece essa tag e
pressiona a tecla de verdade em vez de digitar o texto dela. Isso resolve um problema real: se você
escreve `10 PRINT "Pressiona [ESC]"`, os colchetes normais da string continuam saindo como texto puro
— só a tag especial vira tecla, então não tem risco de confundir uma tecla querida com um texto que só
por acaso menciona o nome dela.

Cada clique nos botões da paleta insere uma tecla que é **apertada e solta na hora**, uma de cada vez —
bom pra sequências (ex. `[ESC]` depois `[DOWN]`, cada uma independente). Quando você precisa de um
**combo de verdade** (mais de uma tecla pressionada AO MESMO TEMPO — ex. Shift+F1, Ctrl+Select), ligue
o botão **Modo Combo**: os cliques na paleta param de inserir na hora e passam a acumular num combo
(o rótulo ao lado mostra o que já foi escolhido, tipo "Combo: SHIFT + F1") até você clicar **Inserir**,
que escreve uma única tag combinada (`⟦SHIFT+F1⟧`) — essa tag segura todas as teclas primeiro e só
solta todas no final, diferente da tag simples. **Cancelar** descarta o combo acumulado sem inserir
nada. Desligar o Modo Combo volta a paleta ao comportamento padrão (uma tecla por clique, na hora).

#### Aba Status Info

Log somente-leitura de **tudo** que o openMSX reporta — mudou por um comando seu ou não (ex. você
apertando uma tecla direto na janela do openMSX, ou um jogo acendendo o LED de disquete). Separado do
log da aba Console de propósito: lá fica só a sua sessão interativa (o que você digitou + respostas);
aqui fica o "o que está acontecendo" cru. O valor de FPS (consultado a cada segundo) fica de fora
deste log e do da aba Console — já tem o display dedicado na barra inferior, não precisa mais poluir
nenhum dos dois.

A comunicação usa um mecanismo próprio do openMSX (`-control`) espelhado no do Catapult (a GUI
oficial do projeto), documentado com mais detalhe em `docs/SPEC.md`. Configure o caminho do openMSX em
**Configurar → openMSX...** (ou na aba **Emulador** de **Configurar → Basic Dignified...** — mesmo
campo) antes de usar.

### Ajuda → openMSX...

Janela de referência não-modal (mesma UI de busca/árvore/histórico das outras janelas de Ajuda) com
os 5 manuais originais do openMSX — Guia de Configuração, Manual do Usuário, Using Diskmanipulator,
Controlling openMSX from External Applications e a Referência de Comandos/Configurações completa
(mais de 250 tópicos). Diferente do console acima, esta janela é só consulta de texto — não depende
do openMSX estar aberto nem do controle remoto funcionar.

## Base de conhecimento MSX (manuais antigos, livros técnicos)

Sete janelas de referência, todas com a mesma UI não-modal de busca/árvore/histórico das outras
janelas de Ajuda — a diferença é a origem do conteúdo: documentação técnica antiga (manuais de
fabricante, livros técnicos há muito fora de catálogo), reproduzida como no original, não escrita
pela equipe do projeto. Pode ficar aberta ao lado do editor enquanto você programa.

### Ajuda → Manuais MSX...

Documentos técnicos originais completos: **MSX-DOS 2** (Referência, Interface de Programa, Códigos de
Função), **Z80** (conjunto de instruções por código e por mnemônico) e **R800**, **Turbo-Basic
Compiler**, **FM-PAC** e o **MSX2 Technical Handbook** (a transcrição original de 1997, texto puro —
veja também **Ajuda → MSX2 Technical Handbook...** abaixo para uma edição mais recente, com tabelas e
figuras).

### Ajuda → MSX-Basic/DOS/CP-M (RuMSX)...

Referência de comandos MSX-BASIC (organizada por geração — MSX1/MSX2/MSX2+/Turbo-R —, mais Disk-BASIC
e as extensões `CALL` de firmware), MSX-DOS e CP/M, cada comando com Sintaxe/Função/Exemplo/Veja
também. É uma **segunda fonte** de referência MSX-BASIC, em paralelo com **Ajuda → MSX BASIC...**
(baseada no livro brasileiro "Linguagem BASIC MSX") — compare as duas e use a que preferir.

### Ajuda → BIOS MSX: Chamadas / Hardware / Documentação (RuMSX)...

Três janelas cobrindo a documentação de BIOS do RuMSX: **Chamadas** tem as rotinas de BIOS
individuais (MainROM, RAM-variables, SubROM, Disk-ROM, Hangul-ROM, BDOS, EXTBIO, MSX-JE), uma entrada
por endereço/nome — útil pra pesquisar uma rotina específica pelo nome (`RDSLT`, `CALSLT` etc.) sem
abrir um PDF externo. **Hardware** cobre os chips e periféricos (PSG, SCC, VDP, V9990, teclado, portas
I/O, ROM Kanji, etc.). **Documentação** tem os tópicos avulsos (sequências ESC de impressora,
software-reset).

### Ajuda → Livro Vermelho...

**"The MSX Red Book"** (Avalon Software/Kuma Computers, 1985) completo — um dos livros técnicos mais
respeitados sobre o hardware/software do MSX1, incluindo a BIOS descrita rotina por rotina. Esta
janela tem um recurso que nenhuma outra tem: **os links internos do livro são clicáveis de verdade**
— clicar numa palavra sublinhada azul (ex.: uma referência a outra rotina, tipo "veja `DAC`") navega
direto pra aquele tópico, sem precisar procurar na árvore. As figuras originais do livro (diagramas de
registrador/porta) também são clicáveis — abrem num popup com a imagem, ao lado do texto.

### Ajuda → MSX2 Technical Handbook...

O manual técnico oficial da ASCII Corporation para o MSX2 (1987), na edição em Markdown mantida por
Konamiman (autor do Nestor80, já usado nesta IDE) — mais completa que a transcrição de 1997 já
incluída em **Ajuda → Manuais MSX...**, com tabelas e as figuras originais do livro. Mesmos links e
figuras clicáveis do Livro Vermelho acima.

## Ajuda Basic Dignified (sintaxe da linguagem e configurações desta IDE)

Menu **Ajuda → Basic Dignified...** abre uma janela de referência (mesma UI não-modal de
busca/árvore/histórico das outras duas janelas de Ajuda) compilada a partir da documentação oficial
do Basic Dignified Suite original, cruzada com o código desta IDE para dizer o que realmente se
aplica aqui.

### O que está coberto

- **Sintaxe Dignified** — as regras do dialeto que você escreve no editor: labels e loop labels
  (`{rotulo}`, `nome{ ... }`, `exit`), defines (`define [nome][conteúdo]`), variáveis de nome longo
  e `DECLARE`, proto-funções `FUNC`/`RET` (incluindo o aviso de que a definição precisa ficar
  **depois** do `end` do fluxo principal, senão o programa executa a função sem ela ter sido
  chamada), separação/junção de linha com `:`/`_`, comentários exclusivos e toggles (`##`, `#nome`),
  tradução de caracteres Unicode especiais, `INCLUDE` de arquivos externos e `TRUE`/`FALSE`/
  operadores compostos.
- **Configurar → Basic Dignified...** — cada campo das 3 abas da tela de configuração, explicado
  campo a campo. Importante: os tópicos dizem explicitamente **quais campos afetam a conversão de
  verdade** (numeração de linha, TAB, cabeçalho REM, espaços, maiúsculas, tradução Unicode,
  converter `?`/`PRINT`, remover `THEN`/`GOTO`, rodar no openMSX com máquina/extensão) e **quais
  existem só por compatibilidade** com o `.ini` do toolchain Python original, sem efeito nenhum
  nesta IDE hoje (os 6 checkboxes de relatório e a verbosidade da primeira aba, as opções de
  listagem do tokenizador na aba MSX, e monitor/nothrottle/setting/verbosidade do emulador na aba
  Emulador).
- **Remtags** — o que são as diretivas `##BB:comando=valor` no código, e a lista exata de flags que
  `##BB:arguments=` de fato aplica nesta IDE, mais `export_file=` (troca o destino sugerido ao
  salvar) e `help=`.
- **Sobre a suíte original** — ferramentas do Basic Dignified Suite em Python que **não foram
  portadas** para esta IDE (o conversor reverso DignifieR, a integração com Sublime Text/VSCode, o
  suporte a Tandy CoCo), mais uma referência rápida do formato binário tokenizado `.bmx`.

## Ajuda SEE Tracker (manual original e formato de arquivo)

Menu **Ajuda → SEE Tracker...** abre uma janela de referência (mesma UI não-modal de busca/árvore/
histórico das outras janelas de Ajuda) sobre o **SEE** (Sound Effect Editor), um editor de efeitos
sonoros PSG shareware para MSX (Fuzzy Logic, 1991/95) que gera arquivos `.SEE`/`.SFX` tocáveis via um
pequeno driver Z80 — o mesmo tipo de integração `BLOAD`+`DEFUSR`/`USR()` já usado pelo NestorBASIC
desta IDE. É material de **estudo**: ainda não existe nenhum editor/gerador `.SEE` nesta IDE, mas o
objetivo é construir um tracker de SFX nativo compatível com o formato, para uso via NestorBASIC.

### O que está coberto

- **Manual original (v3.10a)** — telas, menus, teclas de atalho, os 11 canais de um pattern (event/
  som/rustle/volume/wave/time), os comandos do canal `event` (`HALT`/`FOR`/`NEXT`/`START`/`RERUN`/
  `TMP`/`END`), efeitos de slide (`D:`/`U:`) e edição em bloco.
- **Formato de arquivo `.SEE`** — cabeçalho, tabela de posições de SFX e o registro de pattern de 15
  bytes, campo a campo, cruzando o manual com o código-fonte do driver de replay (`see/SEE3PLAY.ASC`)
  para corrigir/precisar pontos que o manual só descreve por alto (ex.: quantos bits do byte de
  evento o player realmente testa, o mapeamento exato pros 14 registradores do PSG).
- **Motor de replay** — a API de vetores do driver, o mecanismo real de `FOR`/`NEXT`/`START`/`RERUN`
  (não é só "volta pro pattern" — só dispara uma vez, ver o tópico dedicado) e as fórmulas exatas de
  slide de afinação/volume e da escala por `Max Volume`.
- **Rumo a um tracker compatível** — o que já está confirmado com segurança versus o que ainda
  precisa de um teste controlado antes de implementar de verdade (ex.: o significado exato de um dos
  campos do cabeçalho, que não bateu de forma conclusiva contra os 4 arquivos `.SEE` de exemplo desta
  sessão de estudo).

## Editor Hexa

Atalho: `F7`.

Menu **Executar → Editor Hexa...** (`src/editor/core/HexEditorGui.pbi`) abre um editor hexadecimal genérico —
diferente dos outros editores visuais da IDE, ele não trabalha com a aba de texto ativa: abre
**qualquer arquivo** do disco (até 8 MB) e mostra offset/hex/ASCII numa grade rolável, com
reconhecimento automático dos formatos binários que a própria IDE produz e consome.

### Abrir/Salvar e a grade hex/ASCII

- **Abrir arquivo...** / **Salvar** / **Salvar como...** — mesmo fluxo de qualquer editor da IDE;
  o rótulo ao lado do caminho ganha um `*` quando há bytes editados ainda não salvos, e fechar a
  janela com alterações pendentes pergunta antes de descartar.
- A grade mostra 16 bytes por linha (endereço à esquerda, hex agrupado 8+8, ASCII à direita —
  bytes não imprimíveis aparecem como `.`). Clicar num byte (hex ou ASCII) seleciona um "cursor":
  o byte ganha uma borda na cor de destaque e a linha inteira tem o endereço pintado na mesma cor,
  pra localizar de longe mesmo com a grade rolada. Editar esse byte é digitar 1-2 dígitos
  hexadecimais no campo **Valor (hex)** e clicar **Aplicar**.
- Todo valor hex nesta janela (grade, endereços, campos) sempre aparece com largura fixa (`00`, não
  `0`) — o PureBasic usado aqui não completa zero à esquerda automaticamente em `Hex()`, então isso
  é forçado manualmente para não confundir `00` com `0`, `0C` com `C`, etc.

### Reconhecimento de formato

O painel à esquerda mostra o tipo de arquivo detectado e os campos relevantes. A checagem é sempre
automática (nenhuma configuração necessária) e cobre, nesta ordem:

**Formatos nativos desta IDE**

- **Binário MSX BLOAD/BSAVE** — primeiro byte `FEh`, seguido de endereço inicial/final/execução (2
  bytes cada, little-endian) — mesmo cabeçalho gerado por **Executar → Montar Assembly (.bin)...**
  e pelos editores de sprite/alfabeto/tela. Mostra os três endereços e o tamanho dos dados
  (fim − início + 1).
- **MSX-BASIC tokenizado** — primeiro byte `FFh`, endereço de carga `8001h` por convenção desta IDE
  (ver `#Tok_Base` em `MsxTokenizer.pbi`) — o formato gerado por **Dignified → tokenizado nativo
  (.bmx)...** e **Executar → BASIC**.
- **Imagem de disco MSX (FAT12)** — extensão `.dsk`: lê o boot sector (setor 0) e mostra bytes por
  setor, setores por cluster, número de FATs, entradas do diretório raiz, total de setores, descritor
  de mídia e setores por FAT — os mesmos offsets que `MSXDisk.pbi` lê/escreve internamente.
- **Texto ASCII puro** vs. **BASIC MSX clássico (linhas numeradas)** — diferenciados pelo primeiro
  caractere visível do arquivo (dígito = provável linha numerada, mesma regra que o tokenizador exige
  de entrada).

**Formatos de terceiros da era MSX/CP-M** (reconhecidos por assinatura/estrutura própria, sem precisar
de nenhum programa externo instalado)

- **Executável MSX-DOS (`.COM`)** — extensão checada junto com o fato de não ter cabeçalho (código Z80
  cru, convenção CP/M) — carrega e executa sempre em `0100h`.
- **Planilha SuperCalc 2 MSX (`.CAL`)** — assinatura `"SuperCalc ver."` nos primeiros bytes, mostra
  versão, título da planilha e onde a seção de dados começa. Detalhe completo do formato (o que já foi
  decifrado e o que ainda não) em `docs/reference/supercalc2-cal-format.md`.
- **Banco de dados dBase II (`.DBF`)** — byte de versão `02h` + extensão, mostra número de registros,
  tamanho do registro e a lista de campos decodificada (nome/tipo/tamanho). Formato totalmente
  decifrado, ver `docs/reference/dbase2-dbf-format.md`.
- **Alfabeto Graphos III (`.ALF`)** — cabeçalho BLOAD/BSAVE + 2048 bytes de dados (256 caracteres × 8
  bytes).
- **Layout Graphos III (`.LAY`)** — cabeçalho BLOAD/BSAVE + dados comprimidos; a checagem decodifica o
  RLE+ofuscação de verdade e só reconhece se o resultado bater exatamente com 6144 bytes.
- **Tela Graphos III (`.SCR`)** — cabeçalho BLOAD/BSAVE + rotina de apresentação (tamanho variável) +
  12288 bytes fixos de padrão/cor de SCREEN 2.
- **Banco de shapes Graphos III (`.SHP`)** — o único dos quatro formatos do Graphos III sem cabeçalho
  BLOAD/BSAVE; a checagem percorre a cadeia de blocos do arquivo até achar o terminador `FFh`.

Se nada bater, cai em **binário desconhecido/dados crus**. WordStar e MSX-Word seguem como possíveis
extensões futuras, dependendo de arquivos de amostra reais pra validar antes de implementar — este
projeto não crava reconhecimento de formato binário por suposição.

### Galeria de templates

`.ALF`/`.LAY`/`.SCR` já têm checagem própria e mais profunda (seção anterior, incluindo decodificação
de verdade no caso do `.LAY`) — a galeria de templates abaixo continua existindo pra qualquer outro
binário BLOAD/BSAVE que o usuário queira dar nome amigável, e serve de segunda tentativa se um arquivo
tiver a extensão certa mas não passar na checagem mais profunda (ex.: um `.SCR` fora do padrão).

Binários BLOAD/BSAVE reconhecidos passam por uma segunda checagem contra uma **galeria de
templates**: cada template tem nome, extensão, byte de tipo, endereço inicial e tamanho dos dados
(qualquer campo em branco/−1 significa "qualquer valor") — se um arquivo bater com um template, o
painel mostra o nome amigável (ex.: "Alfabeto Graphos III (.ALF)") em vez do genérico "Binário MSX
(BLOAD/BSAVE)", mais uma linha "Template: ...".

A galeria persiste em `dist/editor/hexeditor_templates.json` (mesmo estilo de persistência de
`editor_settings.json`/`badig_settings.json` — arquivo local da máquina, não versionado) e já vem
semeada com os três formatos nativos do Graphos III (ver `GraphosNativeIO.pbi`/
`CharsetEditorGui.pbi`):

| Template | Extensão | Byte | Endereço | Tamanho dos dados |
| --- | --- | --- | --- | --- |
| Alfabeto Graphos III (.ALF) | `alf` | `FEh` | `9200h` | 2048 bytes (exato) |
| Layout Graphos III (.LAY) | `lay` | `FEh` | `9200h` | qualquer (RLE comprimido) |
| Tela Graphos III (.SCR) | `scr` | `FEh` | qualquer (`9200h` ou `9000h`) | qualquer |

O botão **Galeria de templates...** abre uma janela própria para adicionar (nome + campos, cada um
opcional) ou remover templates da lista — toda alteração é salva no JSON na hora.

### Intervalo marcado e operações de bloco

Além de editar um byte por vez, a barra de operações de bloco trabalha sobre um **intervalo**:

- **Marcar início** / **Marcar fim** — usam o byte selecionado na grade (clique) como limite do
  intervalo; **Limpar seleção** desmarca. O intervalo marcado aparece na grade com um preenchimento
  mais suave que o cursor de byte único, e um rótulo acima da grade mostra o intervalo atual
  (endereço inicial/final e tamanho em bytes).
- **Preencher...** — preenche o intervalo marcado com um valor hex escolhido; se nada estiver
  marcado, pergunta endereço inicial e final antes do valor.
- **Inserir bloco...** — insere bytes numa posição (o byte selecionado, ou perguntada se nada
  estiver selecionado), **deslocando** o resto do arquivo pra frente (o arquivo cresce).
- **Sobrepor bloco...** — mesma escolha de posição, mas **sem deslocar** o que já existe depois — só
  cresce o arquivo se o bloco novo passar do fim atual.
- Tanto **Inserir** quanto **Sobrepor** perguntam a origem dos dados: um **arquivo inteiro**
  escolhido na hora, ou **bytes em branco** (quantidade + valor, ambos escolhidos pelo usuário).
- **Excluir bloco...** — usa o intervalo marcado (ou pergunta início/fim); depois pergunta se
  **desloca de verdade** (remove os bytes e desloca o restante pra trás, o arquivo encolhe) ou só
  **sobrescreve com `00`** no lugar (tamanho do arquivo não muda).

Qualquer operação que mude o tamanho do arquivo (Inserir/Sobrepor além do fim/Excluir deslocando)
limpa a seleção e o intervalo marcado, já que os offsets antigos deixam de fazer sentido.

### Barra de rolagem

A rolagem vertical é uma barra customizada (não o `ScrollBarGadget` nativo do PureBasic, que nesta
configuração renderizava enorme/esticado e com os botões trocados — esquerda subindo, direita
descendo): uma seta tradicional no topo, outra na base, e uma trilha no meio desenhando um "thumb"
proporcional ao trecho do arquivo visível na grade no momento — clicar na trilha pula direto pra
posição proporcional clicada. A grade também rola pela roda do mouse.

## Inserir → Caractere Especial

Atalho: `Ctrl+Alt+I`.

Menu **Inserir → Caractere Especial...** abre um mapa de caracteres parecido com o "Mapa de
Caracteres" do Windows (`charmap.exe`), pros **159 caracteres especiais** que a opção **Traduzir
caracteres Unicode** (`-tr`, ver [Telas de configuração](#telas-de-configuração)) traduz pra ASCII
nativo MSX ao converter — acentos, letras gregas, símbolos gráficos, e (a partir desta versão) também
carinhas/naipes de baralho/linhas de caixa estilo CP437. Sem precisar decorar nem copiar/colar esses
caracteres de outro lugar: escreva o código Dignified normalmente usando os próprios símbolos Unicode
(ex. `print "café ☺"`) e ative `-tr` na conversão — esta janela só ajuda a **digitar** os símbolos que
não têm tecla direta no teclado.

### A grade e a prévia

A grade (16 colunas × 10 linhas, a última célula fica vazia) mostra todos os 159 caracteres. Clicar
numa célula **seleciona** (contorno vermelho) e atualiza o painel à direita: o caractere numa fonte
grande, a posição na tabela (`N/159`), o código MSX (`Codigo MSX: 80h`...`FFh` pros 128 primeiros;
`Grafico MSX: CHR$(1);CHR$(N)` pros 31 últimos — esses usam um escape de 2 bytes, não um código único,
ver nota abaixo) e o codepoint Unicode. Duplo clique numa célula **seleciona e já adiciona** o
caractere ao campo acumulador (ver próxima seção), sem precisar do botão "Adicionar" separado.

> Os 31 últimos caracteres da tabela (carinhas, naipes de baralho, linhas de caixa) são especiais: no
> MSX real eles não têm um único código de 0x80 a 0xFF como os demais — são impressos com uma sequência
> de dois bytes, `CHR$(1)` seguido de uma letra, que sinaliza pro driver de tela "desenhe um dos 31
> gráficos especiais" sem colidir com os códigos de controle de verdade (posicionar cursor etc.) que
> ocupam a mesma faixa. Isso é feito automaticamente pelo conversor quando `-tr` está ativo — não muda
> nada no jeito de usar esta janela, só explica por que o painel de prévia mostra um formato diferente
> pra esses 31 caracteres.

### Campo acumulador e o botão Inserir

Abaixo da grade fica um campo de texto (até **80 caracteres**) onde os caracteres escolhidos vão se
acumulando — pode digitar/editar nele normalmente também, não só clicar na grade. Botões:

- **Adicionar** — acrescenta o caractere selecionado no momento ao campo (mesmo efeito do duplo clique
  na grade).
- **Remover último** — apaga o último caractere do campo.
- **Limpar** — esvazia o campo inteiro.
- **Inserir** — copia o conteúdo do campo pra posição do cursor na aba de texto ativa, e fecha a
  janela. Se o campo estiver vazio, só fecha sem inserir nada.
- **Fechar** — fecha a janela sem inserir nada, mesmo se o campo tiver conteúdo.

![Editor Hexa reconhecendo um alfabeto Graphos III (galeria de templates) — grade hex/ASCII, painel de tipo de arquivo, barra de operações de bloco e barra de rolagem customizada](../images/msxbasica-14.png)

## Editor de tela SCREEN 0

Atalho: `Ctrl+Shift+0` (Criar → Screen 0...).

Este é o primeiro de uma família de 3 editores de tela de texto MSX (**Criar → Screen 0.../Screen 1.../
Screen 1+2...**), cada um cobrindo um modo de cor de texto diferente do hardware: **SCREEN 0** (1 cor
pra tela inteira, com um modo **MSX2+** de 80 colunas que ganha uma segunda cor real de texto — ambos
neste mesmo editor, ver "Cor 2" abaixo), **SCREEN 1** (1 cor por grupo de 8 caracteres, seção seguinte) e
**SCREEN 1+2** (SCREEN 2 de verdade — 3 alfabetos e cor por linha de scanline, duas seções à frente). Os
três compartilham a grade fixa (32×24, ou 40/80×24 no SCREEN 0) e a maioria das ferramentas — só o
modelo de cor muda entre eles.

Menu **Criar → Screen 0...** abre um editor gráfico de telas de texto do modo **SCREEN 0** do MSX, no
espírito dos clássicos editores de tela ANSI da era BBS (TheDraw/AcidDraw/DarkDraw) — mas fiel ao
hardware MSX de verdade: uma tela SCREEN 0 real não tem cor por caractere como um editor ANSI de PC,
só **uma** cor de tinta e **uma** de fundo pra tela inteira (o mesmo que o comando `COLOR` faz).

### Largura, fonte e cor (INK/PAPER único pra tela inteira)

- **Largura** — escolhida ao criar uma tela nova (botão "Novo" na barra de projeto, pergunta 40 ou 80
  colunas): 40 é o padrão do MSX1; 80 precisa de MSX2+. Cada tela grava sua própria largura; trocar a
  largura de uma tela já em edição não é possível neste editor (crie uma tela nova).
- **Fonte** — combo "Fonte:" no canto superior direito: **Padrão** usa o alfabeto embutido do MSX, ou
  escolha qualquer alfabeto já cadastrado no banco do projeto (**Criar → Alfabeto Graphos III...**,
  aparece na lista como `#N`). A fonte escolhida só afeta a **prévia** no canvas e, se não-padrão, gera
  um carregador de fonte junto do código (ver abaixo) — o texto em si não depende do bitmap da fonte
  pra funcionar certo.
- **Tinta / Fundo** — duas paletas de 16 cores do MSX1 (mesma paleta dos demais editores gráficos desta
  IDE), aplicadas à tela inteira, não célula por célula.
- **Cor 2 (Tinta2/Fundo2) e Pisca-pisca** — **só tem efeito em telas de 80 colunas**: o MSX2+ tem um
  recurso real de hardware (modo T2 do VDP) que permite um SEGUNDO par de tinta/fundo por caractere,
  marcado com a ferramenta **Atributo** (ver abaixo). Duas paletas extras "Cor 2" escolhem essa segunda
  cor; dois campos "Normal"/"Cor 2" (0-15) controlam quanto tempo cada fase fica visível (cada unidade
  ≈ 1/6 segundo, até 2.5s por fase) — **deixando "Normal" em 0, as células marcadas ficam travadas
  permanentemente na Cor 2, sem piscar**, dando efetivamente 2 cores de texto fixas na tela (coisa que
  40 colunas não tem). Esses controles ficam desabilitados automaticamente numa tela de 40 colunas.
- **Caractere atual** — campo de 1 caractere ao lado da paleta: digite qualquer letra/símbolo ali pra
  usar como "caractere de estampar" nas ferramentas Bloco e Borracha (a ferramenta Caractere também
  atualiza este campo quando você escolhe um glifo na grade dela).

### Ferramentas

Sete abas, uma por ferramenta:

- **Texto** — digite numa caixa de texto e clique no canvas: o texto é posicionado horizontalmente a
  partir da célula clicada (corta se passar do fim da linha, sem quebra automática).
- **Caractere** — a mesma grade de 159 caracteres especiais de **Inserir → Caractere Especial...**
  (acentos, gregas, box-drawing, naipes/carinhas) embutida na aba: clique num caractere pra escolher,
  clique ou arraste no canvas pra estampar.
- **Quadro** — dois cliques (cantos opostos) desenham uma moldura com linhas simples. Se a nova borda
  encostar num quadro já desenhado, a junção vira automaticamente um T ou uma cruz, em vez de sobrepor
  as linhas de qualquer jeito. Botão direito do mouse cancela uma marcação pendente (primeiro clique já
  feito, aguardando o segundo).
- **Sombra** — dois cliques (cantos opostos, tipicamente o mesmo retângulo de um quadro já desenhado)
  estampam uma faixa de sombra deslocada uma célula pra baixo e pra direita, ao longo das bordas direita
  e inferior — o efeito clássico de "sombra" de editor de tela ANSI.
- **Bloco** — dois cliques (cantos opostos) preenchem o retângulo inteiro com o "caractere atual" (campo
  ao lado da paleta, ou escolhido na aba Caractere). Útil pra texturas, fundos ou apagar uma área maior
  de uma vez só.
- **Borracha** — clique ou arraste no canvas apaga (estampa espaço).
- **Atributo** — clique ou arraste liga, botão direito (clique ou arraste) desliga o uso da Cor 2 numa
  célula, sem mexer no caractere que já está lá — funciona como uma "camada" independente, aplicável
  depois de já ter escrito o texto/desenhado o quadro. **Só tem efeito em telas de 80 colunas.** O
  canvas mostra uma prévia estática de "como ficaria a Cor 2" nas células marcadas (o editor não anima
  o pisca-pisca de verdade durante a edição, só no código gerado).

### Gerar código e injetar no editor

Os botões **Injetar no cursor**/**Copiar** (rodapé da janela) montam o código na hora, cada vez que são
clicados — não precisa de um botão "Gerar" separado. O código sempre inclui `SCREEN 0`, `WIDTH` (a
largura da tela), `COLOR tinta,fundo` e um `LOCATE`+`PRINT` por linha não-vazia da tela (linhas
totalmente em branco não geram `PRINT` nenhum). Se uma fonte customizada (não-padrão) estiver escolhida,
um carregador `DATA`+`VPOKE` é adicionado, carregando os 2048 bytes da fonte na posição certa da memória
de vídeo (o endereço muda conforme a largura — o modo de 80 colunas usa parte da memória padrão pra
outra coisa, ver abaixo). Se alguma célula estiver marcada com o atributo de Cor 2 (só em 80 colunas), o
código também inclui `VDP(13)`/`VDP(14)` (cor 2 e duração do pisca-pisca) e o carregador da tabela que
diz ao MSX quais células usam esse recurso.

Os caracteres especiais (acentos, box-drawing etc.) entram no código como o próprio símbolo Unicode —
a opção **Traduzir caracteres Unicode** (`-tr`, ver [Telas de configuração](#telas-de-configuração))
converte pro código nativo MSX automaticamente ao tokenizar, exatamente como qualquer outro texto
digitado com esses símbolos no editor (ver [Inserir → Caractere Especial](#inserir--caractere-especial)).

### Barra de projeto

Mesmo padrão dos demais editores gráficos desta IDE: número da tela, navegação
(primeiro/anterior/próximo/último), campo de tag (até 16 caracteres), **Novo** (pergunta a largura,
numera automaticamente, começa em branco) e **Registrar** (grava a tela atual no projeto). Trocar de
tela ou criar uma nova sem ter registrado avisa antes de descartar as alterações pendentes.

## Editor de tela SCREEN 1

Atalho: `Ctrl+Shift+1`.

Menu **Criar → Screen 1...** abre um editor gráfico de telas de texto do modo **SCREEN 1** do MSX,
mesmo espírito do editor SCREEN 0 acima — mas com a diferença real de cor do hardware SCREEN 1: em vez
de uma única cor de tinta/fundo pra tela inteira, o SCREEN 1 tem uma **Color Table** de 32 entradas,
cada uma com seu próprio par tinta/fundo, cobrindo um **grupo de 8 códigos de caractere** (código 0-7
usam a mesma cor, 8-15 usam outra, e assim por diante — 32 grupos × 8 códigos = 256). A grade de tela é
fixa em 32×24 células (o SCREEN 1 não tem WIDTH configurável como o SCREEN 0).

### Fonte e a tabela ASCII do alfabeto (cor por octeto)

- **Fonte** — combo "Fonte:" no canto superior direito, mesmo mecanismo do editor SCREEN 0: **Padrão**
  usa o alfabeto embutido do MSX, ou escolha qualquer alfabeto já cadastrado no banco do projeto
  (**Criar → Alfabeto Graphos III...**).
- **Tabela ASCII do alfabeto** — grade de 256 células abaixo das paletas, mostrando o **bitmap real** de
  cada um dos 256 códigos da fonte escolhida. O fundo de cada célula já aparece pintado na cor do
  **octeto** (grupo de 8) daquele código — é aqui que a colorização acontece: clique numa célula pra
  escolher o "byte atual" (usado pelas ferramentas Caractere e Bloco) e as duas paletas **Tinta do
  octeto**/**Fundo do octeto** ao lado mudam a cor dos 8 códigos daquele grupo (não da tela inteira) —
  a mudança aparece imediatamente tanto na própria tabela quanto no canvas, em qualquer célula da tela
  que já use um código daquele grupo.
- **Byte atual** — campo de 1 caractere acima da tabela: digite qualquer letra/símbolo ASCII simples ali
  pra escolher o byte (equivalente a clicar a célula correspondente na tabela); o texto ao lado mostra o
  número do byte, seu octeto e a faixa de códigos daquele grupo.

### Ferramentas

Seis abas, uma por ferramenta (mesmas do editor SCREEN 0, sem "Atributo" — exclusiva do recurso de Cor
2/pisca-pisca do WIDTH 80 do SCREEN 0, que não existe aqui):

- **Texto** — digite numa caixa de texto e clique no canvas: o texto é posicionado horizontalmente a
  partir da célula clicada (corta se passar do fim da linha, sem quebra automática).
- **Caractere** — escolha o byte na tabela ASCII de 256 códigos (ou digite ASCII simples no campo acima
  dela), depois clique ou arraste no canvas pra estampar.
- **Quadro** — dois cliques (cantos opostos) desenham uma moldura com linhas simples, unindo
  automaticamente com quadros já existentes que a nova borda encoste (formando T/cruz na junção). Botão
  direito cancela uma marcação pendente.
- **Sombra** — dois cliques (cantos opostos, tipicamente o mesmo retângulo de um quadro já desenhado)
  estampam uma faixa de sombra deslocada uma célula pra baixo e pra direita, ao longo das bordas direita
  e inferior.
- **Bloco** — dois cliques (cantos opostos) preenchem o retângulo inteiro com o byte atual. Útil pra
  texturas, fundos ou apagar uma área maior de uma vez só.
- **Borracha** — clique ou arraste no canvas apaga (estampa espaço).

### Gerar código e injetar no editor

Os botões **Injetar no cursor**/**Copiar** montam o código na hora. O código sempre inclui `SCREEN 1` e
um carregador `DATA`+`VPOKE` da Tabela de Cores (32 bytes, um por octeto, endereço padrão `&H2000`) —
esse bloco sempre aparece, mesmo sem nenhuma cor customizada, porque é ele que garante que a tela use
exatamente as cores configuradas em cada octeto. Se uma fonte customizada (não-padrão) estiver
escolhida, um segundo carregador `DATA`+`VPOKE` copia os 2048 bytes da fonte pra Pattern Generator Table
(`&H0000`). Por fim, um `LOCATE`+`PRINT` por linha não-vazia da tela (linhas totalmente em branco não
geram `PRINT` nenhum).

Diferente do editor SCREEN 0, o texto gerado aqui não depende da tradução `-tr` — cada célula já é um
byte MSX bruto, então o código sai como uma mistura de texto literal entre aspas e `CHR$(n)` pros bytes
fora do intervalo imprimível simples (a mesma técnica que o resto do pipeline usa pra caracteres
especiais, só que calculada direto pelo editor em vez de esperar a tokenização).

### Barra de projeto

Mesmo padrão dos demais editores gráficos desta IDE: número da tela, navegação
(primeiro/anterior/próximo/último), campo de tag (até 16 caracteres), **Novo** (numera automaticamente,
começa em branco) e **Registrar** (grava a tela atual no projeto). Trocar de tela ou criar uma nova sem
ter registrado avisa antes de descartar as alterações pendentes.

## Editor de tela SCREEN 1+2

Menu **Criar → Screen 1+2...** abre a versão mais completa (e mais complexa) desta família de editores:
mesma grade de tela 32×24 e mesmas ferramentas do editor SCREEN 1 acima, mas gerando **SCREEN 2**
(Graphics II) de verdade, que tem dois recursos de cor que o SCREEN 1 não tem.

### 3 alfabetos, um por terço da tela

O SCREEN 2 real divide a Pattern/Color Table em **3 "terços"** de 2048 bytes cada, escolhidos por qual
terço de LINHAS DE TELA uma célula está (linhas 0-7 = terço 1, 8-15 = terço 2, 16-23 = terço 3). Por
isso a coluna direita tem **3 combos de fonte** ("Fonte T1"/"T2"/"T3"), um por terço, todos começando em
**Padrão** mas trocáveis independentemente uns dos outros.

A **tabela ASCII** (grade de 256 células) mostra 1 terço por vez — o seletor **Terço 1 (0-7)/Terço 2
(8-15)/Terço 3 (16-23)** logo acima da grade escolhe qual terço está sendo visualizado/editado ali,
deixando claro de qual terço é cada célula mostrada. Importante: esse seletor só afeta o que a TABELA
mostra — no canvas, cada célula da tela sempre usa o alfabeto e a cor do seu PRÓPRIO terço real (a linha
onde ela está), não o terço selecionado na tabela. Pra facilitar, esse seletor **acompanha sozinho**
qualquer clique ou arraste no canvas: ao tocar uma linha de um terço diferente, o rádio muda, e a tabela
ASCII/o texto do byte atual atualizam pra mostrar exatamente o terço que você acabou de tocar — assim o
que a tabela mostra nunca fica "atrasado" em relação ao que você está editando na tela. O canvas também
desenha uma linha-guia preto+branco nos limites de cada terço (linhas de tela 8 e 16), sempre visível
não importa a cor do que está desenhado ali.

### Cor por linha de scanline (o modo mais complexo)

Diferente do SCREEN 1 (cor por grupo de 8 códigos), a Color Table real do SCREEN 2 guarda uma cor de
tinta e uma de fundo **para CADA UMA DAS 8 LINHAS de cada glifo** — é o "color clash" de verdade do
hardware: toda vez que o mesmo código de caractere aparece no mesmo terço, ele usa exatamente as mesmas
8 cores por linha, não importa em que posição da tela ele esteja.

- **Byte atual** — mesmo mecanismo do SCREEN 1 (campo de texto ou clique na tabela ASCII).
- **Cores do caractere...** — abre uma janela separada com o glifo do byte atual bem ampliado e 8
  linhas, cada uma com sua própria paleta de Tinta e de Fundo (16 cores MSX1). Clicar numa cor aplica na
  hora — não precisa de um botão "Aplicar" separado.
- **Cores em bloco...** — clique o código inicial e o código final direto na tabela ASCII abaixo (em
  qualquer ordem) e abre a MESMA janela de cores, mas aplicando o padrão de 8 cores escolhido a TODOS os
  códigos do intervalo de uma vez (por exemplo, colorir A-Z inteiro com o mesmo esquema). Enquanto você
  escolhe, os códigos já marcados ganham uma moldura ciano sutil na tabela; botão direito na tabela
  cancela a escolha. Útil pra colorir uma faixa grande sem repetir o processo código por código.
- **Copiar cores** / **Colar cores** — copia as 8 cores por linha do byte atual pra um clipboard interno
  do editor; colar aplica esse padrão a outro byte atual escolhido depois. Rápido pra reaproveitar um
  esquema de cores já pronto em outro caractere.
- **Resetar caractere** / **Resetar bloco...** / **Resetar TODOS os caracteres do terço** — voltam
  Tinta/Fundo pro padrão (letra branca em fundo preto) no byte atual, num intervalo escolhido na tabela
  ASCII do mesmo jeito que "Cores em bloco...", ou nos 256 códigos do terço selecionado de uma vez (esse
  último pede confirmação, pois não pode ser desfeito).

Todas as edições de cor valem só para o **terço selecionado** na tabela ASCII no momento.

### Ferramentas

Mesmas 6 ferramentas do editor SCREEN 1 (Texto, Caractere, Quadro, Sombra, Bloco, Borracha) — ver
descrição na seção anterior. A única diferença de comportamento: a ferramenta **Caractere** estampa o
byte atual normalmente, mas a cor final exibida depende de qual TERÇO REAL a célula clicada está (não do
terço selecionado na tabela ASCII).

### Gerar código e injetar no editor

Os botões **Injetar no cursor**/**Copiar** montam o código na hora. O código sempre inclui `SCREEN 2` e,
para cada um dos 3 terços, um carregador `DATA`+`VPOKE` da Tabela de Cores completa (2048 bytes/terço,
endereços `&H2000`/`&H2800`/`&H3000`) — esse bloco sempre aparece, incondicionalmente, garantindo que a
tela use exatamente as cores configuradas em cada linha de cada código. Só os terços com uma fonte
customizada (não-Padrão) ganham também um carregador da Pattern Generator Table daquele terço. Por fim,
um `LOCATE`+`PRINT` por linha não-vazia da tela, igual ao editor SCREEN 1.

### Barra de projeto

Mesmo padrão dos demais editores gráficos desta IDE: número da tela, navegação
(primeiro/anterior/próximo/último), campo de tag (até 16 caracteres), **Novo** (numera automaticamente,
começa em branco, os 3 alfabetos voltam a Padrão) e **Registrar** (grava a tela atual no projeto). Trocar
de tela ou criar uma nova sem ter registrado avisa antes de descartar as alterações pendentes.

---

## Mamute Assembler

> O **Mamute Assembler** já monta código Z80 de verdade (comando `EDIT`/`A`, reaproveitando o mesmo
> motor nativo do menu **Executar → Montar Assembly**), além do "monitor" de memória/disco original
> (`PAGE`, `DM`, `ZAP` e o resto do conjunto abaixo). Ele continua sendo uma ferramenta separada dos
> assemblers já existentes (nativo via menu, N80, asMSX) — um jeito alternativo, no estilo dos
> montadores de linha de comando dos anos 80, de escrever e montar Z80 dentro da mesma janela onde
> também dá pra inspecionar/editar memória e disco. Comandos de execução de programa (`G`) e
> carregamento de assemblado por fita (`R`) ainda só validam sintaxe — ficam pra uma fase futura.

`Executar → Mamute Assembler...` abre uma janela "monitor" — inspirada nos montadores de linha de
comando dos computadores de 8 bits dos anos 80 (o **MegaAssembler** foi a referência direta pedida pelo
usuário). Diferente do [Editor Hexa](#editor-hexa) e dos assemblers já existentes (nativo, N80, asMSX),
não é uma tela de campos/botões: um prompt `MON>` aceita comandos digitados, um de cada vez, com o
resultado aparecendo logo acima, igual um terminal de verdade. Fundo preto, texto monoespaçado verde —
visual deliberadamente fora do tema claro do resto da IDE; fonte (nome/tamanho/negrito) configurável em
[Configurar → Mamute Assembler...](#configurar--mamute-assembler) logo abaixo.

**Setas Cima/Baixo** no campo `MON>` navegam pelo histórico de comandos já digitados (Cima = mais
recente, Baixo = volta pro presente) — esse histórico é salvo no arquivo de projeto atual (ou num
projeto padrão, se nenhum estiver aberto) e continua disponível na próxima vez que a janela abrir.

A ferramenta simula o **sistema de slots do MSX de verdade**: 4 slots (numerados 0 a 3), cada um com 4
páginas de 16KB — os mesmos endereços do hardware real:

| Página | Endereços     |
|--------|---------------|
| 0      | `0000`-`3FFF` |
| 1      | `4000`-`7FFF` |
| 2      | `8000`-`BFFF` |
| 3      | `C000`-`FFFF` |

16 blocos de memória ao todo (256KB). Por padrão todos começam em branco; **`Configurar → Mamute
Assembler...`** já permite carregar um arquivo real (BIOS, BASIC, uma ROM) em qualquer célula — ver a
seção logo abaixo.

Ferramenta nova, em construção: os comandos existentes até agora estão listados abaixo. Novos comandos
entram aos poucos, ao longo de futuras versões — consulte **Ajuda → Mamute Assembler...** pra ver sempre
a lista atualizada (o conteúdo dessa janela cresce junto com a própria ferramenta).

### Configurar → Mamute Assembler...

Define o que existe **fisicamente** em cada um dos 16 blocos de memória (4 slots × 4 páginas) — uma
lista com uma linha por bloco (Slot/Página/Endereço/Tipo/Arquivo). Selecione uma linha pra editar:

- **Tipo** — `Vazio` (padrão), `RAM`, `ROM` ou `BASIC` (mais tipos de cartucho entram depois).
- **Arquivo** — só habilitado quando o Tipo é `ROM` ou `BASIC`: caminho de um arquivo pra carregar
  naquele bloco (ex.: `BIOS.ROM` no Slot 0/Página 0). O carregamento de verdade (ler o arquivo pros
  256KB simulados) ainda não está implementado — por enquanto só guarda o caminho configurado.

Exemplo de configuração típica de um MSX1: `ROM` no Slot 0/Página 0 (BIOS), `BASIC` no Slot 0/Página 1,
`RAM` nas páginas do Slot 3. **Salvar** grava em `mamute_settings.json`; **Cancelar** descarta as
edições.

**Arquivo de BIOS+BASIC combinado (32KB)**: em muitos MSX reais a BIOS e o BASIC vêm num único arquivo
de ROM de 32KB (16KB de cada, concatenados). Ao escolher um arquivo assim (exatamente 32KB) pra uma
célula `ROM` na **Página 0** (a posição convencional da BIOS), a tela pergunta se é BIOS+BASIC
combinados:

- **Sim** — a Página 0 fica com os primeiros 16KB do arquivo (BIOS); a Página 1 do mesmo slot passa
  pra `BASIC` automaticamente e fica com os últimos 16KB — o mesmo arquivo, repetido nos dois pontos,
  cada um lendo a metade certa (a lista mostra **"(últimos 16KB)"** ao lado do caminho nessa segunda
  linha). Você continua livre pra trocar o arquivo da Página 1 na mão depois, se quiser usar um BASIC
  diferente.
- **Não** (ou o arquivo escolhido não tem 32KB) — funciona como antes: só a célula selecionada recebe
  o arquivo.

Mais abaixo, **"Fonte do terminal"** ajusta a aparência da janela do monitor (`Executar → Mamute
Assembler...`) — combo com as fontes monoespaçadas instaladas (mesma lista de `Configurar →
Editor...`), campo de tamanho e checkbox **Negrito**. Só tem efeito na próxima vez que o monitor for
aberto.

**"Notas SUPER-X padrão"** — caminho de um arquivo de notas (comandos `XIM`/`XIC`/`XIL`/`XIS`/`XIR`,
abaixo) que é carregado automaticamente toda vez que o Mamute Assembler abre, sem precisar digitar `XIL`
manualmente. Vazio (padrão) = não carrega nada. O botão **"..."** abre um diálogo já sugerindo o arquivo
traduzido (`SUPER-X-PT.notas`) que o próprio Paleobasic já traz pronto com as 471 notas do arquivo de
exemplo original do SUPER-X, traduzidas — **se você escolher justamente esse arquivo, ele é
automaticamente marcado como somente-leitura** e uma cópia editável (`SUPER-X-SHADOW.notas`) é criada e
usada como padrão no lugar, pra nunca sobrescrever o original sem querer.

### Comandos disponíveis

**Todo endereço/setor digitado em qualquer comando do Mamute Assembler é hexadecimal** — o padrão de
entrada da ferramenta inteira, incluindo dentro do editor `EDIT`.

- **`BA`** ou **`QUIT`** — encerra a janela do Mamute Assembler (equivalente a fechar pelo X). Não
  diferencia maiúsculas de minúsculas. Sem argumentos.
- **`PAGE`** — mostra ou troca o **mapeamento ativo agora mesmo** (qual slot está comutado em cada uma
  das 4 páginas que o Z80 enxerga) — diferente da configuração física acima, que só diz o que EXISTE em
  cada slot. Três formas:
  - `PAGE` sozinho — coloca as 4 páginas no slot marcado como RAM (o primeiro slot, varrendo 0 a 3, com
    RAM configurada em alguma página).
  - `PAGE ?` — só mostra o mapeamento ativo, sem mudar nada.
  - `PAGE X, Y, Z, W` — troca o mapeamento: página 0 vai pro slot `X`, página 1 pro slot `Y`, página 2
    pro slot `Z`, página 3 pro slot `W` (cada um de 0 a 3, sempre os 4 juntos). Exemplo: `PAGE 2, 2, 2,
    2` coloca tudo no slot 2; `PAGE 0, 1, 3, 3` coloca a página 0 no slot 0, a página 1 no slot 1, e as
    páginas 2 e 3 no slot 3.

  O mapeamento ativo é recalculado sozinho ("estado de boot") toda vez que a janela abre, a partir da
  configuração salva em `Configurar → Mamute Assembler...`. É esse mapeamento que a maioria dos comandos
  abaixo usa pra decidir de qual bloco de memória ler/escrever em cada endereço.
- **`DM <endereço>[,<deslocamento>]`** — despejo/edição de memória numa janela à parte. Ver [DM -
  navegação e edição](#dm---navegação-e-edição).
- **`M [<endereço>]`** / **`S [<endereço>]`** — edição rápida de memória, digitando os 2 dígitos hexa de
  cada byte direto (sem abrir campo). `S` usa um teclado numérico configurável em vez de `0-9`/`A-F`
  fixos. Ver [M e S](#m-e-s---edição-rápida-de-memória).
- **`ZAP <setor>[,<deslocamento>]`** — edição de setores crus de uma imagem `.dsk`. Ver [ZAP](#zap---editor-de-setores-de-disco).
- **`SCR <endinic>,<dx>,<dy>[,<modo>]`** — mostra a memória como uma tela gráfica 256×192, útil pra
  visualizar fontes/sprites. Ver [SCR](#scr---display-gráfico-da-memória).
- **`SH [<endereço>],<byte>[,<byte>...]`** ou **`SH [<endereço>],'<texto>`** — busca bytes (com curinga)
  ou texto na memória. Ver [SH](#sh---busca-de-bytes-ou-texto).
- **`MS <endereço>,[<deslocamento>],'<texto>`** — grava uma string na memória. Ver [MS](#ms---grava-uma-string-na-memória).
- **`LOAD`** / **`SAVE`** — carrega/grava um bloco de memória num arquivo (binário BLOAD, `.rom`), com
  janela própria. Ver [LOAD e SAVE](#load-e-save).
- **`C <modo>`** — escolhe o modo de exibição usado por `D`/`P`/`V`. **`D <endinic>[,<endfim>]`** —
  despejo formatado no log. **`P <endinic>[,<endfim>]`** — igual ao `D`, mas gera PDF. **`V
  <endinic>[,<endfim>]`** — igual ao `P`, mas lê da VRAM simulada. Ver [C, D, P e
  V](#c-d-p-e-v---despejo-formatado-de-memória).
- **`T <endinic>,<endfim>,<enddest>`** — copia um bloco de memória. **`F <endinic>,<endfim>,<byte>`** —
  preenche um bloco com um byte repetido. Ver [T e F](#t-e-f---transferir-e-preencher-blocos).
- **`G <endinic>[,<brkpnt1>[,<brkpnt2>]]`** — ainda só valida sintaxe (execução de programas fica pra
  uma fase futura). **`X [<reg>]`** — mostra/edita os registradores do Z80 simulado. Ver [G e
  X](#g-e-x---execução-e-registradores).
- **`R [<offset>]`** — ainda só valida sintaxe (carregar um assemblado gravado por fita fica pra uma
  fase futura). **`L [<endinic>[,<endfim>]]`** — disassembla a memória no log. **`LP
  [<endinic>[,<endfim>]]`** — igual ao `L`, mas gera PDF. Ver [R, L e
  LP](#r-l-e-lp---referência-de-fita-e-disassembler).
- **`EDIT`** — abre o editor de linhas do programa-fonte Z80 (estilo ZX-81), com o comando **`A`**
  (montar/assemblar) dentro dele. Ver [EDIT](#edit---editor-do-programa-fonte-z80) e [A - montar o
  programa](#a---montar-o-programa).

### DM - navegação e edição

`DM <endereço>[,<deslocamento>]` abre uma janela separada mostrando **128 bytes** (16 linhas de 8) a
partir do `<endereço>` informado (hexadecimal, obrigatório), em hexa e ASCII lado a lado — cada linha
tem o endereço na primeira coluna, os 8 bytes em hexa nas colunas seguintes, e os 8 caracteres
correspondentes como um bloco no final. Caractere que não dá pra imprimir aparece como `.`.

Abaixo da grade, duas linhas de status sempre visíveis: **Endereço:** (o endereço da primeira linha da
grade) e **Desloc.:** (o deslocamento ASCII ativo).

**Deslocamento (`<deslocamento>`, opcional, hexadecimal com sinal `+`/`-`, de `-7F` a `80`)**: não
muda o byte na memória — só a forma como o bloco de texto interpreta/edita cada byte, somando o
deslocamento ao valor cru (módulo 256) antes de decidir o caractere. Útil pra "descriptografar" texto
guardado com um deslocamento simples tipo César. Exemplo: `DM 4000,-20` mostra o conteúdo de `4000`
com um deslocamento de `-20h` aplicado só na leitura do texto.

**Navegando o cursor** (ambos os métodos abaixo funcionam, e clicar direto numa célula da grade também
move o cursor pra lá):

| Ação | Mouse | Teclado |
|---|---|---|
| Mover uma célula | 4 setas pequenas na tela | Setas do cursor |
| Alternar bloco hexa ↔ texto | — | `TAB` |
| Pular ±128 bytes (endereço base) | 2 setas maiores (`<<`/`>>`) | `PgUp`/`PgDn` |
| Ajustar o deslocamento em 1 | Botões `+`/`-` | Tecla `+`/`-` do teclado numérico |

**Editando um byte**: `RETURN` abre um campo de entrada pro bloco onde o cursor está (mostra o valor
atual, pronto pra substituir); `RETURN` de novo confirma o que foi digitado. `ESC` cancela a edição em
andamento sem gravar nada — ou, se não havia edição em curso, fecha a janela do DM (volta pro `MON>`).

- **Bloco hexa**: digite 1-2 dígitos hexadecimais — vira o byte cru na célula do cursor.
- **Bloco texto**: digite um texto qualquer (não só 1 caractere) — cada caractere digitado vira um byte
  (revertendo o deslocamento ativo, se houver), escrito a partir da posição do cursor; o cursor avança
  sozinho conforme você digita.

**Importante**: a escrita só tem efeito em células mapeadas como **RAM** no momento (ver `PAGE` acima e
`Configurar → Mamute Assembler...`) — células ROM, BASIC ou Vazio são somente-leitura, igual num MSX de
verdade (fisicamente não há o que escrever ali). Tentar editar uma célula assim não dá erro nem trava —
só não muda nada.

### M e S - edição rápida de memória

`M [<endereço>]` abre a **mesma grade de 128 bytes** (16 linhas de 8, hexa+ASCII) e a **mesma
navegação** do `DM` (setas, `PgUp`/`PgDn`, `TAB`, botões, `+`/`-` pro deslocamento da interpretação
ASCII exibida) — a diferença é como um byte é editado.

`<endereço>` é opcional: se não for informado, a janela reabre exatamente onde ficou da última vez (só
funciona depois que `M` já abriu pelo menos uma vez nesta sessão).

**Editar um byte** — com o cursor no bloco hexa, digite dois dígitos hexa (`0-9`, `A-F`) direto, sem
abrir campo de edição nenhum: o primeiro dígito fica mostrado com um `_` no lugar do segundo (ex.: `3_`)
esperando o próximo; o segundo confirma o byte inteiro (`3F`) e avança o cursor sozinho pro próximo
endereço. `ESC` cancela o primeiro dígito se ainda estiver pendente, ou sai da janela se não houver nada
pendente. `RETURN` sempre sai da janela.

O bloco de texto (ASCII) é **somente leitura** neste comando — `TAB` ainda alterna o destaque visual
entre hexa/texto, mas não abre edição no bloco de texto.

**`S [<endereço>]`** é **igual ao `M`** (mesma grade, mesma navegação, mesmo jeito de editar um byte
digitando dois dígitos hexa direto) — a única diferença é **quais teclas do teclado representam cada
dígito hexa**. Em vez de `0-9`/`A-F` fixos, usa um teclado numérico reduzido configurável em
`Configurar → Mamute Assembler...`, por padrão:

```
1 2 3 4        1 2 3 4
Q W E R   =>   5 6 7 8
A S D F        9 A B C
Z X C V        D E F 0
```

(o mesmo layout clássico de teclado numérico usado em vários emuladores — as 4 fileiras da esquerda do
teclado QWERTY). Qualquer uma das 16 teclas pode ser trocada individualmente na tela de configuração
para qualquer letra ou dígito. `S` guarda seu próprio "último endereço", separado do `M`.

### ZAP - editor de setores de disco

`ZAP <setor inicial>[,<deslocamento>]` é muito parecido com o `DM`, mas em vez de mostrar a memória
simulada do MSX, ele edita **setores de uma imagem de disco `.dsk` de verdade**, direto, sem passar pela
estrutura do sistema de arquivos FAT12 — como um editor de setor de disquete dos anos 80.

Ao digitar o comando, uma janela normal de **escolher arquivo** aparece primeiro, pedindo a imagem `.dsk`
que você quer editar. Cancelar essa escolha cancela o comando inteiro (a janela do ZAP não chega a abrir).
A prioridade é editar discos **FAT12 de 720KB**, mas imagens de **360KB** e **180KB** também funcionam —
face simples ou dupla, densidade simples ou dupla, 5¼" ou 3½", tanto faz: o ZAP não interpreta a estrutura
do disco, só lê e escreve bytes crus por posição.

`<setor inicial>` é o número do setor (hexadecimal, obrigatório — setor `0` é o boot sector) a partir de
onde a grade de 128 bytes começa. `<deslocamento>` funciona exatamente como no `DM` (hexadecimal com
sinal, `-7F` a `80`, só afeta a interpretação/edição do bloco de texto).

**A navegação é idêntica à do `DM`** — mesmas 4 setas pequenas/setas do cursor pra mover a célula, `TAB`
pra alternar hexa↔texto, as 2 setas maiores/`PgUp`/`PgDn` pra pular ±128 bytes, botões `+`/`-` (ou as
teclas `+`/`-`) pra ajustar o deslocamento, `RETURN` pra abrir/confirmar a edição de um byte, `ESC` pra
cancelar a edição em andamento. A única diferença visível na grade: o rótulo de cada linha mostra o
deslocamento **dentro do setor** (`000` a `1F8`) em vez de um endereço de CPU, e as linhas de status
mostram **Setor:** e **Byte:** em vez de **Endereço:**.

**Diferença importante em relação ao `DM`: salvar é um passo separado e explícito.** Editar um byte no
ZAP só muda uma cópia em memória — ele **não** grava no arquivo `.dsk` sozinho. Para gravar de verdade no
disco, use uma das duas opções, que gravam **só o setor onde está o cursor** (não o disco inteiro):

- **`Ctrl+S`** (atalho de teclado), ou
- o botão amarelo **"SALVAR SETOR"**, ao lado dos outros botões de navegação.

Enquanto houver alterações não salvas, o título da janela do ZAP ganha um `*` no final. Se você tentar
fechar a janela (`ESC` fora de uma edição em andamento, ou pelo X) com alterações não salvas, o ZAP pede
confirmação antes de descartá-las — igual o restante da IDE (ver o Gerenciador de Discos, por exemplo).

**Também importante: no ZAP, qualquer byte do disco pode ser editado** — diferente do `DM`, onde células
ROM/BASIC/Vazio são somente-leitura. Não existe conceito de "só RAM é editável" numa imagem de disco, então
a proteção de escrita do `DM` não se aplica aqui.

### SCR - display gráfico da memória

`SCR <endinic>,<dx>,<dy>[,<modo>]` mostra uma tela **fixa de 256×192 pixels** (32×24 caracteres 8×8, a
mesma resolução de um SCREEN 2/1 real do MSX) preenchida com a memória a partir de um endereço, cada
caractere formado por 8 bytes/8 pixels (1 bit = 1 pixel) — exatamente como a Pattern Generator Table do
SCREEN 1/2 ou a Sprite Pattern Table de um MSX real. Útil pra visualizar fontes de caracteres e sprites
direto na memória simulada.

Todos os números são hexa. `<endinic>` (obrigatório) é o endereço do primeiro caractere. A tela em si é
sempre 256×192 — `<dx>`/`<dy>` (obrigatórios, ≥1) não mudam esse tamanho, eles definem o "azulejo"
(bloco de `dx`×`dy` caracteres) usado pra ladrilhar a tela inteira, da esquerda pra direita e de cima
pra baixo. `<modo>` (opcional, `0` ou `1`, padrão `0`) define a ordem em que os blocos de 8 bytes são
lidos dentro de cada azulejo: **`0`** (horizontal) lê linha por linha dentro do azulejo; **`1`**
(vertical) lê coluna por coluna, a mesma ordem real de armazenamento de sprites do MSX.

Exemplo pra ver a tabela de caracteres ASCII de uma ROM de fonte carregada em `Configurar → Mamute
Assembler...` (endereço `1BBF` é onde a maioria das BIOS de MSX guarda o início da Pattern Generator
Table; `<dx>`=`<dy>`=`1` ladrilha a tela toda com 1 caractere por azulejo, leitura sequencial simples):

```
MON>SCR 1BBF,1,1
```

**Navegação** (fora do modo de edição):

| Tecla | Efeito |
|---|---|
| Setas esquerda/direita | Deslocam o endereço base **1 byte** (ajuste fino) |
| Setas cima/baixo | Deslocam o endereço base **1 azulejo inteiro** (`dx`×`dy`×8 bytes) |
| `TAB` (ou botão **MOL**) | Liga/desliga o contorno de uma **moldura** de edição, tamanho fixo 2×2 caracteres (16×16 pixels), sempre no canto superior esquerdo |
| `E` (ou botão **END**) | Mostra/oculta o rótulo com o endereço base atual |
| `ENTER` | Entra no modo de edição, ampliando os 16×16 pixels da moldura num painel à parte |
| `ESC` | Encerra o comando (fecha a janela) |

Não há tecla pra mover a moldura pela tela — a única forma de trazer outro pedaço da memória pra dentro
dela é rolar o endereço base com as setas.

**Modo de edição** (`ENTER`) — só afeta os 16×16 pixels da moldura, ampliados num painel à direita com
um cursor de contorno vermelho:

| Tecla | Efeito |
|---|---|
| Setas | Movem o cursor de pixel dentro da moldura |
| `ESPAÇO` | Inverte (acende/apaga) o pixel sob o cursor |
| `I` (ou botão **INV**) | Inverte (XOR) os 16×16 pixels inteiros da moldura de uma vez |
| `L` (ou botão **APG**) | Apaga (zera) esses mesmos 16×16 pixels de uma vez |
| `ENTER` | Sai do modo de edição (as alterações já foram gravadas, pixel a pixel) |
| `ESC` | Cancela TODAS as alterações feitas desde que entrou no modo de edição e sai |

**Se a moldura cair sobre uma célula que não seja RAM agora** (ROM/BASIC/Vazio, conforme `PAGE`), o
painel de edição mostra o conteúdo real normalmente e todas as teclas de edição continuam respondendo,
mas nada é gravado de verdade — um aviso amarelo "ROM - somente leitura (alterações não são gravadas)"
aparece abaixo da tela nesse caso.

### SH - busca de bytes ou texto

`SH` procura uma sequência de bytes exatos (com curingas opcionais) ou um texto (testando
automaticamente todos os deslocamentos possíveis) na memória simulada. Não abre janela nenhuma — o
resultado aparece direto no log do `MON>`.

**Modo bytes:**

```
MON>SH [<endereço>],<byte>[,<byte>...]
```

`<endereço>` (hexa) é onde começar a busca. Se for omitido (a vírgula continua ali, só o número antes
dela que falta — ex.: `SH ,2A,40`), a busca continua do endereço onde a **última** busca deste comando
achou algo, mais 1 — só funciona depois de um `SH` que já tenha achado algo nesta mesma sessão da
janela.

Cada `<byte>` é 1-2 dígitos hexa. **Deixar um `<byte>` vazio (vírgula dupla) vira curinga** — "esse byte
pode ser qualquer um". Exemplos:

```
MON>SH 4000,2A,40,0C
```

procura a sequência exata `2A 40 0C` a partir de `4000`;

```
MON>SH 4000,2A,,0C
```

procura 3 bytes onde o 1º é `2A`, o 2º pode ser qualquer coisa, e o 3º é `0C`.

**Modo texto:**

```
MON>SH [<endereço>],'<texto>
```

Um apostrofo seguido do texto (sem precisar fechar com outro apostrofo), 2+ caracteres. Diferente do
modo bytes, a busca de texto testa TODOS os deslocamentos possíveis (`-7F` a `80`, mesma faixa do
`DM`/`ZAP`) em cada posição candidata — acha tanto o texto puro (deslocamento `+00`) quanto texto
"cifrado" por um deslocamento fixo (truque comum em jogos antigos pra não deixar diálogo legível num
editor de disco cru). Exemplo:

```
MON>SH 3F41,'teste
```

**Resultado:** `ACHADO EM <endereço>` (modo bytes) ou `ACHADO EM <endereço> DESLOC <deslocamento>` (modo
texto, com sinal `+`/`-`), ou `NAO ENCONTRADO` se a busca varrer os 65536 endereços (com volta ao
início) sem achar nada.

### MS - grava uma string na memória

`MS` escreve um texto digitado, byte a byte, a partir de um endereço, com um deslocamento opcional. Não
abre janela nenhuma — só confirma no log do `MON>`.

```
MON>MS <endereço>,[<deslocamento>],'<texto>
```

`<endereço>` (obrigatório, hexa) é onde começa a gravação. `<deslocamento>` (opcional, hexa com sinal
`+`/`-`, `-7F` a `80`, mesma faixa do `DM`/`ZAP`/`SH`) é `0` se omitido. Um apostrofo seguido do texto
(sem precisar fechar com outro apostrofo) — qualquer vírgula dentro do texto NÃO quebra o comando, tudo
depois do apostrofo vira parte do texto.

Cada caractere é gravado como `(código do caractere - deslocamento) & FF` — a mesma fórmula usada pelo
bloco de texto do `DM` ao editar. Isso significa que o texto gravado com um deslocamento diferente de
zero fica "cifrado" nos bytes crus — só volta a aparecer legível se depois for lido (`DM`) ou procurado
(`SH`) com esse MESMO deslocamento. Exemplo:

```
MON>MS 9A15,20,'nome
```

grava a string `nome` a partir do endereço `9A15` com deslocamento `+20` — `DM 9A15,20` (ou `SH ,'nome`
após ajustar o deslocamento) mostraria `nome` de volta.

Escrita só tem efeito em células mapeadas como RAM agora (`PAGE`) — mesma regra do `DM`, ROM/BASIC/Vazio
são somente-leitura (recusa silenciosa, sem aviso separado).

### LOAD e SAVE

`LOAD` carrega um arquivo na memória simulada — totalmente interativo: não se digita nome de arquivo no
comando. Basta digitar `LOAD` sozinho:

```
MON>LOAD
```

Um nome de arquivo pode ser digitado depois do `LOAD` (`MON>LOAD alfabeto.alf`), mas ele não carrega
nada sozinho — só pré-preenche o campo de nome na janela de escolher arquivo e acrescenta a extensão
dele ao filtro padrão. O arquivo que de fato vai ser carregado é sempre o que for confirmado na janela
(cancelar a escolha cancela o comando inteiro, sem gravar nada).

Em seguida, sempre é perguntado em qual **Slot (0-3)** carregar — o slot que tiver RAM configurada é
sugerido como padrão, mas qualquer slot pode ser escolhido. O que acontece depois depende da extensão:

- **`.ROM`** (cartucho) — carregado a partir do endereço `4000` (Página 1). Se tiver mais de 16KB (até
  32KB), ocupa também a Página 2 (`8000`). Arquivos com mais de 32KB não são suportados.
- **Binário com cabeçalho BLOAD** (qualquer outra extensão, ex.: `.bin`) — se o arquivo começar com o
  cabeçalho real do BSAVE do MSX (byte `FE` seguido de endereço inicial/final/execução, 2 bytes cada),
  carrega automaticamente no endereço indicado pelo cabeçalho.
- **Binário sem cabeçalho** — se não começar com `FE`, pergunta o endereço inicial (hexa) antes de
  carregar.
- **`.CAS` ainda não é suportado** — mostra um erro e cancela, em vez de tentar interpretar errado.

Ao final, o resultado é mostrado no log: `CARREGADO NO SLOT <slot> EM <endereço> - TAMANHO <tamanho> -
FIM <endereço final>`.

`LOAD` grava direto na memória física do slot escolhido, independente do que o `PAGE` tem mapeado ativo
agora (simula "inserir um cartucho/carregar dado naquele slot", não escrever pela CPU). Também ajusta a
configuração física das páginas tocadas (RAM pro binário, ROM pro `.rom`) — mas só em memória, nunca
grava em `mamute_settings.json`; fechar e reabrir a janela volta pra configuração salva de antes.

`SAVE` é o inverso, também com janela própria:

```
MON>SAVE [<nome>][,<endinic>,<endfim>[,<endexec>]]
```

Tudo opcional — `SAVE` sozinho abre a janela em branco. `<nome>` sugere o campo Arquivo; se
`<endinic>`/`<endfim>` forem informados (sempre os dois juntos, `<endexec>` opcional separado — vazio
assume igual ao inicial), pré-preenchem os campos de endereço, mas a janela sempre abre pra revisar
antes de gravar — nada é salvo só por digitar o comando. Exemplo:

```
MON>SAVE rom.bin,4000,7FFF
```

**Campos da janela:**

- **Arquivo** — campo editável + botão "..." (Salvar Como do Windows).
- **Slot (0-3)** — de qual slot físico ler os bytes, sugerido a partir do mapeamento `PAGE` ativo na
  página do endereço inicial, sempre editável.
- **Endereço inicial / final** — o bloco a gravar (inclusive nos dois extremos).
- **Endereço de execução** — vai no cabeçalho; vazio usa o mesmo valor do inicial.
- **Formato** — `BIN` (cabeçalho real do BSAVE do MSX: `FE` + 3 endereços de 2 bytes) ou `ROM` (mesma
  ideia, com `AB` no lugar do `FE` — formato próprio deste simulador, não o cabeçalho real de 16 bytes
  de um cartucho MSX). Sugerido automaticamente a partir da extensão do arquivo, mas editável.
- **Salvar sem cabeçalho** — checkbox: grava só os bytes crus, ignorando o Formato escolhido.

Ao gravar, confirma no log: `SALVO "<arquivo>" - SLOT <slot> - <inicial>-<final> - TAMANHO <tamanho>`.
Igual o `LOAD`, lê direto do slot escolhido, sem passar pelo `PAGE`.

### C, D, P e V - despejo formatado de memória

`C <modo>` escolhe o modo de exibição que `D`, `P` e `V` vão usar — sozinho não mostra nada além da
confirmação, só guarda a escolha (dura enquanto a janela estiver aberta; fechar e reabrir volta pro modo
`0`):

- **`0`** — hexadecimal + ASCII, 4 bytes por linha.
- **`1`** — igual ao `0`, mas 16 bytes por linha (pra telas/impressoras de 80 colunas).
- **`2`** — só hexadecimal, 8 bytes por linha, com um checksum no final de cada linha (soma dos 8 bytes
  + o byte baixo do endereço inicial da linha, tudo módulo 256).
- **`3`** — igual ao `2`, mas o checksum é só a soma dos bytes, sem somar o endereço.

```
MON>C 1
MODO 1: HEXA+ASCII, 16 BYTES/LINHA
```

`D <endinic>[,<endfim>]` mostra um despejo formatado direto no log do `MON>`, conforme o modo escolhido
em `C`. Sem `<endfim>`, mostra só 16 bytes a partir de `<endinic>`; com os dois, mostra o intervalo
inteiro (inclusive) — `<endfim>` não pode ser menor que `<endinic>`, e nenhum dos dois passa de `FFFF`.

```
MON>D 4000,400F
```

`P <endinic>[,<endfim>]` é igual ao `D`, mas em vez de mandar o despejo pro log, gera uma listagem num
**PDF A4** (fonte Courier, cabeçalho com o intervalo/modo usado) e abre uma janela "Salvar como" no
final — simula "a impressora" (um driver de verdade pra impressora Epson FX-80 fica pra uma sessão
futura). Cancelar a janela não gera arquivo, só mostra `CANCELADO`.

`V <endinic>[,<endfim>]` é igual ao `P`, mas lê da **VRAM simulada** em vez da RAM/ROM — endereço plano,
sem `PAGE` nem banco algum (a VRAM real de um MSX nunca fica mapeada no espaço de endereços do Z80, é
acessada pelas portas do VDP). O tamanho de VRAM é configurado em `Configurar → Mamute Assembler...`:
**16KB** (MSX1), **128KB** ou **192KB** (MSX2/2+). `<endinic>`/`<endfim>` podem ter até 5 dígitos hexa e
são validados contra o tamanho configurado — passar do teto é erro de sintaxe, sem dar a volta. Ainda
não existe nenhum comando que escreva na VRAM simulada — ela começa sempre zerada.

### T e F - transferir e preencher blocos

`T <endinic>,<endfim>,<enddest>` copia um bloco de memória (RAM/ROM mapeada agora pelo `PAGE`) de um
intervalo de endereços pra outro:

```
MON>T 4000,7FFF,8000
```

copia o bloco de `4000` a `7FFF` para `8000` em diante. Se origem e destino se sobrepõem, a cópia é
feita na ordem certa pra não corromper dado ainda não lido (mesmo cuidado de um `memmove` de verdade).
`<endfim>` não pode ser menor que `<endinic>`, e o bloco copiado não pode passar de `FFFF` no destino.

`F <endinic>,<endfim>,<byte>` preenche um bloco inteiro com um único byte repetido:

```
MON>F 8000,C000,FF
```

preenche o bloco de `8000` a `C000` (inclusive) com `FF` em todo byte. Escrita silenciosa em células que
não sejam RAM, em ambos os comandos (mesma regra do `DM`/`MS`).

### G e X - execução e registradores

`G <endinic>[,<brkpnt1>[,<brkpnt2>]]` ainda **não executa nada** — por enquanto só valida a sintaxe e
confirma no log que o comando foi entendido. A execução de verdade de programas na memória simulada
(com breakpoints, registradores, etc.) fica pra uma fase futura.

`X [<reg>]` mostra ou edita os registradores do Z80 simulado. Sem argumento, mostra os 7 pares de
registrador de uma vez:

```
MON>X
AF=0000 BC=0000 DE=0000 HL=0000
IX=0000 IY=0000 SP=0000
```

Com argumento, entra num modo de edição sequencial — aceita tanto um par de registrador (`AF`, `BC`,
`DE`, `HL`, `IX`, `IY`, `SP`, editado como um valor de 16 bits/4 dígitos hexa) quanto um registrador de
1 byte isolado (`A`, `F`, `B`, `C`, `D`, `E`, `H`, `L`, 2 dígitos hexa):

```
MON>X BC
```

abre uma caixa de diálogo perguntando o novo valor de `BC` (valor atual já preenchido) — confirmar com
ENTER sem editar mantém o valor e passa pro próximo registrador da sequência (`DE`, `HL`, `IX`, `IY`,
`SP`); apagar o campo e confirmar (ou Cancelar) para a edição inteira.

Os registradores duram só enquanto a janela estiver aberta — fechar e reabrir zera todos de novo. Quando
o comando `G` (execução de programas) for implementado de verdade, vai carregar o Z80 simulado com estes
valores.

### R, L e LP - referência de fita e disassembler

`R [<offset>]` ainda **não faz nada** além de confirmar no log — carregar um programa assemblado
gravado por fita (opção `I` do comando `A`, ver abaixo) depende de um leitor que ainda não existe.

`L [<endinic>[,<endfim>]]` disassembla a memória (RAM/ROM mapeada agora pelo `PAGE`) direto no log do
`MON>` — um disassembler Z80 de verdade, com o conjunto de instruções documentado inteiro mais as formas
não documentadas mais estáveis/conhecidas (`IXH`/`IXL`/`IYH`/`IYL`, formas indexadas do `CB` com
cópia-sombra).

- **Os dois endereços** — disassembla de `<endinic>` até ultrapassar `<endfim>` (a instrução que começa
  dentro do intervalo entra inteira, mesmo que os últimos bytes dela passem um pouco de `<endfim>`).
- **Só `<endinic>`** — disassembla exatamente 10 instruções a partir dali.
- **Nenhum endereço** — continua de onde o `L`/`LP` mais recente parou, também 10 instruções.

Cada linha mostra o endereço, os bytes crus em hexa (1 a 4 bytes) e o mnemônico com os operandos —
saltos relativos (`JR`/`DJNZ`) já mostram o **endereço de destino absoluto**, não o deslocamento cru:

```
MON>L 4000,4010
4000  E5           PUSH HL
4001  CD 39 54     CALL 5439
4004  44           LD B,H
```

`LP [<endinic>[,<endfim>]]` é igual ao `L`, mas em vez de mandar a listagem pro log, gera um PDF A4
(fonte Courier) e abre uma janela "Salvar como" — mesma ideia do `P`/`V`. Cancelar não gera arquivo, só
mostra `CANCELADO`.

### EDIT - editor do programa-fonte Z80

`EDIT` abre uma janela separada com um editor de linhas pro programa-fonte Z80, modelado no editor de
BASIC do ZX-81/ZX Spectrum — **a listagem é a própria tela** (sem log de comandos nem mensagem "OK"),
com um cursor `>` marcando a linha atual.

**Sintaxe de cada linha** (formato do manual original do MegaAssembler):

```
NN Label: instrucao operando ;comentario
```

- **`NN`** — número da linha, **obrigatório**. Digitar de novo o mesmo número **substitui** a linha.
- **`Label:`** — opcional, termina em `:`.
- **`instrução`** — um mnemônico Z80 válido ou uma das pseudo-instruções `ORG`/`DEFB`/`DEFW`/`DEFM`/
  `DEFS`/`EQU`/`END`. `EQU` exige `Label:`.
- **`;comentário`** — opcional, até o fim da linha.

**Números** — diferença deliberada em relação ao manual original: **sem sufixo, um número é
HEXADECIMAL por padrão** (o manual original usava decimal), pra ficar uniforme com o resto do Mamute.
Se começar com letra (`A`-`F`), precisa de um `0` na frente — senão vira label. Sufixos opcionais no
final: `H` (hexa, redundante com o padrão), `B` (binário), `D` (decimal — único jeito de escrever
decimal agora).

**Navegação e edição, ao estilo ZX-81:**

- **Setas Cima/Baixo** movem o cursor `>` pela listagem.
- **ENTER com o campo vazio** puxa a linha do cursor `>` pro campo, pronta pra editar.
- **ENTER com o campo preenchido** grava a linha digitada (nova ou substituindo por `NN`).
- **ESC** descarta o que estiver no campo, sem gravar nada.
- **Tela cheia**: ao digitar linhas novas, quando a tela enche ela é limpa e rola **meia tela**
  automaticamente, pra caber mais.
- **`LIST`** (digitado no campo, sem `NN` na frente): limpa a tela e lista a partir da 1ª linha. Se o
  programa não couber inteiro, pergunta "Rolar mais uma tela? (S/N)" no rodapé (responda no mesmo campo
  + ENTER) — respondendo Sim, mostra a próxima tela CHEIA com o cursor na 1ª linha dela, perguntando de
  novo se ainda sobrar programa.

*Diferente do ZX-81 real, não há teclas tokenizadas (cada palavra-chave BASIC numa única tecla) — sem
sentido com teclado de PC de verdade, digite normalmente.*

**Comandos de gerenciamento** (também digitados no campo, sem `NN` na frente):

- **`NEW`** — apaga o programa inteiro da memória, sem confirmação.
- **`DELETE <lininic>[-[<linfin>]]`** — apaga uma linha (`DELETE 50`), um intervalo inclusive (`DELETE
  50-90`), ou da linha até o fim do programa (`DELETE 50-`, sem número final).
- **`RENUM [<novali>[,<antigali>[,<incr>]]]`** — renumera a partir da linha antiga `antigali` pra uma
  nova sequência começando em `novali` com passo `incr` (`RENUM` sozinho: tudo, começando em 10, passo
  10). Só os números de linha mudam — referências por LABEL continuam funcionando normalmente.
- **`CHANGE '<string1>'[,'<string2>']`** — troca todas as ocorrências de `<string1>` por `<string2>` em
  qualquer lugar de cada linha (label, instrução, operando ou comentário); se `<string2>` for omitido,
  apaga as ocorrências de `<string1>`.
- **`SAVE`** / **`LOAD`** — abrem os diálogos nativos "Salvar como"/"Abrir" (sem digitar nome) — gravam/
  leem o programa-fonte inteiro num arquivo `.mza` em **ASCII simples** (formato desta porta, não o
  formato binário proprietário do MegaAssembler original). `LOAD` substitui o programa em memória pelo
  conteúdo do arquivo.
- **`MERGE`** — igual ao `MERGE` do BASIC: mostra o mesmo diálogo do `LOAD`, mas não apaga o programa em
  memória — funde os dois. Uma linha do arquivo com o mesmo número de uma linha já existente sobrepõe a
  existente; números que só existem de um lado ficam como estão.
- **`SEARCH '<string>'`** (entre aspas) — busca literal, sensível a maiúsculas/minúsculas. **`SEARCH
  <string>`** (sem aspas) — busca livre, insensível a maiúsculas/minúsculas (strings, comandos, labels,
  etc). Bem-sucedida, a tela passa a mostrar só as linhas encontradas (mesmas setas/ENTER de sempre
  navegam entre elas) — digite `LIST` (ou qualquer outro comando) pra voltar ao programa completo.
- **`LSEARCH`** — igual ao `SEARCH` (mesmas duas formas com/sem aspas), mas em vez de filtrar a tela,
  manda a listagem das linhas encontradas pra um PDF.
- **`FIND`** — apelido de `SEARCH` (mesmas duas formas, mesmo resultado).
- **`QUIT`** — fecha a janela do `EDIT` e volta pro `MON>`, sem apagar o programa da memória — abrir
  `EDIT` de novo continua exatamente de onde parou.

### A - montar o programa

`A` monta (compila) o programa-fonte de verdade, reaproveitando o mesmo assembler Z80 nativo do projeto
(compatível M80/Nestor80). Mostra `PASSO-1` e depois `PASSO-2` (mesma sequência do MegaAssembler
original) antes de montar.

**`A` sozinho** só valida — o resultado vira uma **listagem detalhada**, coluna a coluna: número da
linha, endereço (ou o valor de um `EQU`), até 4 bytes de código-objeto em hexa (linhas extras se a
instrução/diretiva gerar mais de 4 bytes) e o conteúdo original da linha — a mesma tela cheia/rolagem do
`LIST` se não couber tudo de uma vez. `ORG`/`END` não aparecem na listagem. Em caso de erro, mostra a
mensagem descritiva e o cursor `>` pula direto pra linha com problema (sem listagem nesse caso).

Exemplo (do manual original, adaptado pra hexa por padrão):

```
10              ORG 0C100H
20 CHPUT:       EQU 0A2H
30              LD HL,PRINT
100 PRINT:      DEFM 'MEGA ASSEMBLER'
120             END
```

**Opções**, digitadas coladas depois de `A ` (um espaço, depois as letras juntas, na ordem que quiser —
`A O`, `A ON`, `A ONPIRSDH/1000`, etc.):

| Opção | Efeito |
|---|---|
| **`O`** | Além de validar, **escreve** o código-objeto na RAM simulada, no endereço do `ORG`, resolvido pelo mapeamento de `PAGE` ativo agora (mesma regra do `DM`/`SCR` — só grava de verdade se a célula mapeada for RAM). |
| **`N`** | A listagem não mostra a coluna do número da linha (o resto é idêntico). |
| **`P`** | Além de mostrar a listagem na tela, manda a mesma listagem pra um PDF (diálogo "Salvar como"). Cancelar o diálogo é silencioso — segue exatamente como sem `P`. |
| **`I`** | Grava o código-objeto recém montado em **disco**, no formato real do BSAVE/BLOAD do MSX (cabeçalho `FE` + endereço inicial/final/execução). Abre a mesma janela do comando `SAVE` do `MON>`, já com tudo pré-preenchido (slot sugerido a partir do mapeamento `PAGE` ativo, endereços vindos da montagem) — tudo editável antes de gravar. Diferente de `O`, não precisa que os bytes já estejam na RAM simulada — funciona sozinho. |
| **`R`** | Anexa ao final da listagem uma **referência cruzada** dos símbolos, em ordem alfabética: nome, valor (constante `EQU` ou endereço de definição do rótulo) e todos os endereços onde foi usado (até 4 por linha, continua nas linhas seguintes se precisar). |
| **`S`** | Anexa ao final da listagem uma lista alfabética **simples** dos símbolos (nome + valor/endereço de definição), sem os endereços de uso — se `R` e `S` estiverem ativos juntos, o bloco de `S` aparece depois do de `R`. |
| **`D`** | Igual ao `S`, mas a lista de símbolos vem em **ordem de aparição** no fonte (a ordem em que cada um foi definido), não em ordem alfabética. Se `S` e `D` estiverem ativos juntos, o bloco de `D` aparece depois do de `S`. |
| **`H`** | Manda só a(s) lista(s) de labels (`S` e/ou `D` — pelo menos uma das duas precisa estar ativa) pra um PDF **separado** do de `P`. Se `S` e `D` estiverem ativos junto com `H`, as duas listas vão pro mesmo PDF, separadas por uma linha em branco. |
| **`/<offset>`** | Monta o programa como se **todo `ORG`** tivesse `<offset>` (hexa, 0000-FFFF) somado ao valor original — ex. `A O/8000` com `ORG 0C100H` monta em `0C100H+8000H`. O programa inteiro acompanha o deslocamento (rótulos, saltos, listagem), não é só um resumo de endereço. A `/` fica separada das letras de opção — tudo depois dela é o offset, não mais uma flag. |

A opção `U` do manual original (não lista o programa) ainda não foi implementada.

**`MAP`** (fora do `A`, comando próprio) — mostra o endereço inicial e final do código-objeto da última
montagem bem-sucedida (`A` sozinho já basta, não precisa de `A O`). Se nada foi montado com sucesso
ainda, pede pra rodar `A` primeiro; `NEW` invalida esse resultado guardado.

### Comandos do SUPER-X (prefixo `X`)

O Mamute Assembler também porta comandos do **SUPER-X**, outro monitor/debugger clássico de MSX mais
avançado que o MegaAssembler original — todos com prefixo `X`, pra nunca colidir com os comandos acima
(`XD`/`XA`/`XI`/`XM` são versões "com endereçamento estendido" de `D`/`A`/`I`/`M`, por exemplo). Como a
porta continua em andamento e cada comando tem opções próprias, a referência completa e sempre
atualizada — sintaxe exata, exemplos, decisões de design — fica em **Ajuda → Mamute Assembler...**
(dentro do próprio programa) e em `docs/SPEC.md`, módulo 45 em diante; aqui vai só um mapa de onde
achar cada coisa, por categoria (36 comandos até a versão 8.7.5):

- **Cruz de modos** (`XD`/`XA`/`XI`/`XM`/`XH`) — hex dump editável, bloco ASCII, disassembler, editor de
  variáveis/memória e editor de caractere/sprite, todos aceitando o mesmo sufixo de endereço estendido
  (`#slot[-subslot]`, `#V` pra VRAM, `#S` pro slot de boot) e ligados entre si por um menu em `+` que
  troca de tela sem digitar outro comando.
- **Registradores e execução** (`X`, `XRG`, `XGO`, `XTR`) — `X` mostra os registradores simulados;
  `XRG` edita em pares (incluindo o par alternado `AF'`/`BC'`/`DE'`/`HL'`) e 5 breakpoints nomeados;
  `XGO` executa o programa simulado de verdade até um breakpoint, `ESC` ou um teto de segurança; `XTR`
  faz o mesmo passo a passo, uma instrução por `ENTER`.
- **Memória intra-slots** (`XBT`/`XRT`/`XFL`/`XCM`/`XFD`) — transferir bloco, transferir e realocar
  ponteiros internos, preencher, comparar e buscar por padrão de instrução decodificada — origem e
  destino podem ser slot/sub-slot/VRAM completamente diferentes.
- **Checksum** (`XCS`/`XTS`) — alterna o tipo usado pelo despejo do `XD`, ou calcula um checksum
  agregado de 16 bits de um bloco inteiro.
- **Tela e saída** (`XCO`, `XSD`, `XQT`) — `XCO` muda a cor do terminal pra qualquer uma das 16 cores
  reais do MSX1; `XSD` exporta um disassembly como listagem reassemblável ou como dados crus
  (`DEFB`/`DATA` de BASIC/X-BASIC); `XQT` sai do monitor (igual `BA`/`QUIT`).
- **Disco corrente** (`XDK`, `XFS`, `XCI`, `XTP`, `XSV`/`XLD`, `XS#`/`XL#`, `XL%`/`XS%`) — `XDK`
  escolhe qual `.dsk` é o disco corrente (as outras nunca pedem nome de arquivo — perguntam o disco na
  primeira vez que precisarem, se `XDK` ainda não tiver sido usado); `XFS` lista os arquivos, `XCI`
  mostra o uso do disco, `XTP` é um visualizador de texto paginado com busca; `XSV`/`XLD` gravam/carregam
  no formato real de BSAVE/BLOAD (com cabeçalho); `XS#`/`XL#` fazem o mesmo mas crus, sem cabeçalho;
  `XL%`/`XS%` leem/gravam setor físico direto, abaixo do sistema de arquivos.
- **Notas por endereço** (`XIM`, `XIC`, `XIL`, `XIS`, `XIR`) — um sistema de anotações associadas a
  endereços de memória (porta do "note function" do SUPER-X): `XIM` adiciona uma nota, `XIC` consulta
  as notas de um endereço direto no `MON>`, `XIL`/`XIS` carregam/salvam um arquivo de notas (ver o campo
  "Notas SUPER-X padrão" em [Configurar → Mamute Assembler...](#configurar--mamute-assembler) acima
  pra carregar automaticamente), e `XIR` abre uma janela dedicada pra folhear as notas uma a uma com
  busca (texto simples, sem diferenciar maiúsculas/minúsculas, ou expressão regular).
- **Painel de Portas I/O** (`XPP`, `XPI`, `XPO`) — `XPP` abre um painel que monitora até 256 portas de
  I/O, mostrando o último byte que o programa mandou por `OUT` ("Entrada") e o que uma `IN` vai ler de
  volta ("Saída") — como ainda não existe nenhuma simulação de hardware de verdade atrás, é o usuário
  quem digita o valor de "Saída" antes de rodar o programa (`XGO`/`XTR`), se quiser controlar o que o
  programa vai ler. `XPI`/`XPO`, no `MON>`, leem/escrevem uma porta manualmente sem precisar abrir o
  painel — os dois criam a porta no painel automaticamente se ela ainda não estiver lá.

## Fossauro (emulador MSX nativo)

**🦴 Fossauro** (`src/fossauro/`) é um port nativo em PureBasic do emulador **fMSX** de Marat Fayzullin —
projeto irmão dentro deste repositório, com licença própria (não-comercial, ver
[`LICENSE-fossauro`](../LICENSE-fossauro) na raiz e a seção Licença do `README.md`). Roda como
executável **separado** (`dist/fossauro.exe`), nunca linkado nem distribuído junto (licença
incompatível com a deste projeto) — mas desde 2026-08-18 a IDE principal sabe **iniciá-lo** como
processo externo, ver "Integração com o Paleobasic" abaixo. Ver `docs/SPEC.md`, módulos 32b/32c/32r,
para arquitetura, status por componente e o roteiro de integração futura. Esta seção documenta a
operação da janela e da linha de comando do próprio Fossauro; para arquitetura interna, veja
`docs/SPEC.md`.

### Integração com o Paleobasic (Executar/Configurar → Fossauro)

- **Configurar → Fossauro...**: tela de configurações padrão (`src/editor/emulators/FossauroSupport.pbi`,
  `dist/editor/fossauro_settings.json` - machine-local, gitignored, mesmo padrão de
  `asmsx_settings.json`/`n80_settings.json`). Campos: caminho do executável (tenta auto-detectar
  `dist/fossauro.exe` na mesma pasta de `dist/PaleoBasic.exe` se o campo estiver vazio - ainda precisa clicar
  Salvar uma vez, mesma exigência de qualquer ferramenta externa configurável nesta IDE), tipo de
  máquina (MSX1/MSX2/MSX2+), RAM (64/128/256/512/1024KB) e VRAM (16/32/64/128/192KB) — mesmos valores
  válidos dos próprios menus **Hardware → RAM Size/VRAM Size** do Fossauro —, temporização PAL/NTSC, log
  verboso (`-verbose`) e um cartucho padrão opcional carregado no Slot A ao iniciar.
- **Executar → Fossauro...** (`F10`): inicia o executável configurado com as opções acima
  (`-msx1`/`-msx2`/`-msx2+ -ram N -vram N -pal`/`-ntsc` [`-verbose`] [cartucho]), like um processo
  independente — sem canal de controle por pipe (diferente do openMSX), a janela do Fossauro abre e
  fica rodando por conta própria. Sem caminho configurado, mostra um erro apontando pra **Configurar →
  Fossauro...**.
- **`-diska`/`-diskb` (disco padrão) ainda não expostos aqui de propósito** — o controlador de disquete
  (FDC) do Fossauro existe mas ainda não está ligado ao boot (regressão conhecida, `docs/SPEC.md` módulo
  32p); serão adicionados à tela de configuração quando isso for corrigido.

> `docs/fossauro/manual.md` (mantido pelo próprio sub-projeto) descreve um conjunto bem mais amplo de menus
> e opções de linha de comando do que o que existe implementado hoje — a tabela abaixo separa
> explicitamente o que já funciona do que ainda é só documentação aspiracional, pra evitar confundir os
> dois.

### O que já funciona hoje

- Compilar: `.\fossauro\build.ps1` (precisa de `pbcompiler` no `PATH`, mesma exigência do `build.ps1`
  principal da IDE — não usa o `build.config.json` do Paleobasic, são scripts independentes).
- Rodar: `fossauro\fossauro.exe [-msx1|-msx2|-msx2+] [-rom <arquivo>] [-verbose]`. Sem argumentos, sobe
  direto pro boot do MSX1 (BIOS `fMSX/MSX.ROM`) com 64KB de RAM e 16KB de VRAM (padrão explícito do
  projeto desde 2026-08-18 - `Mode`/`RAMPages`/`VRAMPages` em `MSX.pbi`) sem cartucho — confirmado
  2026-08-17 (screenshot) que isso já mostra o boot completo de verdade: "`MSX BASIC version 1.0` /
  `Copyright 1983 by Microsoft` / `28815 Bytes free` / `Ok`" com o cursor piscando e a barra de teclas de
  função (`color auto goto list run`) no rodapé, igual ao fMSX real. **Os três modelos chegam no prompt do
  BASIC completo**
  (`-msx1`="MSX BASIC version 1.0", `-msx2`="MSX BASIC version 2.1" desde a correção do freeze de boot em
  2026-08-18 (`docs/SPEC.md` módulo 32j), `-msx2+`="MSX BASIC version 3.0"), carregando a BIOS certa por
  modelo. A janela abre com menus **File**, **Emulation** e **Hardware**.
- **Menu File**: `Open Cartridge...` (carrega um `.rom`/`.mx1`/`.mx2`), `Open Disk...` (seleciona um
  `.dsk` mas ainda não faz nada com ele - sem controlador de disquete implementado), `Save Snapshot...`/
  `Open Snapshot...` (salva/carrega o estado completo da máquina - RAM, VRAM, CPU, VDP, PSG, PPI, RTC,
  slots - num arquivo `.fss` próprio; o cartucho é relido do caminho original no load, não é embutido no
  snapshot), `Load .CAS...`/`Load .CHT...` (seletores de arquivo prontos, mas fita cassete e cheats -
  formato pretendido compatível com openMSX/BlueMSX - ainda não têm nenhuma lógica por trás), `Quit`.
- **Menu Hardware → Model**: troca entre MSX1/MSX2/MSX2+ com a máquina já rodando (recarrega a BIOS certa,
  recarrega o cartucho atual se houver, reset completo - equivalente a reiniciar com um modelo diferente,
  não preserva RAM/VRAM). O item do modelo atual aparece marcado.
- **Menu Hardware → RAM Size**: 64/128/256/512/1024 KB, também com reset completo (igual trocar de
  modelo - não é hot-swap). Implementado igual ao fMSX real: o mapeador de RAM por bancos (portas
  `$FC`-`$FF`, sempre no Slot Primário 3/Secundário 2) é usado em **todos** os modelos, não só MSX2/2+ -
  o fMSX real não modela expansão de RAM do MSX1 como cartuchos separados, mesmo sendo essa a prática mais
  comum em hardware real da época. O tamanho pedido é arredondado pra potência de 2 e limitado por modelo
  (MSX1 mínimo 4 páginas/64KB, MSX2/2+ mínimo 8 páginas/128KB, máximo 256 páginas/4096KB) - pedir 64KB
  rodando MSX2/2+, por exemplo, aplica 128KB (mínimo do modelo) em vez de travar ou dar erro, mesmo
  comportamento do fMSX original. Também setável via `-ram <páginas>` na linha de comando. O item do
  tamanho realmente aplicado aparece marcado (pode diferir do que foi clicado, por causa do
  arredondamento/limite acima).
- **Menu Hardware → VRAM Size**: 16/32/64/128/192 KB, mesma lógica da RAM Size acima. O fMSX real é ainda
  mais rígido aqui: MSX2/MSX2+ só aceitam exatamente 128KB (qualquer outro valor volta pra 128KB), MSX1
  só aceita 32/64/128KB (16KB volta pra 32KB) - "192KB"/addon V9958 não existe no fMSX real, nunca fica
  selecionado de verdade. Também setável via `-vram <páginas>`.
- **Menu Hardware → Cartridge Slot A / Cartridge Slot B**: `Load...`/`Eject` independentes por slot (Slot
  A sempre Slot Primário 1, Slot B sempre Slot Primário 2 - um bug real do código antigo fazia o Slot A
  espelhar nos dois slots primários "por compatibilidade com cartucho único", roubando o Slot B se
  carregado depois; corrigido) mais um submenu `Mapper Type` (Guess MegaROM mapper/Generic 8KB/Generic
  16KB/Konami 5000h-SCC/Konami 4000h/ASCII 8KB/ASCII 16KB/GameMaster2/FMPAC, mesma lista do `-rom <tipo>`
  do fMSX real). ROMs maiores que 32KB agora trocam de banco de verdade (`MapROM()`, portado do
  `MSX.c` real) em vez de simplesmente truncar - inclui RAM battery-backed (SRAM) pros mappers que
  precisam, só que sem persistir em arquivo `.sav` ainda (só dura a sessão). Trocar o mapper com um
  cartucho já carregado recarrega ele ao vivo com o novo mapper.
- **Menu Emulation**: `Reset`, `Pause`, `Resume`.
- **Menu Video → Scale → 1:1 / Force 4:3 screen ratio**: funcionam, verificados ao vivo. **2:1/3:1/4:1
  mostram um aviso em vez de aplicar** — bug real e 100% reproduzível confirmado nesta máquina: qualquer
  janela/canvas maior que 512x384 trava o `fossauro.exe` (não é sobre redimensionar em si — até um
  processo novo iniciado direto com `-vscale 2` trava sozinho). Causa raiz não isolada, ver `docs/SPEC.md`
  módulo 32s. Também setável via `-vscale <1-4>` (N>1 herda o mesmo bug) e `-4x3` na linha de comando.
- Se a tela ficar azul sólida sem nada desenhado por mais que alguns segundos, isso **não** é o
  comportamento esperado — é sintoma do bug de `EX (SP),HL` corrigido em 2026-08-17 (`docs/SPEC.md`
  módulo 32b, achado #2) ou de alguma regressão parecida; rode com `-verbose` e acompanhe
  `dist/fossauro.log` (grava relativo ao diretório de trabalho no lançamento, mesma pasta de
  `dist/fossauro.exe`): a cada frame ele grava uma linha `[CPU] FRAME=<n> PC=... SP=... VDP(0)=...`
  (deve subir a ~50-60/s), e comparar o conteúdo da VRAM/name table contra o esperado é o caminho que
  achou o bug da última vez (ver o achado no `docs/SPEC.md` para o passo a passo).

### Linha de comando

Desde 2026-08-17, `fossauro.exe` **aceita a linha de comando do fMSX original** (não mais um punhado
de flags próprias) — `fossauro -help` imprime a lista completa e é a referência viva (evita esta tabela
ficar desatualizada); a versão completa e comentada do fMSX original está em `docs/fossauro/fMSX-reference.md`.
`-help` funciona como um utilitário de console normal (imprime no terminal que chamou e sai, sem abrir
janela — inclusive quando a saída é redirecionada com `>`).

Resumo do que já tem efeito real vs. só é aceito (não trava, não gera erro, mas ainda não faz nada):

| Categoria | Exemplos | Estado |
|---|---|---|
| Cartucho | `[arquivo1] [arquivo2]` posicionais (padrão fMSX real — 1º = slot A, 2º = slot B), `-rom <arquivo>` (atalho antigo do fossauro, ainda aceito) | **Funciona** — carrega e mapeia nos slots 1 e 2 respectivamente. |
| Modelo/vídeo | `-msx1`/`-msx2`/`-msx2+`, `-pal`/`-ntsc` | **Os três modelos funcionam de ponta a ponta** — carregam a BIOS certa por modelo (`MSX.ROM` / `MSX2.ROM`+`MSX2EXT.ROM` / `MSX2P.ROM`+`MSX2PEXT.ROM`) e chegam no prompt do BASIC (MSX1 mostra "MSX BASIC version 1.0", MSX2 mostra "MSX BASIC version 2.1" desde a correção do freeze de boot em 2026-08-18, `docs/SPEC.md` módulo 32j, MSX2+ mostra "MSX BASIC version 3.0"). SCREEN 6/7 (usado durante o boot do MSX2, pro logo/ícone) ainda não é desenhado por `RefreshLine()` (só modos 0-5/8) - desenhado corretamente na VRAM, só não aparece na tela. |
| Memória | `-ram <páginas>` | **Funciona** — número de páginas de 16KB atrás do mapeador de RAM (portas `$FC`-`$FF`, mesmo mecanismo em todo modelo). Arredondado pra potência de 2 e limitado por modelo (MSX1 mín. 4/64KB, MSX2/2+ mín. 8/128KB, máx. 256/4096KB), igual ao fMSX real. Também setável ao vivo via **Hardware → RAM Size**. |
| Vídeo (memória) | `-vram <páginas>` | **Funciona** — mesma ideia, pro tamanho de VRAM. MSX2/2+ só aceitam exatamente 8 páginas (128KB), MSX1 só 2/4/8 (32/64/128KB), igual ao fMSX real. Também setável ao vivo via **Hardware → VRAM Size**. |
| Log | `-verbose [<máscara>]` | **Funciona**, mas com bitmask própria do fossauro (1=geral, 2=memória, 4=VDP, 8=PSG, 16=CPU) — não é a mesma numeração do `-verbose <level>` do fMSX real. |
| Vídeo (janela) | `-vscale <1-4>` | **Funciona só pra `1`** (única escala sem o bug de travamento do módulo 32s acima) — N>1 é aceito mas herda o mesmo travamento. Fórmula (`largura=256×N×2, altura=212×N`) confirmada batendo com as resoluções reais do fMSX (256x212/512x424/768x636/1024x848). |
| Vídeo (proporção) | `-4x3` | **Funciona** — real flag do fMSX, antes aceita-mas-inerte, agora ligada de verdade. Mesmo efeito do toggle **Video → Force 4:3 screen ratio**. |
| `-rom <tipo>` (mapeador MegaROM, 0-7) | — | Aceito e guardado, ainda sem efeito na CLI (troca de banco em si **já funciona** — ver **Hardware → Cartridge Slot A/B → Mapper Type**, só a flag de linha de comando que ainda não está ligada a isso). |
| Resto (disco, fita, som, joystick, escala de tela, filtros de vídeo, trap do debugger, etc.) | `-diska`, `-diskb`, `-tape`, `-sound`, `-joy`, `-scale`, `-trap`, `-tv`/`-lcd`/`-raster`, `-mono`/`-sepia`, etc. | **Só aceito** — reconhecido, consome o argumento certo, registrado em `fossauro.log` com `-verbose` ligado, mas não muda comportamento nenhum ainda (disco/fita/som/joystick/filtros de vídeo não existem no fossauro hoje). |

> **Corrigido 2026-08-17**: rodando um cartucho por tempo suficiente (~20-25s em modo padrão MSX2, ou
> poucos segundos com `-msx1`), `fossauro.exe` travava com uma access violation genuína (`0xC0000005`).
> Achado via os minidumps que o Windows já gravava automaticamente em `%LOCALAPPDATA%\CrashDumps\`
> (7 crashes reproduzidos, todos com `ExceptionAddress=0x0` — chamada através de ponteiro de função
> nulo): `JumpZ80` nunca é atribuído em `fossauro.pb`/`EmulationThreadProc()` (só no harness de teste
> separado), e dois pontos de código (`JP (HL)`/`JP (IX)`/`JP (IY)`, opcode `$E9`, traduzidos direto do
> C original sem a guarda que o resto do núcleo já usava) chamavam `JumpZ80(...)` sem checar se estava
> setado primeiro. `JP (HL)` é comum em jogos de verdade (jump computado), então qualquer cartucho que a
> executasse crashava. Corrigido com a mesma guarda `If JumpZ80 : JumpZ80(...) : EndIf` já usada em
> outro lugar do núcleo Z80 (`Z80.pbi`). Ver `docs/SPEC.md` módulo 32b pro passo a passo completo,
> incluindo como os minidumps foram lidos sem precisar instalar WinDbg/cdb.
>
> **Achado separado, ainda em aberto (mesmo dia)**: mesmo com o crash corrigido, um cartucho carregado
> pode "congelar" depois da tela de abertura — investigado a fundo e **confirmado que não é hang de
> CPU**: `FrameCounter` avança normalmente (~47fps), `ScanLine` progride certinho, mas o conteúdo da
> tela fica pixel-idêntico entre screenshots tirados segundos de diferença. A splash mostrada ainda é a
> do BIOS, não a tela de título do jogo — o jogo nunca assume o controle visual. A hipótese do hook
> H.TIMI foi investigada a fundo: **o hook É instalado com sucesso** (`JP $401A`, dentro do cartucho,
> persiste corretamente em RAM) — não era isso. O que quebra: o registrador de sub-slot secundário da
> RAM muda sozinho pouco depois, escondendo o hook (ainda intacto) atrás de memória vazia — rastreado
> até a pilha do jogo crescendo sem limite a partir do código que o hook chama, até dar a volta em 64KB
> e colidir com `$FFFF` (que no MSX real é sempre o registrador de troca de slot). **Ainda não
> corrigido** — precisaria desmontar o próprio `Kingsvalley.rom` a partir de `$401A` pra achar o que
> estoura a pilha. Ver `docs/SPEC.md` módulo 32b pro passo a passo completo.

### O que o manual original do Fossauro descreve mas ainda não existe

`docs/fossauro/manual.md` documenta os itens abaixo como se já existissem — nenhum está implementado em
`src/fossauro/fossauro.pb` no momento (não são bugs, é documentação escrita à frente do código, comum em
projeto que ainda está construindo a base):

- Menus **File** (Load ROM.../Load Disk A:/B:/Load Tape.../Save State/Load State) além do que a janela
  já abre vazio - carregar ROM só funciona via `-rom` na linha de comando, não pela GUI ainda.
- Menu **Emulation** (Reset, Pause/Resume, velocidade Fast Forward/Slow Motion, troca de sistema
  MSX1/MSX2/MSX2+ em runtime).
- Menu **Video** — parcialmente implementado desde 2026-08-18 (escala 1:1 real + `Force 4:3`; 2:1/3:1/4:1
  bloqueados por um bug real, ver acima), NTSC/PAL já existia via linha de comando, scanlines segue sem
  implementar.
- Menu **Audio** (mute, volume) — PSG em si já funciona (síntese de áudio real, verificada
  `docs/SPEC.md` módulo 32n), mas o menu de controle de volume/mute ainda não existe.

**Atualização 2026-08-17**: as opções de CLI que essa lista mencionava (`-msx1`/`-msx2`/`-msx2+`,
`-diska`/`-diskb`, `-tape`, `-pal`/`-ntsc`, `-trap`, `-help`) **agora existem** — `fossauro.exe` passou a
aceitar toda a linha de comando do fMSX original (ver seção "Linha de comando" acima). A maioria ainda
não tem efeito de verdade (disco/fita/trap continuam não implementados), mas não é mais "documentação
que não corresponde a nada no código" — o parser reconhece e aceita cada uma delas explicitamente, e
`-help` já funciona de verdade.
