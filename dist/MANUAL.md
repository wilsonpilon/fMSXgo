# Manual do Usuário e Desenvolvedor - fMSXgo

**fMSXgo** é um porte fiel e moderno do emulador **fMSX** (originalmente desenvolvido em C por **Marat Fayzullin**) para a linguagem **Go**, com suporte nativo a sistemas operacionais **Windows e Linux (64-bit)**. 

Além de manter a precisão e fidelidade da máquina MSX original, o fMSXgo foi concebido como uma **estação de trabalho completa para desenvolvedores e hackers**, oferecendo um monitor interativo, mini-montador embutido, disassembler dinâmico, inspeção de memória/slots e armazenamento unificado em banco **SQLite**.

---

## 1. Inicialização e Modos de Operação

O fMSXgo oferece dois modos principais de execução:

### Modo Gráfico (Padrão)
Executando o programa sem argumentos:
```powershell
.\fmsxgo.exe
```
O emulador abrirá uma janela gráfica contendo a barra de menus superior:
* **Menu `File`**:
  * `Reset Machine`: Reinicia a máquina e a CPU aos valores de fábrica.
  * `Exit`: Encerra o emulador.
* **Menu `Help`**:
  * `About fMSXgo`: Exibe a caixa de diálogo com a versão ativa, créditos a Marat Fayzullin e Wilson Pilon, e termos de licença não-comercial.

### Modo Terminal / CLI Monitor (`--no-window`)
Para desenvolvimento de software, automação de testes ou operação rápida sem abrir janelas gráficas:
```powershell
.\fmsxgo.exe --no-window
```
Ou usando o atalho `-cli`:
```powershell
.\fmsxgo.exe -cli
```
Você entrará no **fMSXgo Shell**, um ambiente de comandos no estilo de um sistema operacional de depuração e monitor hacker.

---

## 2. Parâmetros de Linha de Comando

O fMSXgo suporta tanto opções modernas de duas barras (`--`) quanto as clássicas do fMSX de uma barra (`-`):

### Opções Principais
| Parâmetro | Descrição |
| :--- | :--- |
| `--help`, `-help`, `-h` | Exibe a lista completa de comandos e opções disponíveis. |
| `--no-window` | Desativa a interface gráfica e entra diretamente no shell CLI. |
| `--db <arquivo>` | Define o caminho do banco SQLite (padrão: `fmsxgo.db`). |
| `-test` | Executa auto-diagnóstico interno de integridade de CPU e slots. |
| `-exec "<comandos>"` | Executa uma sequência de comandos no shell separados por ponto-e-vírgula. |

### Configuração de Hardware MSX (Compatibilidade fMSX)
| Parâmetro | Descrição |
| :--- | :--- |
| `-msx1` | Emula um computador padrão MSX 1 (TMS9918 VDP). |
| `-msx2` | Emula um computador padrão MSX 2 (V9938 VDP, padrão). |
| `-msx2+` | Emula um computador padrão MSX 2+ (V9958 VDP). |
| `-pal` | Ajusta o sincronismo de vídeo para o padrão europeu PAL (50Hz). |
| `-ntsc` | Ajusta o sincronismo de vídeo para o padrão NTSC (60Hz, padrão). |
| `-ram <páginas>` | Define a quantidade de memória RAM em páginas de 16KB (padrão: 8 = 128KB). |
| `-vram <páginas>` | Define a memória de vídeo em páginas de 64KB (padrão: 2 = 128KB). |
| `-rom <arquivo>` | Carrega um cartucho ROM no Slot 1 (atalho: `-carta`). |
| `-cartb <arquivo>` | Carrega um cartucho ROM no Slot 2. |
| `-diska <arquivo>` | Insere uma imagem de disco `.DSK` no drive virtual A:. |
| `-diskb <arquivo>` | Insere uma imagem de disco `.DSK` no drive virtual B:. |

---

## 3. O Shell de Depuração (Monitor Interativo)

Ao iniciar com `--no-window`, o prompt exibirá o endereço atual do Program Counter (`PC`):
```text
fMSXgo [0000h]> 
```

### Comandos de Controle Primário
* **`HELP`** (ou `?`): Exibe o sumário com todos os comandos do shell.
* **`QUIT`** (ou `exit`): Encerra o emulador.

### Comandos de Registradores
* **`r`** (ou `regs`): Exibe todos os registradores principais (`AF`, `BC`, `DE`, `HL`), sombras (`AF'`, `BC'`, `DE'`, `HL'`), registradores de índice (`IX`, `IY`), pilha (`SP`), `PC`, `I`, `R`, modo de interrupção (`IM`), flags individuais (`[SZ5H3PNC]`) e a instrução desmontada no endereço do PC.
* **`r <reg> <val>`**: Altera o registrador especificado para o valor hexadecimal fornecido:
  ```text
  fMSXgo [0000h]> r a 42h
  fMSXgo [0000h]> r pc C000h
  fMSXgo [C000h]> r sp F000h
  ```

