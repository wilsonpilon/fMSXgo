# Fossauro no Paleobasic

Desde 2026-08-18 a IDE principal sabe **iniciar** o Fossauro como processo externo - sem incorporá-lo
(a licença não-comercial do Fossauro é incompatível com a do Paleobasic, então ele nunca é linkado
nem entra no pacote de distribuição, mesma relação que o openMSX já tem).

## Configurar -> Fossauro...

Tela de configurações padrão, usadas toda vez que **Executar -> Fossauro...** é acionado:

- **Caminho do executável**: tenta auto-detectar `fossauro/fossauro.exe` como pasta irmã de
  `editor/` se o campo estiver vazio - ainda precisa clicar **Salvar** uma vez, mesma exigência de
  qualquer ferramenta externa configurável nesta IDE (openMSX, asMSX, N80, MSXBas2Rom).
- **Tipo de máquina**: MSX1 / MSX2 / MSX2+.
- **RAM**: 64 / 128 / 256 / 512 / 1024 KB.
- **VRAM**: 16 / 32 / 64 / 128 / 192 KB.
- **Temporização PAL/NTSC**.
- **Log verboso** (`-verbose`, grava `fossauro.log`).
- **Cartucho padrão** (opcional) - carregado no Slot A ao iniciar.

As configurações são gravadas em `fossauro_settings.json` (ao lado do executável da IDE - específico
desta máquina, não versionado).

## Executar -> Fossauro... (F10)

Inicia o executável configurado com as opções acima, como processo independente - sem canal de
controle por pipe (diferente do openMSX), a janela do Fossauro abre e fica rodando por conta própria.
Sem caminho configurado, mostra um erro apontando para **Configurar -> Fossauro...**.

## O que ainda não está exposto aqui de propósito

`-diska`/`-diskb` (disco padrão ao iniciar) e a escala de vídeo 2:1/3:1/4:1 não aparecem na tela de
configuração porque, respectivamente, o controlador de disquete do Fossauro ainda não está ligado ao
boot, e a escala acima de 1:1 tem um bug real de travamento confirmado (ver o tópico "Status atual").
Serão adicionados quando essas limitações forem resolvidas.
