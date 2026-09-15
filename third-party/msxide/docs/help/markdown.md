# Markdown

Referência básica de formatação Markdown - o formato de texto usado pelos arquivos `.md` do editor
embutido do msxIDE (`Arquivo -> Novo Arquivo MD`, ou abrindo qualquer `.md` existente). Ponto de partida
enxuto, com os comandos mais usados - cresce aos poucos conforme for precisando de mais.

## O que o msxIDE já desenha com destaque de verdade

O visualizador/preview do msxIDE (o mesmo motor que já renderiza toda essa Ajuda) reconhece e colore
de verdade:

- **Cabeçalhos** (`#` até `######`) - cor e sublinhado por nível.
- **`código`** (crases simples) e blocos ` ``` ` (crases triplas) - cor destacada, monoespaçado.
- **Listas** (`-`/`*` e `1.`/`2.`) - marcador recolorido.
- **Tabelas** (`|coluna|coluna|`) - desenhadas com bordas de verdade (`┌│┼└` etc.), não só o texto cru.
- **`**negrito**`** - intensidade de cor diferente ao vivo.

**O que ainda é só texto literal** (sem highlight especial nesta versão): links `[texto](url)` (aparecem
com colchetes/parênteses mesmo, não ficam clicáveis), imagens `![alt](url)`, *itálico* (o console do
msxIDE não tem itálico de verdade - por enquanto vira texto normal), `~~riscado~~`, listas aninhadas/
tarefas `- [ ]`, linha horizontal `---` (aparece como um traço comum, não uma régua desenhada).

## Comandos básicos de formatação

### Cabeçalhos

```
# Título principal
## Seção
### Subseção
```

Até 6 níveis (`#` a `######`) - quanto menos `#`, maior o cabeçalho.

### Ênfase

```
**negrito**
*itálico* (ou _itálico_)
***negrito e itálico***
```

### Listas

```
- Item sem ordem
- Outro item
* Também funciona com asterisco

1. Item numerado
2. Outro item numerado
```

### Código

Uma palavra ou trecho curto, entre crases simples: `` `MON>PAGE` ``.

Bloco de código (várias linhas), entre crases triplas:

````
```
10 PRINT "OI"
20 GOTO 10
```
````

### Citação

```
> Texto citado, indentado e destacado.
```

### Link e imagem

```
[texto do link](https://exemplo.com)
![texto alternativo](caminho/da/imagem.png)
```

### Linha horizontal

```
---
```

### Tabela

```
| Comando | Função           |
|---------|------------------|
| `PAGE`  | Mostra o mapa    |
| `XCL`   | Calculadora      |
```

A primeira linha é o cabeçalho; a segunda (`|---|---|`) marca onde termina o cabeçalho e começa o corpo
da tabela - sem ela, a tabela não é reconhecida como tabela.

## O editor de `.md` do msxIDE

`Arquivo -> Novo Arquivo MD` (ou abrir um `.md` existente) abre o arquivo no editor de texto normal,
com um recurso a mais: **F7** alterna entre três modos de visualização:

1. **Edição simples** - só o texto cru, editável, sem preview (o padrão ao abrir).
2. **Dividido** - metade esquerda com o texto editável, metade direita com o preview renderizado ao
   vivo (atualiza a cada tecla digitada).
3. **Somente leitura** - a janela inteira mostra só o preview renderizado, sem editar nada (útil pra só
   ler/revisar um documento já pronto).

`F7` de novo volta pro modo 1, fechando o ciclo. Arquivos `.md` também entram no sistema de projetos
(`.msxproj`) junto com o código BASIC/Assembly - dá pra distribuir a documentação do projeto inteira
dentro do mesmo pacote.

**Nota:** arquivos `.md` não podem ser compilados (`Compilar` mostra um aviso e não faz nada) - são só
texto/documentação, não código-fonte.
