param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $projectRoot ".build-config.json"
$outputExe = Join-Path $projectRoot "msxide.exe"
$releaseCodename = "MAMUTE.MAP"

function New-DefaultConfig {
    return [ordered]@{
        Basic          = "C:\dos\freebasic"
        Compiler       = "fbc64.exe"
        Backend        = "win"
        Version        = "0.0.0"
        LastSourceHash = ""
    }
}

function Save-Config {
    param([hashtable]$Config)
    $Config | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8
}

function Load-Config {
    if (-not (Test-Path -Path $configPath)) {
        $cfg = New-DefaultConfig
        Save-Config -Config $cfg
        return $cfg
    }

    $raw = Get-Content -Path $configPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        $cfg = New-DefaultConfig
        Save-Config -Config $cfg
        return $cfg
    }

    $obj = $raw | ConvertFrom-Json
    $cfg = New-DefaultConfig

    if ($obj.PSObject.Properties.Match("Basic").Count -gt 0 -and [string]$obj.Basic -ne "") { $cfg.Basic = [string]$obj.Basic }
    if ($obj.PSObject.Properties.Match("Compiler").Count -gt 0 -and [string]$obj.Compiler -ne "") { $cfg.Compiler = [string]$obj.Compiler }
    if ($obj.PSObject.Properties.Match("Backend").Count -gt 0 -and [string]$obj.Backend -ne "") { $cfg.Backend = [string]$obj.Backend }
    if ($obj.PSObject.Properties.Match("Version").Count -gt 0 -and [string]$obj.Version -ne "") { $cfg.Version = [string]$obj.Version }
    if ($obj.PSObject.Properties.Match("LastSourceHash").Count -gt 0 -and [string]$obj.LastSourceHash -ne "") { $cfg.LastSourceHash = [string]$obj.LastSourceHash }

    return $cfg
}

function Show-Help {
    Write-Host "Uso:" -ForegroundColor Cyan
    Write-Host "  .\build.ps1 [--Compiler NOME] [--Basic DIRETORIO] [--Backend win|newt] [--Version X.Y.Z|release|minor|major] [--Run]"
    Write-Host ""
    Write-Host "Opcoes:" -ForegroundColor Cyan
    Write-Host "  --Compiler  Nome/arquivo do compilador (ex.: fbc64.exe)"
    Write-Host "  --Basic     Diretorio base do FreeBASIC (ex.: C:\dos\freebasic)"
    Write-Host "  --Backend   Backend de console: win ou newt"
    Write-Host "  --Version   Define versao manual X.Y.Z ou incrementa: release, minor, major"
    Write-Host "  --Run       Executa msxide.exe apos compilar"
    Write-Host "  --Help      Mostra esta ajuda"
    Write-Host ""
    Write-Host "Regras de versao:" -ForegroundColor Cyan
    Write-Host "  release = patch (+0.0.1)"
    Write-Host "  minor   = feature/bugfix (+0.1.0, zera patch)"
    Write-Host "  major   = pacote fechado (+1.0.0, zera minor/patch)"
    Write-Host ""
    Write-Host "Auto patch: se codigo-fonte mudar e --Version nao for informado, o script incrementa patch automaticamente."
}

function Parse-Version {
    param([string]$Version)

    if ($Version -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
        throw "Versao invalida '$Version'. Use formato X.Y.Z"
    }

    return @([int]$Matches[1], [int]$Matches[2], [int]$Matches[3])
}

function Format-Version {
    param([int]$Major, [int]$Minor, [int]$Patch)
    return "$Major.$Minor.$Patch"
}

function Bump-Version {
    param(
        [string]$Current,
        [ValidateSet("release", "minor", "major")]
        [string]$Kind
    )

    $parts = Parse-Version -Version $Current
    $major = $parts[0]
    $minor = $parts[1]
    $patch = $parts[2]

    switch ($Kind) {
        "release" {
            $patch += 1
        }
        "minor" {
            $minor += 1
            $patch = 0
        }
        "major" {
            $major += 1
            $minor = 0
            $patch = 0
        }
    }

    return (Format-Version -Major $major -Minor $minor -Patch $patch)
}

