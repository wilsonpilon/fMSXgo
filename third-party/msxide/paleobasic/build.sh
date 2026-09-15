#!/usr/bin/env bash
#
# build.sh — compila o executavel do MSX BASIC+Z80 IDE (src/editor/BadigEditor.pb)
# usando o PureBasic Compiler para Linux (pbcompiler), gerando
# dist/PaleoBasic, tipicamente rodado de
# dentro do WSL (Windows Subsystem for Linux) apontando pro mesmo checkout do
# repositorio (ex.: /mnt/c/dos/msxbasica).
#
# Contraparte Linux do build.ps1 (Windows/pbcompiler.exe) — mesmo espirito,
# mesmas opcoes de linha de comando, adaptado para bash + o compilador Linux.
#
# O caminho do pbcompiler e resolvido nesta ordem de prioridade:
#   1) Opcao -C / --compiler na linha de comando
#   2) Valor "CompilerPath" gravado em build.config.linux.json (ao lado deste
#      script; arquivo proprio, separado do build.config.json do Windows, pra
#      nao pisar um no config do outro)
#   3) "pbcompiler" encontrado no PATH
#   4) Alguns caminhos padrao comuns de instalacao do PureBasic no Linux
# Quando o caminho e informado via -C/--compiler, ele e salvo em
# build.config.linux.json para as proximas execucoes.
#
# Versao e build sao embutidas no executavel em tempo de compilacao via
# -co/--constant do pbcompiler (constantes #App_Version/#App_Build/
# #App_BuildDate em editor/BadigEditor.pb, exibidas em Ajuda -> Sobre...) —
# mesmo mecanismo do build.ps1, so que calculado aqui em bash puro
# (date/printf) em vez de [DateTime]::UtcNow do PowerShell.
#
# IMPORTANTE: a sintaxe de linha de comando do pbcompiler Linux e diferente da
# do pbcompiler.exe do Windows — flags de hifen (-o/-q/-cl/-co), nao "/FLAG"
# (confirmado rodando "pbcompiler -h" real num WSL com PureBasic instalado,
# 2026-07-29): -o/--output (saida), -q/--quiet, -cl/--console (equivalente ao
# /CONSOLE do Windows — "-c" sozinho e --commented, outra coisa), -co/
# --constant Name=Value (um par por flag, mesmo espirito do /CONSTANT do
# Windows). Nao ha opcao "-h"/"--help" que aceite abreviacao de "--icon" nem
# nada parecido: /ICON (embutir paleobasic.ico como recurso do executavel) e um
# recurso especifico de PE/Windows sem equivalente aqui, entao esta build nao
# tenta embutir icone nenhum (ExtractIconEx em App_ApplyWindowIcon(),
# BadigEditor.pb, tambem e API do Windows e so roda nesse OS).
#
# Exemplos:
#   ./build.sh
#   ./build.sh -C "/home/usuario/pb/compilers/pbcompiler"
#   ./build.sh --compiler "/home/usuario/pb/compilers/pbcompiler" --run
#   ./build.sh -V "7.33.9" -R
#   ./build.sh -H
#   ./build.sh -D

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat <<'EOF'
Uso: build.sh [opcoes]

Compila (e opcionalmente executa) o MSX BASIC+Z80 IDE via PureBasic Compiler
para Linux (pbcompiler). Pensado para rodar dentro do WSL, apontando pro mesmo
checkout do repositorio usado pelo build.ps1 no Windows.

Opcoes:
  -C, --compiler <caminho>   Caminho para o binario pbcompiler (Linux). Fica
                              salvo em build.config.linux.json para as
                              proximas execucoes.
  -R, --run                  Executa o programa apos compilar com sucesso.
  -H, --help                 Mostra esta ajuda e sai.
  -V, --version <versao>     Versao embutida no executavel (padrao: 7.33.9).
  -i, --sourcefile <arquivo> Arquivo fonte a compilar
                              (padrao: src/editor/BadigEditor.pb).
  -o, --outputexe <arquivo>  Caminho do executavel de saida
                              (padrao: dist/PaleoBasic).
  -D, --distribute           Depois de compilar com sucesso, atualiza dist/editor/
                              com os recursos de resource/ (fontes, imagens de
                              ajuda) e copia README.md/docs/MANUAL.md/LICENSE/
                              paleobasic.png pra dist/. NAO apaga dist/sample/
                              nem dist/projects/ (sao conteudo versionado).

