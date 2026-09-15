param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)
try {
    $compiler = "C:\basic\FreeBASIC\fbc64.exe"
    if (-not (Test-Path $compiler)) {
        throw "Compilador FreeBASIC nao encontrado em $compiler"
    }

    & $compiler `
        ".\regression_runner.bas" `
        "..\..\src\compiler.bas" `
        "..\..\src\db.bas" `
        -x ".\regression_runner.exe"

    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao compilar regression_runner.bas"
    }

    & ".\regression_runner.exe"
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
