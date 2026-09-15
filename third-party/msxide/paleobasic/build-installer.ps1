<#
.SYNOPSIS
    Gera o instalador standalone do PaleoBasic (installer\PaleoBasicSetup.exe).

.DESCRIPTION
    Fluxo completo, nesta ordem:
      1. Roda .\build.ps1 (raiz do repo) pra garantir que dist\ esta fresco
         (os dois executaveis + recursos) - o instalador embute uma copia de
         dist\, entao nunca deve empacotar um build velho.
      2. Gera um manifesto (lista de arquivos a empacotar) via
         "git ls-files dist/" - a mesma lista que o proprio git ja usa pra
         decidir o que e conteudo versionado/distribuivel de dist\ (exclui
         *_settings.json, dist\projects\noname.msxproject, etc. automaticamente,
         ver .gitignore) - evita duplicar essas regras de exclusao aqui e correr
         o risco delas divergirem com o tempo. Usa "-c core.quotepath=false" pra
         nomes de arquivo com acento (ex.: "La sereníssima...mid" em
         dist\editor\tools\msxbas2rom\games\) nao virem escapados em octal
         (\303\255) na saida - confirmado um caso real assim ao testar, o
         arquivo ficava de fora do pacote silenciosamente sem esse flag.
         dist\fossauro.exe e dist\roms\*.ROM sao adicionados a mao (os dois
         gitignored de proposito - fossauro.exe por ser binario grande,
         dist\roms\ por serem ROMs com copyright proprio - mas pedido explicito
         do usuario 2026-08-25: os dois fazem parte do pacote redistribuivel
         mesmo assim, so' nao ficam rastreados no repositorio git).
      3. Compila src\installer\tools\BuildPayloadZip.pb (ferramenta de build,
         usa o Packer nativo do PureBasic - UseZipPacker/AddPackFile - em vez
         de Compress-Archive do PowerShell, mesmo espirito "sem dependencia
         de runtime externo" do resto do projeto) e roda ela, gerando
         src\installer\payload.zip a partir do manifesto.
      4. Compila src\installer\PaleoBasicSetup.pb, que embute payload.zip via
         IncludeBinary (path relativo fixo, por isso o passo 3 sempre grava
         no mesmo lugar) - saida final: installer\PaleoBasicSetup.exe.

    payload.zip fica ~100+ MB (dist\ inteiro: fontes, imagens de ajuda, os
    bundles do msxbas2rom/n80) - o .exe final do instalador fica desse
    tamanho tambem, e' esperado (instalador standalone auto-contido, pedido
    explicito do usuario 2026-08-22 - sem precisar de um .zip separado ao
    lado).

.EXAMPLE
    .\build-installer.ps1
.EXAMPLE
    .\build-installer.ps1 -Version "8.6.0" -Run
#>

param(
    [string]$Version = "8.7.5",
    [switch]$Run,
    [switch]$SkipAppBuild
)

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot

# --- 1. Garante dist\ fresco --------------------------------------------
if (-not $SkipAppBuild) {
    Write-Host "=== Passo 1/4: compilando PaleoBasic + fossauro (build.ps1) ==="
    & (Join-Path $RepoRoot "build.ps1") -V $Version
    if ($LASTEXITCODE -ne 0) {
        Write-Error "build.ps1 falhou (codigo $LASTEXITCODE)."
        exit $LASTEXITCODE
    }
    Write-Host ""
} else {
    Write-Host "=== Passo 1/4: pulado (-SkipAppBuild) - usando dist\ como esta ==="
    Write-Host ""
}

# --- Resolve pbcompiler.exe (mesmo build.config.json de build.ps1) -----
$ConfigPath = Join-Path $RepoRoot "build.config.json"
$CompilerPath = Join-Path $env:PROGRAMFILES "PureBasic\Compilers\pbcompiler.exe"
if (Test-Path $ConfigPath) {
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        if ($config.CompilerPath) { $CompilerPath = $config.CompilerPath }
    } catch {
        Write-Warning "Nao foi possivel ler $ConfigPath - usando o caminho padrao do compilador."
    }
}
if (-not (Test-Path $CompilerPath)) {
    Write-Error "pbcompiler.exe nao encontrado em: $CompilerPath`nRode .\build.ps1 -C <caminho> uma vez pra configurar."
    exit 1
}

# --- 2. Manifesto (git ls-files dist/ + extras nao rastreados) ---------
Write-Host "=== Passo 2/4: gerando manifesto de arquivos (git ls-files dist/) ==="
$InstallerSrcDir = Join-Path $RepoRoot "src\installer"
$ManifestPath = Join-Path $InstallerSrcDir "payload_manifest.txt"