Exemplos:
  ./build.sh
  ./build.sh -C "/home/usuario/pb/compilers/pbcompiler"
  ./build.sh --compiler "/home/usuario/pb/compilers/pbcompiler" --run
  ./build.sh -V "7.33.9" -R
  ./build.sh -D
EOF
}

# Defaults
HELP=0
COMPILER=""
RUN=0
VERSION="7.33.9"
SOURCE_FILE="$SCRIPT_DIR/src/editor/BadigEditor.pb"
OUTPUT_EXE="$SCRIPT_DIR/dist/PaleoBasic"
DISTRIBUTE=0

while [ $# -gt 0 ]; do
    case "$1" in
        -H|--help)
            HELP=1
            ;;
        -C|--compiler)
            shift
            [ $# -gt 0 ] || { echo "Falta o caminho depois de -C/--compiler." >&2; exit 1; }
            COMPILER="$1"
            ;;
        -R|--run)
            RUN=1
            ;;
        -V|--version)
            shift
            [ $# -gt 0 ] || { echo "Falta a versao depois de -V/--version." >&2; exit 1; }
            VERSION="$1"
            ;;
        -i|--sourcefile)
            shift
            [ $# -gt 0 ] || { echo "Falta o caminho depois de -i/--sourcefile." >&2; exit 1; }
            SOURCE_FILE="$1"
            ;;
        -o|--outputexe)
            shift
            [ $# -gt 0 ] || { echo "Falta o caminho depois de -o/--outputexe." >&2; exit 1; }
            OUTPUT_EXE="$1"
            ;;
        -D|--distribute)
            DISTRIBUTE=1
            ;;
        *)
            echo "Aviso: parametro desconhecido: $1 (use -H ou --help para ver as opcoes)." >&2
            ;;
    esac
    shift
done

if [ "$HELP" -eq 1 ]; then
    show_help
    exit 0
fi

CONFIG_PATH="$SCRIPT_DIR/build.config.linux.json"

# Parsing/gravacao minimos de JSON (um unico campo "CompilerPath") sem
# depender de jq/python3 — o arquivo e sempre gerado por este proprio script,
# entao o formato e conhecido e fixo.
read_config_compiler_path() {
    if [ -f "$CONFIG_PATH" ]; then
        sed -n 's/.*"CompilerPath"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' "$CONFIG_PATH" | head -n 1
    fi
}

write_config_compiler_path() {
    printf '{\n    "CompilerPath": "%s"\n}\n' "$1" > "$CONFIG_PATH"
}

DEFAULT_CANDIDATE_PATHS=(
    "$HOME/pb/compilers/pbcompiler"
    "$HOME/purebasic/compilers/pbcompiler"
    "$HOME/PureBasic/compilers/pbcompiler"
    "/opt/pbcompiler/compilers/pbcompiler"
    "/opt/PureBasic/compilers/pbcompiler"
    "/usr/local/PureBasic/compilers/pbcompiler"
)

if [ -n "$COMPILER" ]; then
    COMPILER_PATH="$COMPILER"
    write_config_compiler_path "$COMPILER_PATH"
    echo "Caminho do compilador salvo em $CONFIG_PATH"
else
    COMPILER_PATH="$(read_config_compiler_path || true)"
    if [ -z "$COMPILER_PATH" ]; then
        if command -v pbcompiler >/dev/null 2>&1; then
            COMPILER_PATH="$(command -v pbcompiler)"
        else
            for candidate in "${DEFAULT_CANDIDATE_PATHS[@]}"; do
                if [ -x "$candidate" ]; then
                    COMPILER_PATH="$candidate"
                    break
                fi
            done
        fi
    fi
fi

if [ -z "${COMPILER_PATH:-}" ] || [ ! -x "$COMPILER_PATH" ]; then
    echo "Erro: pbcompiler (Linux) nao encontrado em: ${COMPILER_PATH:-<vazio>}" >&2
    echo "Configure o caminho correto via -C/--compiler ou edite $CONFIG_PATH." >&2
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Erro: arquivo fonte nao encontrado: $SOURCE_FILE" >&2
    exit 1
fi

OUTPUT_DIR="$(dirname "$OUTPUT_EXE")"
mkdir -p "$OUTPUT_DIR"

# Build = data/hora UTC de compilacao, segundos desde a epoch Unix, em hex —
# mesmo esquema do build.ps1, so que calculado com `date` em vez de
# [DateTimeOffset]::ToUnixTimeSeconds().
BUILD_EPOCH="$(date -u +%s)"
BUILD_HEX="$(printf '%08X' "$BUILD_EPOCH")"
BUILD_DATE_TEXT="$(date -u -d "@$BUILD_EPOCH" +"%Y-%m-%d %H:%M:%S") UTC"

