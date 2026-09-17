# Tokenizador MSX BASIC — Guia do Usuário

> Adaptação, para o nosso projeto em PureBasic, da documentação original do **MSX Basic Tokenizer** (`msxbatoken`), parte da suíte [Basic Dignified](https://github.com/farique1/basic-dignified) de farique1. Este módulo já era exclusivo do MSX no projeto original, então nada precisou ser removido por conta do CoCo — só a mecânica de invocação (que era via `python msxbatoken.py` no terminal) foi adaptada para funcionar dentro da nossa IDE.

---

## O que é

O Tokenizador MSX BASIC converte um programa MSX BASIC em **ASCII** (texto puro, o `.amx` gerado pelo módulo Basic Dignified, ou qualquer `.amx`/`.asc` escrito à mão) para o formato **tokenizado/binário** (`.bmx`) que o MSX carrega muito mais rápido que o ASCII.

Na nossa IDE, ele funciona tanto **integrado** ao fluxo normal (você escreve em Dignified, compila, e a IDE já entrega o `.bmx` pronto) quanto de forma **avulsa** — por exemplo, se você já tem um `.amx`/`.asc` pronto (escrito à mão, ou vindo de outra fonte) e só quer tokenizá-lo, sem passar pela conversão Dignified.

## Arquivo de listagem (list file)

Além da tokenização, o módulo pode exportar um **arquivo de listagem** (`.lmx`), no mesmo espírito dos listamentos gerados por assemblers: mostra os tokens lado a lado com o código ASCII original e algumas estatísticas.

O formato de cada linha é:

```
80da: ee80 7800 44 49 ef 50 49 f2 1f 41 31 41 59 26 53 60 00 00        120 DI=PI-3.1415926536
[-1-] [---2---] [----------------------3----------------------]        [---------4----------]
```

1. **Bytes 1-2**: o endereço de memória da linha no MSX BASIC.
2. **Bytes 3-6**: os quatro primeiros bytes, com o endereço da **próxima linha** e o **número da linha**.
3. **Bytes 7 em diante**: a linha já **tokenizada**.
4. A linha correspondente em **ASCII**, para conferência.

> O arquivo de listagem (`.lmx`) usa o mesmo destaque de sintaxe do MSX BASIC clássico já usado pelo restante da IDE — abra-o no próprio editor para conferir a tokenização com cores.

## Processo de tokenização passo a passo

A IDE pode exibir a tokenização acontecendo **byte a byte, linha a linha** — útil para depurar o próprio tokenizador ou para entender exatamente como um comando específico é convertido. Por exemplo, para:

```
10 PRINT "WH"
20 GOTO 10
```

A saída passo a passo seria:

```
|10 PRINT "WH"
0a00|PRINT "WH"
0a0091| "WH"
0a009120|"WH"
0a00912022|WH"
0a0091202257|H"
0a009120225748|"
0a00912022574822|
|20 GOTO 10
1400|GOTO 10
140089| 10
140089200e0a00|
```

## Como usar na IDE

- **Modo integrado**: ao compilar/rodar um projeto Dignified normalmente, a IDE chama o tokenizador automaticamente quando a saída tokenizada (`.bmx`) é solicitada nas configurações do projeto — você não precisa fazer nada além do fluxo normal.
- **Modo avulso**: há um utilitário próprio no menu de ferramentas para tokenizar um arquivo `.amx`/`.asc` isolado (escrito à mão ou vindo de fora), sem passar pelo Basic Dignified. Esse modo é útil para tokenizar listagens digitadas de revistas antigas, por exemplo.

### Opções do tokenizador avulso

Quando usado de forma integrada (dentro do fluxo normal do projeto), essas opções são melhor deixadas por conta da IDE, que já ajusta tudo automaticamente. No **modo avulso**, ficam disponíveis no próprio utilitário:

| Opção | O que faz | Padrão |
|---|---|---|
| Apagar o ASCII de origem | Remove o arquivo `.amx`/`.asc` depois que a versão tokenizada é salva com sucesso | Desativado |
| Exportar listagem | Gera o arquivo de listagem (`.lmx`). O número indica quantos bytes são mostrados por linha (máximo 32) | 16 |
| Nível de detalhe (verbose) | `0` = silencioso, `1` = +erros, `2` = +avisos, `3` = +cabeçalhos, `4` = +subcabeçalhos, `5` = +tokenização completa | `3` |

Se nenhum arquivo de destino for definido, o nome do arquivo de origem é reaproveitado com a extensão apropriada (`.bmx`).

## Observações e limitações conhecidas

O tokenizador original foi testado com mais de 100 programas aleatórios vindos de revistas e outras fontes, além de programas criados especificamente para testar casos extremos — mas ainda existem alguns casos de borda não cobertos. **Vale ter cuidado**, principalmente com código digitado à mão ou vindo de fontes não confiáveis.

Discrepâncias conhecidas em relação à tokenização real do MSX (a maioria envolvendo **código com erro**):

- **Notação binária `&b`**: no MSX real, tudo depois de `&b` é tratado como caractere até encontrar um comando tokenizado. Nossa implementação (herdada do tokenizador original) só reconhece `0` e `1`, voltando ao parsing normal ao encontrar outro caractere.
- **Espaços no fim da linha**: são removidos na tokenização. O MSX real só remove esses espaços se o programa foi digitado na máquina — não remove se carregado de um arquivo ASCII.
- **Números de linha "estourados" em instruções de desvio** (precedidos pelo byte `0e`): o MSX real parece dividir o número; aqui, isso gera um erro em vez de ser dividido.
- **Erros de sintaxe** em geral podem gerar resultados bem diferentes dos que o MSX real produziria — não confie na tokenização como validação de que o programa está sintaticamente correto.

### Erros que interrompem a conversão

- Número de linha muito alto, números de linha fora de ordem, linhas que não começam com número, linhas de desvio (`GOTO`/`GOSUB`/etc.) apontando para número de linha muito alto.
- Números maiores que o permitido pelo tipo explícito da variável (em alguns casos são convertidos para cima, como o próprio MSX faz).

---

> Este utilitário é parte da mesma base do **módulo Basic Dignified** (veja `BADIG-USER.md`) — o fluxo normal de trabalho é escrever em Dignified e deixar a IDE cuidar da tokenização; use o modo avulso apenas quando precisar tokenizar um ASCII já pronto, vindo de fora do fluxo Dignified.
