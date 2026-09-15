# Formato binário `.CAL` do SuperCalc 2 MSX — notas de engenharia reversa

> Estudo em andamento (2026-08-07). Cobre só o que foi confirmado contra arquivos reais — nada aqui
> foi adivinhado sem verificação. Fonte dos arquivos: `sc2/msx/*.CAL` (Wilson Pilon, cópia local de um
> projeto pessoal de reescrita do SuperCalc 2 em Go, não versionado por conter software de terceiros —
> ver observação no fim deste arquivo).

## Como isso foi descoberto

`sc2/` é um projeto Go separado do usuário (`sc2msx`) que já lê/grava o formato **SDI** (SuperData
Interchange, texto ASCII) — o formato intermediário que o utilitário original `SDI.COM` usa pra
converter de/para o `.CAL` binário (ver `sc2/internal/spreadsheet/sdi.go`, comentário de cabeçalho com
a estrutura completa do SDI). O leitor de `.CAL` binário direto **não existe** nesse projeto Go ainda
(README do projeto lista como "🔧 Em desenvolvimento").

O avanço decisivo: o disco original `sc2/msx/supercalc2L.dsk` (dump de um disquete real do SuperCalc 2
MSX) contém **os dois formatos do mesmo arquivo lado a lado** — `EXEMPLO.CAL` (binário) e `EXEMPLO.SDI`
(texto, já convertido por alguém usando o `SDI.COM` original antes do dump) — um par binário/texto
verdadeiro, sem precisar rodar o `SDI.COM` num emulador. Extraídos com a própria ferramenta desta IDE:

```powershell
editor\PaleoBasic.exe --diskmanipulator extract sc2\msx\supercalc2L.dsk -d sc2\extracted exemplo.cal exemplo.sdi
```

`sc2/extracted/exemplo.sdi` (texto, 768 bytes) documenta a planilha completa célula a célula — 6 linhas
(cabeçalho de meses JAN..JUN+TOTAL, uma linha em branco, VENDA BRUTA, CUSTO1, CUSTO2, VENDA LIQ., cada
uma com fórmulas `SUM(...)`/subtração e referências entre colunas) — e serviu de referência cruzada
pro hexdump de `exemplo.cal` (1664 bytes).

Outros 5 arquivos `.CAL` reais (`BRKEVN.CAL`, `CHECKS.CAL`, `ORCAMENT.CAL`, `SAMPLE.CAL`, `TENMIN.CAL`,
tamanhos de 1280 a 5120 bytes) foram usados só pra comparação estrutural (confirmar o que é fixo entre
arquivos vs. o que varia com o conteúdo), sem ground truth em texto disponível pra eles.

## Confirmado (validado contra os 6 arquivos reais, usado na detecção do Editor Hexa)

- **Assinatura, offset `000000h`, 22 bytes**: `"SuperCalc ver.  1.00\r\n"` — idêntica byte a byte nos 6
  arquivos. Os primeiros 14 bytes (`"SuperCalc ver."`) já são específicos o bastante pra reconhecer o
  formato sem depender de extensão de arquivo.
- **Título da planilha, offset `000016h`, 80 bytes reservados**: string terminada em `NUL`, resto do
  campo preenchido com `00`. Confirmado com títulos de tamanhos bem diferentes (`"Break Even Analysis"`,
  `"Check Register"`, `"THIS IS A SAMPLE SUPERCALC WORKSHEET"` — 37 chars — até planilhas sem título
  nenhum, `TENMIN.CAL`/`EXEMPLO.CAL`) — em todos os casos a seção de dados começa exatamente no mesmo
  offset (ver próximo item), confirmando que o campo tem tamanho **fixo**, não termina onde o texto
  termina.
- **Início da seção de dados: offset `000300h` (768) fixo em todos os 6 arquivos** — independe do
  tamanho do título e do conteúdo da planilha. Isso ancora um cabeçalho de tamanho fixo (768 bytes)
  antes de qualquer dado de célula.
- **Byte de padding de arquivo: `1Ah`** — usado tanto nos "buracos" zerados do cabeçalho (não, esses são
  `00h`) quanto no preenchimento até o fim do arquivo alocado (visível em `exemplo.cal` do offset
  `00063Ch` até o fim, e em `ORCAMENT.CAL`/outros no mesmo padrão) — mesma convenção do caractere de
  fim-de-arquivo CP/M (`SUB`, `1Ah`), plausível já que o SC2 original roda sobre um ambiente derivado de
  CP/M (MSX-DOS 1 é compatível a nível de chamada). Útil como sinal auxiliar, não como parte do
  cabeçalho.
