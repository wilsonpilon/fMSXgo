param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$buildScript = Join-Path $repoRoot "build.ps1"
$exePath = Join-Path $repoRoot "msxide.exe"

Push-Location $repoRoot
try {
    & $buildScript
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao compilar msxide.exe"
    }

    & $exePath "--smoke-badig"
    if ($LASTEXITCODE -ne 0) {
        throw "Smoke test do preprocessador Basic Dignified (juncao de linha por :, Strip Spaces, Convert PRINT, Strip THEN GOTO) falhou"
    }
}
finally {
    Pop-Location
}