function Get-SourceHash {
    $srcDir = Join-Path $projectRoot "src"
    if (-not (Test-Path -Path $srcDir)) {
        return ""
    }

    $files = Get-ChildItem -Path $srcDir -Recurse -File | Where-Object {
        $_.Extension -in ".bas", ".bi"
    } | Sort-Object FullName

    if ($files.Count -eq 0) {
        return ""
    }

    $joined = foreach ($f in $files) {
        $h = Get-FileHash -Path $f.FullName -Algorithm SHA256
        "$($f.FullName)|$($h.Hash)"
    }

    $payload = ($joined -join "`n")
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    $ms = New-Object System.IO.MemoryStream
    $ms.Write($bytes, 0, $bytes.Length)
    $ms.Position = 0

    $hashAlgo = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $hashAlgo.ComputeHash($ms)
        return ([System.BitConverter]::ToString($hashBytes)).Replace("-", "")
    }
    finally {
        $hashAlgo.Dispose()
        $ms.Dispose()
    }
}

function Resolve-CompilerPath {
    param(
        [string]$BasicDir,
        [string]$CompilerName
    )

    if ([System.IO.Path]::IsPathRooted($CompilerName)) {
        return $CompilerName
    }

    # Prioriza o caminho raiz informado pelo usuario.
    $candidateRoot = Join-Path $BasicDir $CompilerName
    if (Test-Path -Path $candidateRoot) {
        return $candidateRoot
    }

    # Fallback comum da distribuicao do FreeBASIC.
    $candidateBin = Join-Path (Join-Path $BasicDir "bin\win64") $CompilerName
    if (Test-Path -Path $candidateBin) {
        return $candidateBin
    }

    return $candidateRoot
}

function Get-SqliteDownloadLink {
    $downloadPage = "https://www.sqlite.org/download.html"
    $resp = Invoke-WebRequest -Uri $downloadPage -UseBasicParsing
    $content = [string]$resp.Content

    # Metodo principal: bloco CSV oficial dentro de comentario HTML.
    # Formato de linha esperado:
    # PRODUCT,sqlite-dll-win-x64,3530400,2026/sqlite-dll-win-x64-3530400.zip,...
    $csvBlock = [regex]::Match(
        $content,
        'PRODUCT,VERSION,RELATIVE-URL,SIZE-IN-BYTES,SHA3-HASH(?<rows>.*?)-->',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if ($csvBlock.Success) {
        $rows = $csvBlock.Groups["rows"].Value -split "`r?`n"
        foreach ($row in $rows) {
            $line = $row.Trim()
            if ($line -like "PRODUCT,sqlite-dll-win-x64,*") {
                $parts = $line.Split(',')
                if ($parts.Length -ge 4 -and -not [string]::IsNullOrWhiteSpace($parts[3])) {
                    $rel = $parts[3].Trim()
                    return ("https://www.sqlite.org/" + $rel.TrimStart('/'))
                }
            }
        }
    }

    # Fallback: busca por qualquer ocorrencia de URL/rel-path no HTML.
    $rx = [regex]'(?<href>(?:https?://[^"''\s<>]*|[0-9]{4}/)sqlite-dll-win-x64-[0-9]+\.zip)'
    $m = $rx.Match($content)
    if ($m.Success) {
        $href = $m.Groups["href"].Value
        if ($href -match '^https?://') {
            return $href
        }
        return ("https://www.sqlite.org/" + $href.TrimStart('/'))
    }

    throw "Nao foi possivel localizar link de sqlite-dll-win-x64 no site oficial."
}

function Ensure-SqliteDll {
    $targetDll = Join-Path $projectRoot "sqlite3.dll"
    if (Test-Path -Path $targetDll) {
        return $targetDll
    }

    $sqliteDir = Join-Path $projectRoot "third_party\\sqlite"
    $extractDir = Join-Path $sqliteDir "extract"

    if (-not (Test-Path -Path $sqliteDir)) {
        New-Item -Path $sqliteDir -ItemType Directory | Out-Null
    }

    Write-Host "sqlite3.dll nao encontrada. Baixando pacote oficial do SQLite..." -ForegroundColor Yellow
    $downloadUrl = Get-SqliteDownloadLink
    $zipName = Split-Path -Path $downloadUrl -Leaf
    $zipPath = Join-Path $sqliteDir $zipName

    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing

    if (Test-Path -Path $extractDir) {
        Remove-Item -Path $extractDir -Recurse -Force
    }
    New-Item -Path $extractDir -ItemType Directory | Out-Null

    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    $dll = Get-ChildItem -Path $extractDir -Recurse -File | Where-Object { $_.Name -ieq "sqlite3.dll" } | Select-Object -First 1
    if ($null -eq $dll) {
        throw "Pacote baixado, mas sqlite3.dll nao foi encontrada dentro do zip."
    }

    Copy-Item -Path $dll.FullName -Destination $targetDll -Force
    Write-Host "sqlite3.dll instalada em: $targetDll" -ForegroundColor Green
    return $targetDll
}

$config = Load-Config
$runAfterBuild = $false
$versionArg = $null
$manualVersionMode = $false
$backendArg = $null

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = [string]$args[$i]

    switch -Regex ($arg) {
        '^--Help$' {
            Show-Help
            exit 0
        }
        '^--Run$' {
            $runAfterBuild = $true
            continue
        }
        '^--Compiler$' {
            if ($i + 1 -ge $args.Count) { throw "Faltou valor para --Compiler" }
            $i += 1
            $config.Compiler = [string]$args[$i]
            continue
        }
        '^--Basic$' {
            if ($i + 1 -ge $args.Count) { throw "Faltou valor para --Basic" }
            $i += 1
            $config.Basic = [string]$args[$i]
            continue
        }
        '^--Version$' {
            if ($i + 1 -ge $args.Count) { throw "Faltou valor para --Version" }
            $i += 1
            $versionArg = [string]$args[$i]
            $manualVersionMode = $true
            continue
        }
        '^--Backend$' {
            if ($i + 1 -ge $args.Count) { throw "Faltou valor para --Backend" }
            $i += 1
            $backendArg = [string]$args[$i]
            continue
        }
        default {
            throw "Opcao desconhecida: $arg (use --Help)"
        }
    }
}

