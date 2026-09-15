param()

# Monta a pasta distribute/ (tudo que msxide.exe precisa pra rodar) e compila
# installer.exe a partir de installer/installer.bas. Roda DEPOIS de build.ps1
# (espera msxide.exe/sqlite3.dll ja existirem na raiz do projeto).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $projectRoot
try {
    $msxideExe = Join-Path $projectRoot "msxide.exe"
    $sqliteDll = Join-Path $projectRoot "sqlite3.dll"
    if (-not (Test-Path $msxideExe)) { throw "msxide.exe nao encontrado - rode .\build.ps1 primeiro." }
    if (-not (Test-Path $sqliteDll)) { throw "sqlite3.dll nao encontrado - rode .\build.ps1 primeiro (ele baixa sozinho)." }

    $distDir = Join-Path $projectRoot "distribute"
    if (Test-Path $distDir) {
        Write-Host "Limpando distribute\ existente..." -ForegroundColor Yellow
        Remove-Item $distDir -Recurse -Force
    }
    New-Item -Path $distDir -ItemType Directory | Out-Null

    Write-Host "Copiando arquivos de execucao..." -ForegroundColor Cyan
    Copy-Item $msxideExe, $sqliteDll -Destination $distDir
    foreach ($doc in @("LICENSE", "README.md", "MANUAL.md", "SPEC.md", "CHANGELOG.md", "RELEASE.md")) {
        $p = Join-Path $projectRoot $doc
        if (Test-Path $p) { Copy-Item $p -Destination $distDir }
    }

    Copy-Item (Join-Path $projectRoot "ajuda") (Join-Path $distDir "ajuda") -Recurse
    Copy-Item (Join-Path $projectRoot "docs") (Join-Path $distDir "docs") -Recurse
    Copy-Item (Join-Path $projectRoot "basic-dignified") (Join-Path $distDir "basic-dignified") -Recurse
    Copy-Item (Join-Path $projectRoot "asMSX") (Join-Path $distDir "asMSX") -Recurse

    # roms\msx1.alf e' a fonte MSX1 padrao que semeia todo "Novo Editor de
    # Fontes" (ver src/editor.bas) - sem ela o editor de fontes cai num
    # buffer em branco no pacote distribuido. So esse arquivo vai (os
    # dumps de BIOS/ROM reais em roms\*.ROM nao sao distribuidos aqui -
    # continuam sendo apontados manualmente pelo usuario em
    # Configurar -> Mamute, como sempre foi).
    $distRomsDir = Join-Path $distDir "roms"
    New-Item -Path $distRomsDir -ItemType Directory | Out-Null
    Copy-Item (Join-Path $projectRoot "roms\msx1.alf") $distRomsDir

    New-Item -Path (Join-Path $distDir "logs") -ItemType Directory | Out-Null
    New-Item -Path (Join-Path $distDir "disk") -ItemType Directory | Out-Null

    # basic-dignified/ e asMSX/ trazem so o que msxide.exe realmente le em
    # runtime (ver SPEC.md) - o resto (fontes Python/C, exemplos, testes) fica
    # de fora pra manter a pasta enxuta.
    Write-Host "Removendo itens nao usados em runtime..." -ForegroundColor Cyan
    Remove-Item (Join-Path $distDir "asMSX\code"), (Join-Path $distDir "asMSX\ref"), (Join-Path $distDir "asMSX\src"), (Join-Path $distDir "asMSX\test") -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $distDir "asMSX\Dockerfile"), (Join-Path $distDir "asMSX\Makefile"), (Join-Path $distDir "asMSX\.gitignore") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $distDir "basic-dignified\badig.py") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $distDir "basic-dignified\examples") -Recurse -Force -ErrorAction SilentlyContinue

    $sizeMb = [math]::Round((Get-ChildItem $distDir -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 1)
    Write-Host "distribute\ pronto ($sizeMb MB)." -ForegroundColor Green

    # Sincroniza a versao/codinome embutidos no instalador com o que
    # build.ps1 acabou de gravar em src/version.bi (evita instalador dizendo
    # uma versao diferente do msxide.exe que ele mesmo esta empacotando).
    $versionBi = Get-Content (Join-Path $projectRoot "src\version.bi") -Raw
    $verMatch = [regex]::Match($versionBi, 'MSXIDE_VERSION_STR As String = "([^"]*)"')
    $codenameMatch = [regex]::Match($versionBi, 'MSXIDE_RELEASE_CODENAME As String = "([^"]*)"')
    if ($verMatch.Success) {
        $ver = $verMatch.Groups[1].Value
        $codename = if ($codenameMatch.Success) { $codenameMatch.Groups[1].Value } else { "" }
        $installerBasPath = Join-Path $projectRoot "installer\installer.bas"
        $installerSrc = Get-Content $installerBasPath -Raw
        $installerSrc = $installerSrc -replace 'Const MSXIDE_INSTALLER_VERSION = "[^"]*"', "Const MSXIDE_INSTALLER_VERSION = `"$ver`""
        $installerSrc = $installerSrc -replace 'Const MSXIDE_INSTALLER_CODENAME = "[^"]*"', "Const MSXIDE_INSTALLER_CODENAME = `"$codename`""
        Set-Content -Path $installerBasPath -Value $installerSrc -Encoding utf8 -NoNewline
        Write-Host "installer.bas sincronizado com a versao $ver ($codename)." -ForegroundColor Cyan
    }

    Write-Host "Compilando installer.exe..." -ForegroundColor Cyan
    $config = Get-Content (Join-Path $projectRoot ".build-config.json") -Raw | ConvertFrom-Json
    if ([System.IO.Path]::IsPathRooted($config.Compiler)) {
        $compilerPath = $config.Compiler
    }
    else {
        $compilerPath = Join-Path $config.Basic $config.Compiler
        if (-not (Test-Path $compilerPath)) { $compilerPath = Join-Path $config.Basic "bin\win64\$($config.Compiler)" }
    }
    if (-not (Test-Path $compilerPath)) { throw "Compilador FreeBASIC nao encontrado ($compilerPath) - rode .\build.ps1 primeiro." }

    & $compilerPath "installer\installer.bas" "-x" "installer.exe"
    if ($LASTEXITCODE -ne 0) { throw "Falha ao compilar installer.exe (codigo $LASTEXITCODE)" }

    Write-Host "installer.exe pronto." -ForegroundColor Green
    Write-Host ""
    Write-Host "Distribuicao completa:" -ForegroundColor Green
    Write-Host "  $distDir\ (copia portatil - so descompactar e rodar msxide.exe)"
    Write-Host "  $(Join-Path $projectRoot 'installer.exe') (instalacao guiada - cria atalho + desinstalador)"
}
finally {
    Pop-Location
}
