# Changelog - fMSXgo

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo.

O formato é baseado no [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/), e as versões seguem a regra **`V X.Y.Z`** com codinomes inspirados em **Filmes de Terror, Clássicos do MSX e Heavy Metal**.

---

## [V 0.1.0] - "Phantasm (The Tall Man)" - 2026-09-16

### Adicionado (Added)
- **Núcleo Z80 64-bit Puro**:
  - Implementação completa e fiel do processador Zilog Z80 em Go (tabelas de opcodes Base, CB, ED, DD, FD, DDCB e FDCB).
  * Tabelas de flags `ZSTable` e `PZSTable` portadas diretamente do `Tables.h` do fMSX.
  * Suporte a ganchos de interceptação e aceleração de BIOS com o opcode patch `ED FE` (`PatchZ80`).
  * Bateria de testes unitários validando instruções lógicas, aritméticas de 8 e 16 bits, saltos relativos/absolutos, transferências em bloco (`LDIR`), chamadas e pilha.
- **Ferramentas Integradas para Desenvolvedores e Hackers**:
  * **Mini-Assembler Embutido**: Montador interativo capaz de traduzir mnemônicos (`LD`, `ADD`, `SUB`, `JP`, `CALL`, `RET`, `OUT`, `IN`, etc.) diretamente em bytes executáveis na memória do Z80.
  * **Disassembler Dinâmico**: Desmontagem em tempo real com identificação precisa do tamanho e parâmetros das instruções.
- **Barramento MSX & Gerenciamento de Memória**:
  * Implementação da matriz de slots de 64KB com 4 Slots Primários (porta `0xA8`) e 4 Subslots Secundários (endereço `0xFFFF`).
  * Gerenciamento de **RAM Mapper** (portas `0xFC` a `0xFF`, permitindo de 64KB a 4MB de RAM).
  * Proteção de escrita em páginas de ROM e permissão de escrita em páginas de RAM baseada no slot atualmente selecionado.
- **Persistência Centralizada em SQLite (`fmsxgo.db`)**:
  * Eliminação da necessidade de distribuir múltiplos arquivos de ROM avulsos.
  * Armazenamento das ROMs de BIOS (`MSX.ROM`, `MSX2.ROM`, `MSX2EXT.ROM`, `DISK.ROM`, etc.) como objetos `BLOB` com metadados e hashes SHA-1.
  * Suporte a tabelas de configurações, manuais e perfis de hardware no SQLite.
- **Interface Gráfica & Menus (Ebitengine)**:
  * Criação da janela gráfica cross-platform (Windows & Linux 64-bit).
  * Barra de menus superior com **`File -> Exit`** e **`Help -> About`**.
  * Diálogo modal interativo de créditos e licença.
  * Painel de status ao vivo exibindo registradores Z80 e configurações de hardware.
- **Shell CLI / Monitor Interativo**:
  * Modo de execução em terminal (`--no-window`).
  * Comandos: `HELP`, `QUIT`, `r` (registradores), `d` (hexdump), `e` (edição de bytes), `u` (disasm), `a` (mini-assembler interativo), `t` (trace), `p` (step-over), `g` (execução contínua), `bp` (breakpoints), `slots` (diagnóstico de slots), `mapper`, `in` e `out`.
- **Automação de Build & Empacotamento (`build.ps1`)**:
  * Script PowerShell que restaura dependências, incrementa automaticamente o número de build, executa testes, compila o binário e empacota a pasta `dist/` pronta para uso pelo usuário final.
