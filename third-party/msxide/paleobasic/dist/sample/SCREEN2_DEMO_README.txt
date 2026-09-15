# Screen 2 Demo Assembly - Instruções de Compilação e Uso

## Arquivo: `screen2_demo.asm`

Este é um programa Assembly Z80 para MSX que demonstra:
- Exibição de mensagens em SCREEN 0
- Transição para SCREEN 2 (modo gráfico 256x192 pixels)
- Desenho de um quadrado azul (100x100 pixels) com centro na tela
- Retorno ao BASIC

## Compilação com Nestor80 (N80)

### Pré-requisitos
- Nestor80 instalado (compatível com MACRO-80/M80)
- .NET Runtime 6.0+

### Comando de Compilação

```powershell
# Compilar o arquivo Assembly para binário
.\nestor80\N80\bin\Release\net6.0\N80.exe sample\screen2_demo.asm -o sample\screen2_demo.bin

# Ou, se tiver adicionado ao PATH:
N80 sample\screen2_demo.asm -o sample\screen2_demo.bin
```

### Saída Esperada
- Arquivo: `sample/screen2_demo.bin`
- Tamanho: ~500-1000 bytes
- Endereço de carregamento: 0xC000
- Endereço de execução: 0xC000

## Uso no MSX-BASIC

### Carregar e Executar

```basic
10 CLEAR 200,&HC000
20 BLOAD "SCREEN2_DEMO.BIN",R
30 CALL &HC000
```

Ou em uma única linha:
```basic
CLEAR 200,&HC000: BLOAD "SCREEN2_DEMO.BIN",R: CALL &HC000
```

### O que o programa faz

1. **Mensagem Inicial**: Toca 3 beeps rápidos para indicar inicio
2. **Aguarda Tecla**: Toca um beep e aguarda você pressionar uma tecla
3. **Alterna para SCREEN 2**: Muda o modo gráfico para 256x192 pixels
4. **Desenha Quadrado**: Desenha um quadrado azul (100x100 pixels) com centro na tela
5. **Aguarda Tecla**: Novo beep, aguardando pressionar tecla
6. **Retorna ao BASIC**: Restaura SCREEN 0 e volta para o BASIC

## Especificações Técnicas

### Endereços de Memória
- **Carregamento**: 0xC000 (acima da área de dados padrão do BASIC)
- **Execução**: 0xC000
- **Stack**: Preservado (salvo e restaurado)

### SCREEN 2 (Modo Gráfico)
- **Resolução**: 256 x 192 pixels
- **Cores**: 8 cores (0-7)
- **Cor Usada**: Azul claro (cor 3)
- **Quadrado**: 100x100 pixels, centralizado

### Registros VDP Configurados

| Registro | Valor | Descrição |
|----------|-------|-----------|
| 0 | 0x00 | Modo |
| 1 | 0xC0 | Display + SCREEN 2 |
| 2 | 0x05 | Name Table em 0x0800 |
| 3 | 0x80 | Color Table em 0x2000 |
| 4 | 0x00 | Pattern Table em 0x0000 |
| 7 | 0x0F | Cores (branco em preto) |

## Modo de Compatibilidade

O programa é compatível com:
- ✅ Nestor80 (principal)
- ✅ MACRO-80 (M80)
- ✅ Microsoft ASM80
- ✅ Sjasm (com pequenas adaptações)

O programa **não usa** recursos avançados, apenas:
- `ORG` para definir endereço de carga
- Rótulos (`START`, `.beep_loop`, etc.)
- Instruções Z80 básicas
- `OUT`/`IN` para acesso às portas

## Troubleshooting

### "File not found" ao compilar
- Verifique se o arquivo `screen2_demo.asm` está em `sample/`
- Use caminhos relativos corretos

### Compilação falha com erro de sintaxe
- Verifique se está usando Nestor80, não o antigo MACRO-80
- Certifique-se de que não há caracteres especiais incorretos no arquivo

### Programa não roda no MSX
1. Verifique se compila sem erros
2. Confirme que BLOAD carregou em 0xC000: `PRINT HEX$(&HC000)`
3. Tente desde zero: `CLEAR 200,&HC000: BLOAD "SCREEN2_DEMO.BIN",R: CALL &HC000`

### Volta ao BASIC com erro
- O programa faz `RET`, deveria voltar ao BASIC normalmente
- Se travar, reinicie o emulador/MSX

## Notas Adicionais

- O programa preserva registros e pilha
- Restaura SCREEN 0 antes de retornar
- Não modifica variáveis do BASIC
- Seguro para usar com BASIC carregado

## Próximos Passos

Para expandir este programa:
1. Adicionar mais linhas/formas geométricas
2. Implementar preenchimento (fill)
3. Adicionar animação
4. Usar interrupção para entrada de teclado
5. Implementar editor simples gráfico

## Referências

- Nestor80: https://github.com/konamiman/Nestor80
- MSX Assembly Documentation
- VDP (Video Display Processor) Reference
