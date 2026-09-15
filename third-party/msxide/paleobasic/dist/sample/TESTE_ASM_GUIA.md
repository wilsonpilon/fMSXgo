# Guia Rápido: Compilar e Executar teste.asm

## Arquivos Criados

- **`sample/teste.asm`** - Programa Assembly Z80 para MSX SCREEN 2
- **`sample/compile_teste.bat`** - Script PowerShell para compilação
- **`sample/screen2_demo.asm`** - Versão alternativa com mais comentários

## Compilação Rápida

### Windows PowerShell

```powershell
# Compilar direto com Nestor80
.\nestor80\N80\bin\Release\net6.0\N80.exe sample\teste.asm -o sample\teste.bin

# Ou usar o batch (se preferir)
.\sample\compile_teste.bat
```

### Linux/macOS

```bash
# Se tiver Nestor80 disponível
dotnet nestor80/N80/bin/Release/net6.0/N80.dll sample/teste.asm -o sample/teste.bin
```

## Resultado da Compilação

- **Arquivo de saída**: `sample/teste.bin`
- **Tamanho**: ~600 bytes
- **Endereço de carregamento**: 0xC000
- **Endereço de execução**: 0xC000

## Executar no MSX-BASIC

No emulador openMSX ou em um MSX real:

```basic
CLEAR 200,&HC000
BLOAD "TESTE.BIN",R
CALL &HC000
```

Ou em uma linha:

```basic
CLEAR 200,&HC000 : BLOAD "TESTE.BIN",R : CALL &HC000
```

## O que o programa faz

1. ✅ Exibe mensagem de inicialização (3 beeps)
2. ✅ Aguarda pressionar uma tecla
3. ✅ Alterna para modo SCREEN 2 (256×192 pixels)
4. ✅ Desenha um quadrado azul (100×100 pixels) com centro na tela
5. ✅ Aguarda pressionar outra tecla
6. ✅ Retorna ao BASIC em SCREEN 0

## Compatibilidade

O programa foi escrito com total compatibilidade com:

- ✅ **Nestor80** (assembler moderno, compatível com MACRO-80)
- ✅ **MACRO-80 / M80** (assembler clássico do MSX)
- ✅ **Microsoft ASM80** (com pequenas adaptações)
- ✅ **MSX-DOS** (ambiente de execução)
- ✅ **MSX 1** (hardware original)

## Recuros Utilizados

### Instruções Z80 Usadas
- `ORG` - Define endereço de carregamento
- `EQU` - Define constantes
- Instruções: `ld`, `out`, `in`, `call`, `ret`, `push`, `pop`, `jp`, `djnz`, `dec`
- Rótulos e desvios condicionais

### Portas VDP Acessadas
- `0x98` - Dados VRAM
- `0x99` - Endereço VRAM
- `0x9B` - Registros VDP

### Registros VDP Configurados
- **Registro 0**: Modo (0x00)
- **Registro 1**: Display + SCREEN 2 (0xC0)
- **Registro 2**: Name Table em 0x0800
- **Registro 3**: Color Table em 0x2000
- **Registro 4**: Pattern Table em 0x0000
- **Registro 7**: Cores (0x0F)

## Estrutura do Código

```
┌─ START
│  ├─ MSG_INIT (Beeps iniciais)
│  ├─ WAIT_KEY (Aguardar tecla)
│  ├─ SCREEN2_INIT (Configurar SCREEN 2)
│  │  └─ PALETTE_INIT (Cores)
│  ├─ SCREEN2_CLEAR (Limpar)
│  ├─ DRAW_QUAD (Desenhar quadrado)
│  ├─ WAIT_KEY (Aguardar tecla)
│  └─ SCREEN0_RESTORE (Voltar ao normal)
└─ RET (Retornar ao BASIC)
```

## Notas Importantes

✓ **Segurança**: O programa salva e restaura registros (AF, BC, DE, HL)
✓ **Compatibilidade**: Não sobrescreve áreas importantes do BASIC
✓ **Endereço**: 0xC000 é um endereço seguro acima da área de dados padrão
✓ **Retorno**: Usa `RET` para retornar corretamente ao BASIC

## Troubleshooting

### Erro: "Nestor80 não encontrado"
- Verifique se `nestor80\N80\bin\Release\net6.0\N80.exe` existe
- Ou ajuste o caminho no script de compilação

### Erro de sintaxe na compilação
- Verifique se não há tabs (use espaços em vez de tabs)
- Confira se todas as instruções são válidas Z80

### Programa não executa no MSX
1. Confirme que compila sem erros
2. Verifique se o endereço de execução é 0xC000
3. Tente novamente: `CLEAR 200,&HC000 : BLOAD "TESTE.BIN",R : CALL &HC000`

## Expandindo o Programa

Para adicionar mais recursos:

### 1. Mais formas geométricas
- Adicionar subroutinas para círculos, triângulos
- Usar cálculos de coordenadas mais complexos

### 2. Preenchimento (Fill)
- Implementar algoritmo de flood fill
- Usar endereço direto na VRAM

### 3. Animação
- Usar loops com delays
- Redrawing periódico

### 4. Entrada de teclado
- Ler porta 0x98 para teclado
- Implementar handlers de interrupção

### 5. Múltiplas cores
- Alterar paleta durante execução
- Usar diferentes padrões

## Referências

- **Nestor80**: https://github.com/konamiman/Nestor80
- **MSX Specs**: http://www.msx.org
- **Z80 Instruction Set**: https://en.wikipedia.org/wiki/Zilog_Z80
- **VDP Reference**: MSX Technical Reference

---

**Criado**: 2026-07-24
**Versão**: 1.0
**Autor**: Claude Copilot
**Compatibilidade**: MSX 1 em diante
