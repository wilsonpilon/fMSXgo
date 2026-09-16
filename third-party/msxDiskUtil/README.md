# MSX Disk Manager Utility - Versão  (Build )

Este utilitário é uma reescrita completa em **PureBasic** do clássico gerenciador de imagens de disquete MSX (`.DSK`). Ele permite a criação de novos discos em branco de 720KB (completamente formatados com FAT12), listagem detalhada de arquivos, adição de novos arquivos locais, extração e exclusão de arquivos existentes.

Este projeto foi totalmente desenvolvido utilizando o **Antigravity IDE**.

---

## Histórico de Versões e Créditos

- **Versão 1.6 (Original)**: Desenvolvida por Arnold Metselaar para Linux. Um utilitário em linha de comando escrito em C composto pelos programas separados `rddsk` (para ler/extrair) e `wrdsk` (para gravar).
- **Versão 1.7 (Adaptação)**: Adaptada por Wilson "Barney" Pilon para sistemas de 64 bits e compatibilizada com Windows através de MSYS2/MinGW.
- **Versão  (Esta Versão)**: Uma **reescrita completa do zero em PureBasic**. Consolida todas as funções de leitura e escrita em uma única biblioteca e em um único utilitário unificado de console, eliminando a dependência do compilador C e de DLLs de terceiros (como `msys-2.0.dll`).

---

## Estrutura de Arquivos

### Fontes (Código-Fonte)
- **[MSXDisk.pbi](MSXDisk.pbi)**: Módulo principal de inclusão (`MSXDisk`) em PureBasic. Contém toda a estrutura de baixo nível do sistema de arquivos FAT12 do MSX (manipulação de bytes da FAT, geometria dos clusters, parsing de entradas de diretório, manipulação de timestamps do MSX e busca de espaço livre).
- **[msxdisk.pb](msxdisk.pb)**: Código-fonte do executável CLI. Gerencia a interface de linha de comando, analisa argumentos e formata as listagens de arquivos.
- **[MSXDiskDLL.pb](MSXDiskDLL.pb)**: Wrapper que permite compilar o módulo `MSXDisk.pbi` em uma DLL padrão de 32 ou 64 bits para ser consumida por outros projetos em C/C++, Python ou Rust.

### Binários Compilados (Windows x86/32-bit)
- **[msxdisk.exe](msxdisk.exe)**: Utilitário de linha de comando pronto para uso.
- **[MSXDisk.dll](MSXDisk.dll)**: Biblioteca dinâmica contendo a lógica central do sistema de arquivos.
- **[MSXDisk.lib](MSXDisk.lib)**: Biblioteca de importação correspondente para desenvolvimento em C/C++.

### Licença e Documentação
- **[LICENSE](LICENSE)**: Texto completo da licença GNU GPL v3.0.
- **[README.md](README.md)**: Este documento informativo.

---

## Como Usar a CLI (`msxdisk.exe`)

A sintaxe geral do utilitário é:
```bash
msxdisk <comando> <imagem_disco.dsk> [argumentos...]
```

### Comandos Disponíveis:

1. **Criar nova imagem**:
   ```bash
   msxdisk create meu_disco.dsk [bootsector.bin]
   ```
   Gera um arquivo `.dsk` formatado de 720KB em branco. Se não for especificado um setor de boot customizado, utiliza o setor de boot padrão embutido.

2. **Listar arquivos**:
   ```bash
   msxdisk list meu_disco.dsk [-l]
   ```
   Lista os arquivos contidos na imagem de disco. O parâmetro `-l` exibe o tamanho exato dos arquivos e os timestamps (data e hora de modificação).

3. **Adicionar arquivos**:
   ```bash
   msxdisk add meu_disco.dsk arquivo1.txt arquivo2.bin
   ```
   Adiciona arquivos locais na imagem de disco. Suporta wildcards locais nativamente no Windows (ex: `msxdisk add meu_disco.dsk *.txt`).

4. **Extrair arquivos**:
   ```bash
   msxdisk extract meu_disco.dsk [-d pasta_destino] [curingas...]
   ```
   Extrai arquivos da imagem de disco. Opcionalmente, permite criar a pasta de destino com `-d` e filtrar a extração por curingas do MSX-DOS (ex: `*.bas`).

5. **Excluir arquivos**:
   ```bash
   msxdisk delete meu_disco.dsk nome_arquivo.ext
   ```
   Exclui o arquivo selecionado da imagem de disco, liberando suas entradas no diretório e seus clusters correspondentes na FAT.

---

## Integração via DLL

A biblioteca `MSXDisk.dll` expõe funções com convenções planas C que aceitam ponteiros de strings UTF-8 null-terminated:
- `CreateMSXDisk(*DiskPath, *BootSectorPath)`
- `OpenMSXDisk(*DiskPath)`
- `CloseMSXDisk()`
- `ExtractMSXFile(*MSXName, *DestPath)`
- `AddMSXFile(*LocalPath, *MSXName)`
- `DeleteMSXFile(*MSXName)`
- `GetMSXDiskError(*Buffer, MaxLen)`
- `GetMSXFileCount()`
- `GetMSXFileInfo(Index, *NameBuffer, NameBufferMaxLen, *Size, *DateTime)`

---

## Licença

Este utilitário é distribuído sob a licença **GNU General Public License v3.0**. Veja o arquivo `LICENSE` para mais detalhes.