# git escreve nomes de arquivo com acento como UTF-8 de verdade (com
# core.quotepath=false, ver comentario abaixo), mas PowerShell so decodifica
# a saida de um processo externo capturada via "$var = & cmd" corretamente
# como UTF-8 se [Console]::OutputEncoding estiver configurado pra isso -
# senao usa o codepage OEM/legado do console (varia por maquina/locale, ex.:
# 850/1252 num Windows em portugues), e o texto ja chega CORROMPIDO em
# $trackedFiles antes mesmo de eu escrever o manifesto (bug real: funcionou
# numa maquina onde o console ja estava em UTF-8 por acaso, falhou noutra
# sessao com o codepage padrao - "sereníssima" virou "seren├¡ssima", um
# classico de UTF-8 lido como Latin-1/CP1252). Forcar UTF-8 aqui garante o
# mesmo resultado em qualquer maquina, independente do codepage default do
# console de quem roda o script.
$PrevOutputEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Push-Location $RepoRoot
try {
    # core.quotepath=false: nomes de arquivo com acento saem como UTF-8 de
    # verdade, nao escapados em octal (ver cabecalho do script) - confirmado
    # necessario com um arquivo .mid real em dist\editor\tools\msxbas2rom\.
    $trackedFiles = & git -c core.quotepath=false ls-files dist/
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git ls-files falhou (codigo $LASTEXITCODE) - rode isto de dentro do repositorio."
        exit 1
    }
} finally {
    Pop-Location
    [Console]::OutputEncoding = $PrevOutputEncoding
}


# dist\roms\ e' gitignored de proposito (ROMs do sistema MSX pro Fossauro,
# copyright proprio - nunca rastreadas no git, ver .gitignore/CLAUDE.md), logo
# "git ls-files dist/" nunca as lista sozinho. Pedido explicito do usuario
# (2026-08-25): o instalador standalone TAMBEM deve empacotar as ROMs (nao so'
# o build local em dist\roms\) - adicionadas a mao aqui, mesmo espirito do
# "dist/fossauro.exe" logo abaixo (tambem gitignored, tambem parte do pacote).
$RomFiles = @()
$DistRomsDir = Join-Path $RepoRoot "dist\roms"
if (Test-Path $DistRomsDir) {
    $RomFiles = Get-ChildItem -Path $DistRomsDir -File | ForEach-Object { "dist/roms/$($_.Name)" }
}

$allFiles = @($trackedFiles) + @("dist/fossauro.exe") + $RomFiles
# UTF8 sem BOM - o manifesto e' lido por um programa PureBasic (ReadFile/
# ReadString), BOM na primeira linha corromperia o primeiro caminho.
[System.IO.File]::WriteAllLines($ManifestPath, $allFiles, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "  manifesto: $ManifestPath ($($allFiles.Count) arquivos)"
Write-Host ""

# --- 3. Compila e roda BuildPayloadZip.exe ------------------------------
Write-Host "=== Passo 3/4: empacotando payload.zip ==="
$PackerToolSrc = Join-Path $InstallerSrcDir "tools\BuildPayloadZip.pb"
$PackerToolExe = Join-Path $InstallerSrcDir "tools\BuildPayloadZip.exe"

& $CompilerPath $PackerToolSrc /OUTPUT $PackerToolExe /CONSOLE /QUIET
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha compilando BuildPayloadZip.pb (codigo $LASTEXITCODE)."
    exit $LASTEXITCODE
}

$PayloadZip = Join-Path $InstallerSrcDir "payload.zip"
& $PackerToolExe $RepoRoot $ManifestPath $PayloadZip
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha empacotando payload.zip (codigo $LASTEXITCODE) - ver avisos acima (arquivo(s) ausente(s) no manifesto?)."
    exit $LASTEXITCODE
}
$PayloadSizeMB = [Math]::Round((Get-Item $PayloadZip).Length / 1MB, 1)
Write-Host "  payload.zip: $PayloadSizeMB MB"
Write-Host ""

# --- 4. Compila o instalador final ---------------------------------------
Write-Host "=== Passo 4/4: compilando o instalador ==="
$InstallerOutDir = Join-Path $RepoRoot "installer"
New-Item -ItemType Directory -Path $InstallerOutDir -Force | Out-Null
$InstallerExe = Join-Path $InstallerOutDir "PaleoBasicSetup.exe"
$InstallerSrc = Join-Path $InstallerSrcDir "PaleoBasicSetup.pb"

& $CompilerPath $InstallerSrc /OUTPUT $InstallerExe /QUIET /XP /CONSTANT "App_Version=$Version"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha compilando o instalador (codigo $LASTEXITCODE)."
    exit $LASTEXITCODE
}

$InstallerSizeMB = [Math]::Round((Get-Item $InstallerExe).Length / 1MB, 1)
Write-Host ""
Write-Host "Instalador pronto: $InstallerExe ($InstallerSizeMB MB)"

if ($Run) {
    Write-Host "Executando $InstallerExe ..."
    Start-Process -FilePath $InstallerExe
}
