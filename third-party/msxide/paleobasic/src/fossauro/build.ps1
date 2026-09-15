# Script de compilação PowerShell para o projeto fossauro
# Executa o pbcompiler para gerar dist\fossauro.exe (raiz de dist\, irmao de
# dist\PaleoBasic.exe - pedido explicito do usuario, 2026-08-19; dist\fossauro\
# continua existindo, so' com help/config, nao o executavel)
#
# Chamado automaticamente por build.ps1 (raiz do repo) a cada build - pedido
# explicito do usuario (2026-08-20): fossauro e parte do PaleoBasic, um unico
# build tem que gerar o pacote inteiro (os dois executaveis + dist\ completo),
# sem precisar rodar dois scripts separados. -Version deixa o build.ps1 raiz
# repassar a MESMA versao pros dois executaveis (antes ficava fixo em 8.2.0
# aqui, dessincronizado do resto do app).
param([string]$Version = "8.4.0")

$ErrorActionPreference = "Stop"

# $PSScriptRoot = src\fossauro\ (localizacao deste script) - resolve tudo daqui
# em vez de depender do diretorio de trabalho de quem chama (antes usava
# nomes crus "fossauro.pb"/"fossauro.exe"/"pbcompiler", so funcionava se
# invocado de dentro da propria pasta).
$SourceFile = Join-Path $PSScriptRoot "fossauro.pb"
$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$OutputExe = Join-Path $RepoRoot "dist\fossauro.exe"
$OutputDir = Split-Path $OutputExe -Parent
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Mesma resolucao de build.config.json que build.ps1 (raiz do repo) ja usa -
# reaproveita o MESMO arquivo/caminho salvo de pbcompiler.exe, nao pede de novo.
$ConfigPath = Join-Path $RepoRoot "build.config.json"
$CompilerPath = "pbcompiler"
if (Test-Path $ConfigPath) {
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        if ($config.CompilerPath) { $CompilerPath = $config.CompilerPath }
    } catch {
        Write-Warning "Nao foi possivel ler $ConfigPath - usando 'pbcompiler' do PATH."
    }
}

# Mesmo icone do PaleoBasic.exe (resource/branding/paleobasic-new.ico), por pedido explicito do
# usuario (2026-08-19) - "por hora" o mesmo icone nos dois, ver build.ps1 (raiz do repo) pro
# mesmo padrao. So embute o icone do .exe (Explorer/propriedades) - diferente do BadigEditor.pb,
# fossauro.pb ainda nao tem codigo de runtime (WM_SETICON) pra reaplicar isso na barra de titulo
# das janelas, entao o icone da JANELA continua o padrao do PureBasic por enquanto.
$IconFile = Join-Path $RepoRoot "resource\branding\paleobasic-new.ico"
$IconArgs = @()
if (Test-Path $IconFile) {
    $IconArgs = @("/ICON", $IconFile)
} else {
    Write-Warning "Icone nao encontrado em $IconFile - compilando sem /ICON."
}

Write-Host "Iniciando compilação do fossauro..." -ForegroundColor Cyan
Write-Host "Fonte : $SourceFile"
Write-Host "Saida : $OutputExe"

& $CompilerPath $SourceFile /THREAD /OUTPUT $OutputExe @IconArgs /CONSTANT "App_Version=$Version"

if ($LASTEXITCODE -eq 0) {
    Write-Host "------------------------------------------------------------" -ForegroundColor Green
    Write-Host " SUCESSO: Compilação concluída com êxito!" -ForegroundColor Green
    Write-Host " Executável criado: $OutputExe" -ForegroundColor Green
    Write-Host "------------------------------------------------------------" -ForegroundColor Green
} else {
    Write-Host "------------------------------------------------------------" -ForegroundColor Red
    Write-Host " ERRO: Falha na compilação do fossauro!" -ForegroundColor Red
    Write-Host "------------------------------------------------------------" -ForegroundColor Red
    exit $LASTEXITCODE
}