### Inspeção e Edição de Memória
* **`d [addr] [len]`**: Exibe um *hexdump* com caracteres ASCII da memória. Se o endereço for omitido, continua de onde parou no último dump:
  ```text
  fMSXgo [0000h]> d 0000 20
  0000:  F3 C3 16 04 BF 1B 98 98 C3 83 26 00 C3 F5 01 00  |..........&.....|
  0010:  C3 86 26 00 C3 25 02 00 C3 45 1B 00 C3 17 02 00  |..&..%...E......|
  ```
* **`e <addr> <b0> [b1 b2 ...]`**: Escreve bytes em hexadecimal diretamente na memória especificada:
  ```text
  fMSXgo [0000h]> e C000 3E 42 76
  Wrote 3 bytes starting at C000h
  ```

### Desmontagem de Código (Disassembler)
* **`u [addr] [count]`**: Desmonta `count` instruções a partir do endereço indicado (padrão: 10 instruções):
  ```text
  fMSXgo [C000h]> u C000 3
  => C000:  3E 42         LD A, 42h
     C002:  76            HALT
     C003:  00            NOP
  ```

### Mini-Assembler Interativo Embutido
O fMSXgo possui um montador Z80 integrado!
* **Montagem Interativa**: Digite `a <addr>` para entrar no modo de edição linha a linha. Para sair, pressione `Enter` em uma linha vazia:
  ```text
  fMSXgo [0000h]> a C000
  Entering Mini-Assembler at C000h (press Enter on empty line to exit):
  C000: LD A, 10
  C002: LD B, 20
  C004: ADD A, B
  C005: HALT
  C006: [Enter]
  Exited Mini-Assembler.
  ```
* **Montagem em Linha Única**: Digite `a <addr> <instrução>`:
  ```text
  fMSXgo [0000h]> a C000 LD A, 0xFF
  Assembled 2 bytes at C000h
  ```

### Execução e Passo a Passo (Debugging)
* **`t [n]`**: Executa passo a passo (*step-in*) `n` instruções (padrão: 1), exibindo o mnemônico executado e os registradores a cada passo.
* **`p`**: Executa passo sobre (*step-over*), tratando chamadas a sub-rotinas (`CALL`, `RST`, `DJNZ`) como uma única instrução atômica sem entrar no corpo da função.
* **`g [addr]`**: Inicia a execução contínua da máquina a partir de `addr` (ou do PC atual) até atingir um breakpoint ou comando `HALT`.
* **`bp`**: Gerencia pontos de parada (*breakpoints*):
  * `bp`: Lista breakpoints ativos.
  * `bp add <addr>`: Adiciona um breakpoint no endereço.
  * `bp del <addr>`: Remove o breakpoint do endereço.
  * `bp clear`: Remove todos os breakpoints ativos.

### Barramento MSX & Hardware
* **`slots`**: Exibe um relatório detalhado do estado do Primary Slot Register (`A8h`), Secondary Slot Registers (`FFFFh`) e a quais slots/subslots cada uma das 4 páginas da Z80 está mapeada.
* **`mapper`**: Inspeciona as páginas do RAM Mapper e as portas de chaveamento `0xFC`..`0xFF`.
* **`in <porta>`**: Lê um byte de uma porta I/O (ex: `in 98` para VRAM, `in A8` para slots).
* **`out <porta> <val>`**: Escreve um byte em uma porta I/O (ex: `out A8 F0`).
* **`info`**: Exibe dados da configuração da máquina ativa.
* **`reset`**: Reinicializa todo o hardware do MSX e zera a CPU.

---

## 4. Persistência Centralizada em SQLite (`fmsxgo.db`)

Para evitar a proliferação de arquivos avulsos e pastas de ROMs espalhadas na distribuição para o usuário final, o fMSXgo utiliza um banco de dados **SQLite centralizado (`fmsxgo.db`)**:

* **Tabela `roms`**: Armazena as imagens binárias completas de todas as BIOS (`MSX.ROM`, `MSX2.ROM`, `MSX2EXT.ROM`, `DISK.ROM`, etc.) como campos `BLOB`, com hash SHA-1, nome e tipo de máquina.
* **Tabela `config`**: Armazena preferências persistentes de hardware, vídeo e caminhos.
* **Tabela `manuals`**: Armazena os tópicos de ajuda do sistema.

Quando você compila o projeto com `build.ps1`, o banco de dados é automaticamente gerado e populado dentro do diretório `dist/`, tornando a distribuição 100% autônoma.

---

## 5. Compilação e Distribuição com `build.ps1`

Para compilar o projeto e gerar o pacote de distribuição:

```powershell
.\build.ps1
```

O script realizará automaticamente:
1. Leitura e incremento do número de build no arquivo `version.json`.
2. Verificação e download de dependências Go (`go mod tidy` / `download`).
3. Execução da bateria completa de testes unitários (`go test ./...`).
4. Compilação otimizada do executável em modo 64-bit para a pasta `dist/`.
5. Inicialização e população do banco SQLite `fmsxgo.db` com todas as ROMs.
6. Cópia de manuais, documentação e criação de lançadores rápidos (`run-gui.bat` e `run-cli.bat`).