echo "Compilador : $COMPILER_PATH"
echo "Fonte      : $SOURCE_FILE"
echo "Saida      : $OUTPUT_EXE"
echo "Versao     : $VERSION"
echo "Build      : $BUILD_HEX ($BUILD_DATE_TEXT)"
echo ""

set +e
"$COMPILER_PATH" "$SOURCE_FILE" -o "$OUTPUT_EXE" -q -cl \
    -co "App_Version=$VERSION" \
    -co "App_Build=$BUILD_HEX" \
    -co "App_BuildDate=$BUILD_DATE_TEXT"
COMPILE_STATUS=$?
set -e

if [ $COMPILE_STATUS -ne 0 ]; then
    echo "Erro: falha na compilacao (codigo $COMPILE_STATUS)." >&2
    exit $COMPILE_STATUS
fi

chmod +x "$OUTPUT_EXE" 2>/dev/null || true

echo "Build concluido: $OUTPUT_EXE"

if [ "$DISTRIBUTE" -eq 1 ]; then
    echo ""
    echo "Atualizando dist/..."

    # dist/ tem conteudo VERSIONADO junto (dist/sample/, dist/projects/,
    # dist/res/) - nao apaga a pasta inteira como a antiga distribute-linux/
    # fazia, so copia por cima os itens gerados/derivados de resource/+src/.
    DIST_DIR="$SCRIPT_DIR/dist"
    DIST_EDITOR_DIR="$DIST_DIR/editor"
    mkdir -p "$DIST_EDITOR_DIR"

    copy_dist_item() {
        local path="$1"
        local dest="$2"
        if [ -e "$path" ]; then
            # Mesmo bug de idempotencia do build.ps1 (ver comentario la): "cp -r origem destino"
            # quando $destino ja existe como pasta copia a origem PRA DENTRO dela em vez de
            # sobrescrever - apaga o destino primeiro quando origem e' pasta e destino ja existe.
            if [ -d "$path" ] && [ -d "$dest" ]; then
                rm -rf "$dest"
            fi
            cp -r "$path" "$dest"
            echo "  incluido: $path -> $dest"
        else
            echo "Aviso: nao encontrado, pulando: $path" >&2
        fi
    }

    copy_dist_item "$SCRIPT_DIR/README.md" "$DIST_DIR/"
    copy_dist_item "$SCRIPT_DIR/docs/MANUAL.md" "$DIST_DIR/"
    copy_dist_item "$SCRIPT_DIR/LICENSE" "$DIST_DIR/"
    copy_dist_item "$SCRIPT_DIR/resource/branding/paleobasic.png" "$DIST_DIR/"
    copy_dist_item "$SCRIPT_DIR/resource/fonts" "$DIST_EDITOR_DIR/"
    copy_dist_item "$SCRIPT_DIR/resource/redbook_images" "$DIST_EDITOR_DIR/"
    copy_dist_item "$SCRIPT_DIR/resource/th2handbook_images" "$DIST_EDITOR_DIR/"
    mkdir -p "$DIST_EDITOR_DIR/tools"
    copy_dist_item "$SCRIPT_DIR/resource/tools/msxbas2rom" "$DIST_EDITOR_DIR/tools/"
    copy_dist_item "$SCRIPT_DIR/resource/tools/n80" "$DIST_EDITOR_DIR/tools/"
    mkdir -p "$DIST_DIR/fossauro"
    copy_dist_item "$SCRIPT_DIR/resource/fossauro_help" "$DIST_DIR/fossauro/help"

    # ROMs do sistema MSX pro Fossauro - mesma logica do build.ps1 (ver
    # comentario la): dist/fossauro roda com CWD = dist/, entao a pasta de
    # ROMs precisa se chamar dist/roms/, nao dist/fossauro/roms/. Fonte
    # canonica em resource/roms/ - copyright proprio, nunca rastreado no git.
    if [ -d "$SCRIPT_DIR/resource/roms" ]; then
        mkdir -p "$DIST_DIR/roms"
        for rom in "$SCRIPT_DIR"/resource/roms/*.ROM; do
            [ -e "$rom" ] && copy_dist_item "$rom" "$DIST_DIR/roms/"
        done
    fi

    echo "dist/ atualizado em: $DIST_DIR"
fi

if [ "$RUN" -eq 1 ]; then
    echo "Executando $OUTPUT_EXE ..."
    "$OUTPUT_EXE" &
fi
