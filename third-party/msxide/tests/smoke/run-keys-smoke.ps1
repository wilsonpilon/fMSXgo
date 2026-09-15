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

    & $exePath "--smoke-keys"
    if ($LASTEXITCODE -ne 0) {
        throw "Smoke test de traducao de teclas (Ctrl/Alt+letra) falhou"
    }
}
finally {
    Pop-Location
}