if ($null -ne $backendArg) {
    $config.Backend = $backendArg
}

$backend = $config.Backend.ToLowerInvariant()
if ($backend -notin @("win", "newt")) {
    throw "Backend invalido '$($config.Backend)'. Use win ou newt."
}

if (-not (Test-Path -Path $config.Basic)) {
    throw "Diretorio FreeBASIC nao encontrado: $($config.Basic)"
}

$nextVersion = $config.Version
$versionChanged = $false

if ($manualVersionMode) {
    $v = $versionArg.ToLowerInvariant()
    if ($v -in @("release", "minor", "major")) {
        $nextVersion = Bump-Version -Current $config.Version -Kind $v
    }
    else {
        [void](Parse-Version -Version $versionArg)
        $nextVersion = $versionArg
    }
    $versionChanged = $true
}

$currentHash = Get-SourceHash
if (-not $manualVersionMode -and $currentHash -ne "" -and $currentHash -ne $config.LastSourceHash) {
    $nextVersion = Bump-Version -Current $config.Version -Kind "release"
    $versionChanged = $true
    Write-Host "Versao auto incrementada (release): $nextVersion" -ForegroundColor Yellow
}

$compilerPath = Resolve-CompilerPath -BasicDir $config.Basic -CompilerName $config.Compiler
if (-not (Test-Path -Path $compilerPath)) {
    throw "Compilador nao encontrado: $compilerPath"
}

Save-Config -Config $config
Ensure-SqliteDll | Out-Null

Push-Location $projectRoot
try {
    $compileArgs = @(
        "src\main.bas"
        "src\editor.bas"
        "src\compiler.bas"
        "src\db.bas"
        "src\project.bas"
        "src\console.bas"
        "-x"
        "msxide.exe"
    )

    Write-Host "Compilando com: $compilerPath" -ForegroundColor Cyan
    Write-Host "Backend: $backend" -ForegroundColor Cyan
    Write-Host "Versao atual: $nextVersion ($releaseCodename)" -ForegroundColor Cyan

    $versionBiPath = Join-Path $projectRoot "src\version.bi"
    $versionBiContent = "Const MSXIDE_VERSION_STR As String = `"$nextVersion`"" + "`r`n" + "Const MSXIDE_RELEASE_CODENAME As String = `"$releaseCodename`""
    Set-Content -Path $versionBiPath -Value $versionBiContent -Encoding utf8

    if ($backend -eq "newt") {
        $compileArgs += @("-d", "MSX_CONSOLE_NEWT")
    }
    else {
        $compileArgs += @("-d", "MSX_CONSOLE_WIN")
    }

    & $compilerPath @compileArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Compilacao falhou com codigo $LASTEXITCODE"
    }

    Write-Host "Build concluido: $outputExe" -ForegroundColor Green

    if ($versionChanged) {
        $config.Version = $nextVersion
    }
    $config.LastSourceHash = $currentHash
    Save-Config -Config $config

    if ($runAfterBuild) {
        if (-not (Test-Path -Path $outputExe)) {
            throw "Executavel nao encontrado: $outputExe"
        }

        Write-Host "Executando msxide.exe..." -ForegroundColor Cyan
        & $outputExe
    }
}
finally {
    Pop-Location
}
