# Formato binário `.DBF` do dBase II — notas de engenharia reversa

> Confirmado e validado (2026-08-07) contra um arquivo `.DBF` real — decodificado campo a campo e
> registro a registro, não só reconhecido. Fonte: `sc2/msx/msxdos1.dsk` (disco MSX-DOS local, achado ao
> lado do material do SuperCalc 2 mas sem relação com ele), arquivo `PESSOAL.DBF` — uma tabela de
> funcionários com nome/cargo/salário/data de admissão.

## Como foi validado

Extraído com a própria ferramenta desta IDE:

```powershell
editor\PaleoBasic.exe --diskmanipulator extract sc2\msx\msxdos1.dsk -d sc2\extracted pessoal.dbf
```

O arquivo é pequeno (1024 bytes, 6 registros) e todo o conteúdo é texto legível — deu pra decodificar
campo a campo e **conferir contra o texto visível no próprio hexdump** (nomes de pessoas, cargos,
salários, datas), sem precisar de nenhuma outra fonte externa. Um harness descartável confirmou o
formato inteiro, registro a registro:

```
Registro 0: [marco antonio] [desenhista] [23000] [77/07]
Registro 1: [luis carlos] [contador] [21000] [78/12]
Registro 2: [maria cecilia] [pedagoga] [20000] [81/06]
Registro 3: [maria beatris] [psicologa] [19000] [82/10]
Registro 4: [julio cesar] [gerente] [30000] [87/04]
Registro 5: [paulo sergio] [engenheiro] [25000] [82/09]
```

## Formato confirmado

### Cabeçalho primário (offset `000000h`, 8 bytes)

| Offset | Tamanho | Campo | Observado em `PESSOAL.DBF` |
|---|---|---|---|
| `00h` | 1 | Versão/tipo de arquivo — `02h` = dBase II | `02h` |
| `01h`-`02h` | 2 (LE) | Número de registros | `06h 00h` = 6 (bate com as 6 linhas reais) |
| `03h`-`05h` | 3 | Data de última atualização — valores `05h 13h 11h` presentes, ordem exata dos bytes (YY/MM/DD vs. outra permutação) **não confirmada** | não decifrado |
| `06h`-`07h` | 2 (LE) | Tamanho de cada registro de dados, em bytes (inclui o byte de flag de exclusão) | `24h 00h` = 36 (bate com `1 + 15 + 10 + 5 + 5`) |

### Descritores de campo (offset `000008h` em diante, 16 bytes cada, até 32)

Cada descritor:

| Deslocamento dentro do descritor | Tamanho | Campo |
|---|---|---|
| `+0` | 11 | Nome do campo, ASCII, terminado em `NUL`, resto preenchido com `00h` |
| `+11` | 1 | Tipo: `43h`='C' (Character), `4Eh`='N' (Numeric) — só esses dois tipos apareceram na amostra |
| `+12` | 1 | Tamanho do campo, em bytes |
| `+13`-`+15` | 3 | Reservado (valores variam: `b9 70 00`, `c8 70 00`, `d2 70 00`, `d7 70 00` — palpite: parte baixa de um ponteiro de memória da sessão de edição original, sem relevância pra releitura, mesma categoria de "lixo de sessão" suspeitada no cabeçalho do `.CAL` do SuperCalc — ver `docs/reference/supercalc2-cal-format.md`) |

A lista termina com o **byte terminador `0Dh`** (`\r`) na posição onde o próximo descritor começaria —
confirmado em `PESSOAL.DBF`: 4 descritores (`NOME` C/15, `CARGO` C/10, `SALARIO` N/5, `DATADM` C/5)
ocupam `000008h`-`000047h` (4×16=64 bytes), e o byte em `000048h` é exatamente `0Dh`.

### Início fixo da seção de dados: offset `000209h` (521)

**Sempre** offset 521, independente de quantos campos o arquivo realmente tem — confirma a hipótese de
que o formato reserva espaço fixo pra até **32 descritores de campo** (o limite clássico do dBase II),
mesmo que menos estejam em uso: `8 (cabeçalho) + 32×16 (slots de descritor) + 1 (terminador) = 521`.
Em `PESSOAL.DBF` só 4 dos 32 slots têm dado de verdade; os outros 28×16=448 bytes entre o terminador
(`000048h`+1) e o início dos dados (`000209h`) ficam zerados.

### Registros de dados (offset `000209h` em diante)

Cada registro = **1 byte de flag** (`20h`=espaço = ativo; convenção dBase padrão, `2Ah`='*' = excluído,
não observado na amostra) seguido pelos valores de cada campo **na ordem dos descritores**, cada um
ocupando exatamente o tamanho declarado no descritor (`+12`), sem separador entre campos, texto
alinhado à esquerda e preenchido com espaço até o tamanho declarado (campo `C`); campo numérico (`N`)
observado também como texto ASCII alinhado à esquerda no exemplo (`"23000"`, 5 caracteres — não deu pra
confirmar se `N` sempre é ASCII ou se existe uma variante binária, já que só apareceu esse um caso).

### Fim dos dados

Byte `1Ah` logo após o último registro (mesma convenção CP/M de fim-de-arquivo já vista no `.CAL` do
SuperCalc 2 — reforça que é um padrão comum da época, não coincidência), seguido por `FFh` até o fim do
espaço alocado no disco (preenchimento de setor não usado, não faz parte do formato em si).

## Não confirmado / fora do escopo desta amostra

- **Ordem exata dos bytes de data** (`03h`-`05h`) — só uma amostra disponível, sem outra data conhecida
  pra cruzar.
- **Byte de flag de registro excluído** (`2Ah`) — nenhum registro excluído na amostra.
- **Campos de outros tipos** (`L`=lógico, `D`=data, `M`=memo — dBase II/III costumam ter esses também)
  — só `C` e `N` apareceram em `PESSOAL.DBF`.
- **Os 3 bytes reservados de cada descritor** (`+13`-`+15`) — valores plausíveis de serem lixo de sessão,
  não confirmados.

## Implementado no Editor Hexa

`editor/HexEditorGui.pbi` (`HexEd_DescribeFile`) reconhece `.DBF` (extensão + byte `02h`) e decodifica
os descritores de campo (nome/tipo/tamanho) pro resumo mostrado — não decodifica os registros de dados
em si (isso ficaria mais apropriado numa ferramenta dedicada tipo o gerenciador de disco, se algum dia
fizer sentido: um "visualizador de tabela dBase" dentro da IDE). A extensão `.dbf` é exigida junto com o
byte `02h` porque, sozinho, um único byte de assinatura é fraco demais pra confiar (diferente da
assinatura de 14 bytes do SuperCalc 2 ou dos bytes mágicos `FEh`/`FFh` já usados nos formatos nativos da
IDE).
