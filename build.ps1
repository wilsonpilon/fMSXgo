# =====================================================================
# fMSXgo - Build & Distribution Automation Script (PowerShell)
# =====================================================================
# This script:
# 1. Downloads all necessary Go packages and dependencies.
# 2. Increments the build number (Z in V X.Y.Z).
# 3. Runs internal test suites to verify integrity.
# 4. Compiles the 64-bit binary for Windows (and cross-compilation ready).
# 5. Packages everything into the 'dist/' distribution folder, including
#    all BIOS ROMs and documentation bundled inside a single SQLite database!
# =====================================================================

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       fMSXgo Build Automation & Packaging Engine                " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Read and update version.json
$VersionFile = Join-Path $PSScriptRoot "version.json"
if (Test-Path $VersionFile) {
    $verData = Get-Content $VersionFile | ConvertFrom-Json
} else {
    $verData = [PSCustomObject]@{
        major    = 0
        minor    = 1
        build    = 0
        codename = "Phantasm"
    }
}

# Increment build number (Z) on each compilation
$verData.build = [int]$verData.build + 1
$verData | ConvertTo-Json | Set-Content $VersionFile

$VersionStr = "$($verData.major).$($verData.minor).$($verData.build)"
$Codename   = $verData.codename

Write-Host "[1/5] Target Version: V $VersionStr ('$Codename')" -ForegroundColor Yellow

# 2. Download and verify Go dependencies
Write-Host "[2/5] Downloading and tidying Go dependencies..." -ForegroundColor Yellow
go mod tidy
go mod download

# 3. Run Automated Tests
Write-Host "[3/5] Running automated unit tests..." -ForegroundColor Yellow
$testResult = go test ./...
if ($LASTEXITCODE -ne 0) {
    Write-Error "Unit tests failed! Aborting build."
    exit 1
}
Write-Host "  -> All unit tests passed!" -ForegroundColor Green

# 4. Compile binary into dist/
$DistDir = Join-Path $PSScriptRoot "dist"
if (!(Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir | Out-Null
}

$BinaryPath = Join-Path $DistDir "fmsxgo.exe"
Write-Host "[4/5] Compiling fmsxgo.exe with version metadata..." -ForegroundColor Yellow

go build -ldflags "-s -w -X main.Version=$VersionStr -X 'main.Codename=$Codename'" -o $BinaryPath ./cmd/fmsxgo

if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation failed! Aborting build."
    exit 1
}
Write-Host "  -> Compiled binary created: $BinaryPath" -ForegroundColor Green

# 5. Populate SQLite Database and Bundle Assets into dist/
Write-Host "[5/5] Bundling SQLite database, ROMs and documentation..." -ForegroundColor Yellow

$DistDB = Join-Path $DistDir "fmsxgo.db"

# Seed the distribution database using fmsxgo itself
& $BinaryPath --no-window --db $DistDB -test | Out-Null

# Copy Documentation to dist/
$Docs = @("README.md", "MANUAL.md", "CHANGELOG.md", "SPEC.md", "LICENSE")
foreach ($doc in $Docs) {
    $docPath = Join-Path $PSScriptRoot $doc
    if (Test-Path $docPath) {
        Copy-Item -Path $docPath -Destination $DistDir -Force
    }
}

# Create convenience launcher bat files in dist/
$cliLauncher = @"
@echo off
fmsxgo.exe --no-window
"@
Set-Content -Path (Join-Path $DistDir "run-cli.bat") -Value $cliLauncher

$guiLauncher = @"
@echo off
fmsxgo.exe
"@
Set-Content -Path (Join-Path $DistDir "run-gui.bat") -Value $guiLauncher

Write-Host "=================================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Build completed successfully!" -ForegroundColor Green
Write-Host " Distribution artifacts generated in: $DistDir" -ForegroundColor Green
Write-Host " Version: V $VersionStr ($Codename)" -ForegroundColor Green
Write-Host " Files bundled in dist/:" -ForegroundColor Green
Get-ChildItem -Path $DistDir | ForEach-Object {
    $sizeKb = [math]::Round($_.Length / 1KB, 1)
    Write-Host "   - $($_.Name) ($sizeKb KB)" -ForegroundColor Gray
}
Write-Host "=================================================================" -ForegroundColor Green
