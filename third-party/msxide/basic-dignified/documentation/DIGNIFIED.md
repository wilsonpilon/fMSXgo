# Dignified Quick Reference

## Indice

- [Visao Geral](#visao-geral)
- [Sintaxe Basica](#sintaxe-basica)
- [Labels e Fluxo](#labels-e-fluxo)
- [Defines](#defines)
- [Variaveis](#variaveis)
- [Proto-funcoes](#proto-funcoes)
- [Comentarios e Toggles](#comentarios-e-toggles)
- [Operadores](#operadores)
- [Observacoes](#observacoes)

## Visao Geral

Dignified e uma forma moderna de escrever BASIC classico sem numeros de linha.
O codigo e convertido para BASIC classico por ferramentas da suite Basic Dignified.

## Sintaxe Basica

- Separe comandos, funcoes e variaveis com espacos para melhor legibilidade.
- O arquivo deve terminar com uma linha em branco.
- Indentacao com espacos e recomendada.

## Labels e Fluxo

- Labels normais: {inicio}
- Label de auto-referencia: {@}
- Loop label: loop{ ... }
- Saida de loop label: exit

## Defines

- Define simples: define [nome][conteudo]
- Define com parametro: define [pk]poke 100,[10]]
- Uso com argumento: [pk](30)
- Uso com padrao: [pk]

## Variaveis

- Variaveis longas sao permitidas e convertidas para nomes curtos no BASIC classico.
- Declaracao explicita: declare variavel:va
- Reserva de nome curto: declare zz,xv,cd
- Prefixo ~ preserva nome longo quando o alvo suporta.

## Proto-funcoes

- Definicao: func .nome(arg1,arg2)
- Retorno: ret valor
- Chamada: .nome(10,20)
- Chamada com atribuicao: a,b = .nome(10)

## Comentarios e Toggles

- Comentario removido: ## comentario
- Comentario mantido: ' comentario
- Bloco removido: ### ... ###
- Bloco mantido: '' ... ''
- Toggle de linha/bloco: #debug, keep #debug

## Operadores

- Compostos: += -= \*= /= ^=
- Incremento/decremento: ++ --
- Booleanos: true false
- Logicos: and or xor not imp eqv

## Observacoes

Este documento e um resumo rapido para consulta dentro do editor.
Para referencia completa, consulte BASIC_DIGNIFIED.md.
