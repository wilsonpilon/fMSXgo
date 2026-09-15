param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $testsRoot

$regressionScript = Join-Path $testsRoot "regression\run-regression.ps1"
$smokeScript = Join-Path $testsRoot "smoke\run-help-smoke.ps1"
$editorSmokeScript = Join-Path $testsRoot "smoke\run-editor-smoke.ps1"
$keysSmokeScript = Join-Path $testsRoot "smoke\run-keys-smoke.ps1"
$badigSmokeScript = Join-Path $testsRoot "smoke\run-badig-smoke.ps1"

if (-not (Test-Path -Path $regressionScript)) {
    throw "Script de regressao nao encontrado: $regressionScript"
}
if (-not (Test-Path -Path $smokeScript)) {
    throw "Script de smoke nao encontrado: $smokeScript"
}
if (-not (Test-Path -Path $editorSmokeScript)) {
    throw "Script de smoke do editor nao encontrado: $editorSmokeScript"
}
if (-not (Test-Path -Path $keysSmokeScript)) {
    throw "Script de smoke de teclas nao encontrado: $keysSmokeScript"
}
if (-not (Test-Path -Path $badigSmokeScript)) {
    throw "Script de smoke do Basic Dignified nao encontrado: $badigSmokeScript"
}

Push-Location $repoRoot
try {
    Write-Host "[1/5] Executando regressao..." -ForegroundColor Cyan
    & $regressionScript
    if ($LASTEXITCODE -ne 0) {
        throw "Regressao falhou"
    }

    Write-Host "[2/5] Executando smoke de help..." -ForegroundColor Cyan
    & $smokeScript
    if ($LASTEXITCODE -ne 0) {
        throw "Smoke de help falhou"
    }

    Write-Host "[3/5] Executando smoke do editor de textos..." -ForegroundColor Cyan
    & $editorSmokeScript
    if ($LASTEXITCODE -ne 0) {
        throw "Smoke do editor de textos falhou"
    }

    Write-Host "[4/5] Executando smoke de traducao de teclas..." -ForegroundColor Cyan
    & $keysSmokeScript
    if ($LASTEXITCODE -ne 0) {
        throw "Smoke de traducao de teclas falhou"
    }

    Write-Host "[5/5] Executando smoke do Basic Dignified (juncao de linha, Strip Spaces, Convert PRINT, Strip THEN GOTO)..." -ForegroundColor Cyan
    & $badigSmokeScript
    if ($LASTEXITCODE -ne 0) {
        throw "Smoke do Basic Dignified falhou"
    }

    Write-Host "TESTES OK: regressao + smoke" -ForegroundColor Green
}
finally {
    Pop-Location
}
