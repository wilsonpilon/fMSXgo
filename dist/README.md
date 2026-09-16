# fMSXgo - MSX Emulator & Developer Workstation (64-bit)

[![Language](https://img.shields.io/badge/Language-Go%201.27-blue.svg)](https://golang.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%2064--bit-darkgreen.svg)]()
[![Status](https://img.shields.io/badge/Status-Active%20Development-orange.svg)]()
[![License](https://img.shields.io/badge/License-Non--Commercial-red.svg)](LICENSE)

**fMSXgo** é um porte fiel e moderno do consagrado emulador **fMSX** (originalmente desenvolvido em C por **Marat Fayzullin**) para a linguagem **Go (64-bit)**, focado em **Windows e Linux**. 

Além de herdar a precisão histórica do fMSX, o **fMSXgo** foi desenhado desde o primeiro dia para ser uma **estação de trabalho de ponta para desenvolvedores de software MSX e entusiastas de hacking/engenharia reversa**, com:

* **Núcleo Z80 100% puro em Go** com tabelas de flags pré-computadas fiéis ao original (`ZSTable`, `PZSTable`).
* **Mini-Assembler Interativo Embutido** (permite montar instruções Z80 diretamente na memória em tempo de execução).
* **Disassembler Dinâmico** integrado.
* **Barramento de Slots Fiel**: 4 Slots Primários (`0xA8`), 4 Subslots Secundários (`0xFFFF`) e **RAM Mapper** (`0xFC`..`0xFF`) de 64KB até 4MB.
* **Persistência Centralizada em SQLite (`fmsxgo.db`)**: todas as ROMs de BIOS, configurações, perfis de máquina e manuais de ajuda ficam armazenados em um único arquivo de banco de dados SQLite, eliminando pastas cheias de arquivos avulsos na distribuição.
* **Interface Gráfica com Menus**: Janela gráfica com barra de menus (`File -> Exit`, `Help -> About`) e suporte a modo terminal puro via `--no-window`.
* **Monitor / Shell Interativo ("SO de Desenvolvimento")**: REPL completo com comandos de inspeção de registradores, hexdump, edição direta de memória, stepping (`step-in`, `step-over`), breakpoints e teste de portas I/O.
* **Script de Automação e Empacotamento (`build.ps1`)**: compilação, testes, incremento de versão e geração da pasta `dist/` pronta para o usuário final.

---

## Esquema de Versões & Codinomes (Horror & Heavy Metal)

O projeto adota o versionamento **`V X.Y.Z`** acompanhado de codinomes inspirados no universo do MSX, filmes de terror e clássicos do Heavy Metal:
* **`Z`**: incrementado a cada compilação gerada pelo `build.ps1`.
* **`Y`**: incrementado a cada novo subsistema ou feature funcional.
* **`X`**: incrementado a cada grande bloco arquitetural concluído.

Versão Atual: **V 0.1.0 ("Phantasm")**

Para detalhes sobre todas as fases e planejamento futuro, consulte o documento vivo [SPEC.md](SPEC.md).

---

## Início Rápido

### 1. Compilar e Gerar o Pacote de Distribuição
Execute o script de automação no PowerShell:
```powershell
.\build.ps1
```
O script baixará as dependências, rodará a suite de testes, compilará o binário de 64 bits e gerará a pasta `dist/` completa contendo o executável, o banco de dados `fmsxgo.db` populado com todas as ROMs de BIOS e atalhos de inicialização.

### 2. Executar no Modo Gráfico
```powershell
.\fmsxgo.exe
```
Abre a janela gráfica do emulador contendo o menu superior (`File -> Exit`, `Help -> About`).

### 3. Executar no Modo Terminal / CLI de Desenvolvimento
```powershell
.\fmsxgo.exe --no-window
```
Ou com opções de hardware:
```powershell
.\fmsxgo.exe --no-window -msx2 -ram 8
```

---

## Documentação do Projeto

* 📖 **[MANUAL.md](MANUAL.md)**: Manual completo do usuário, comandos do Shell e sintaxe do Mini-Assembler.
* 📋 **[SPEC.md](SPEC.md)**: Especificação técnica viva, fases do projeto e registro de "onde paramos".
* 📝 **[CHANGELOG.md](CHANGELOG.md)**: Histórico cronológico detalhado de cada versão e novidade.

---

## Créditos e Licença

Este projeto é uma tradução/porte em Go do emulador **fMSX**, criado por **Marat Fayzullin**.

* **Lógica original do fMSX e arquitetura**: &copy; Marat Fayzullin (1994-2021). Projeto desenvolvido com conhecimento e aval do autor original.
* **Porte em Go, ferramentas de desenvolvimento e interface**: &copy; Wilson "Barney" Pilon.

**Aviso Importante**: Este projeto destina-se **estritamente a uso Não-Comercial**. Ele herda as restrições proprietárias de licenciamento do código-fonte original do fMSX. Consulte o arquivo [LICENSE](LICENSE) para maiores esclarecimentos.