- **Byte fixo em `000066h` = `1Ah`** — idêntico nos 6 arquivos, logo após o campo de título
  (`000016h`..`000065h`, 80 bytes: `000066h - 000016h = 000050h = 80`). Significado exato desconhecido
  (possivelmente um marcador de fim-de-registro do mesmo estilo do padding acima), mas confirma o limite
  exato do campo de título.

## Ainda não decifrado (não usado na detecção — evitando adivinhar sem confirmação)

- **Bytes `000067h`-`0002FFh`** (~666 bytes entre o fim do título e o início dos dados): contém alguns
  valores não-zero que **variam por arquivo** (ex.: `000067h`-`000069h` é `CFh CFh CFh` em 4 dos 6
  arquivos mas `46h 32h B6h` em `BRKEVN.CAL` e `00h 00h 00h` em `TENMIN.CAL`) — provavelmente
  configurações globais da planilha (formato numérico padrão, largura de coluna padrão, modo de cálculo,
  contador de iteração — os mesmos conceitos que `GDISP-FORMAT`/`COL-FORMAT` documentam no SDI texto,
  ver `sc2/internal/spreadsheet/sdi.go`) ou ponteiros de memória da sessão de edição original (sem
  relevância pra releitura). Não decifrado campo a campo ainda.
- **Layout de cada célula na seção de dados (`000300h` em diante)**: visualmente segue o mesmo conceito
  do SDI texto (tipo da célula + coordenada + valor/fórmula/texto), com registros que parecem
  comprimento-prefixado (ex.: em `BRKEVN.CAL`, offset `000302h`-`000303h` = `23 00` = `0023h` = 35
  bytes, seguido por exatamente um registro de texto de célula terminando 35 bytes depois) — mas o
  mapeamento exato campo a campo (que bytes são linha/coluna, que bytes são o tipo 0/1/-1/-2/-3/-4/-5 do
  SDI, como fórmulas/referências são codificadas em binário) não foi confirmado célula a célula ainda.
  O par `exemplo.cal`/`exemplo.sdi` é o melhor material pra continuar essa parte (planilha pequena, 6
  linhas, com números, texto e fórmulas com referência entre colunas — cobre os casos principais).

## Próximos passos, se for continuar

1. Decodificar `exemplo.cal` campo a campo contra `exemplo.sdi` (já extraídos em `sc2/extracted/`),
   célula por célula, até fechar o formato de registro.
2. Se sobrar ambiguidade, `D:\msx\openMSX\openmsx.exe` está instalado e configurado
   (`editor/badig_settings.json` → `EmulatorPath`) — dá pra gerar mais pares binário/texto rodando
   `SDI.COM` de verdade contra qualquer um dos outros `.CAL` (`BRKEVN`/`CHECKS`/`ORCAMENT`/`SAMPLE`/
   `TENMIN`), usando os discos `sc2/msx/supercalc2*.dsk` (já têm `SDI.COM`/`SDI.OVL` a bordo).
3. Só depois de fechar o formato célula a célula vale a pena decodificar conteúdo de verdade no Editor
   Hexa (hoje só reconhece o arquivo — assinatura, título, onde a seção de dados começa — não lê
   células, ver `editor/HexEditorGui.pbi`).

## Achado colateral: amostra real de dBase II

`sc2/msx/msxdos1.dsk` (disco MSX-DOS separado, sem relação com o SuperCalc) contém `PESSOAL.DBF` — um
arquivo `.DBF` real gerado por dBase II no MSX. Fica registrado aqui porque é exatamente o tipo de
arquivo de amostra que falta pra atacar o reconhecimento de dBase II no Editor Hexa (módulo 17, pedido
do usuário em 2026-08-07 junto com SuperCalc II/WordStar/MSX-Word) — ainda não estudado nesta sessão.

## Sobre `sc2/` no controle de versão

`sc2/msx/` contém software original de terceiros (executáveis `.COM`/`.OVL` do SuperCalc 2 MSX, PDFs de
manuais com copyright, dumps de disquete) — mesma categoria de material que `see/` (ver `.gitignore`),
que já é tratado como cópia local de referência, não conteúdo pra versionar/distribuir com o
repositório. `sc2/` inteiro está hoje **sem entrada no `.gitignore`** (untracked, `git status` mostra
`sc2/` como novo) — vale decidir com o usuário se replica o padrão de `/see/` antes de qualquer commit
que inclua essa pasta.
