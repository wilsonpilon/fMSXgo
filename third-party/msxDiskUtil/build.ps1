# build.ps1
# Build script for MSX Disk Manager Utility
# Generates msxdisk.exe, MSXDisk.dll, MSXDisk.lib, updates README.md, and creates the distribution zip package.

$ErrorActionPreference = "Stop"

$version = "1.8b"

# 1. Generate Build Number (UNIX timestamp in UTC represented in Hexadecimal)
$unixTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$buildHex = $unixTime.ToString("X")

Write-Host "Starting build process for version $version (Build: $buildHex)..." -ForegroundColor Cyan

# 2. Write version.pbi
$versionFileContent = @"
#VERSION$ = "$version"
#BUILD$ = "$buildHex"
"@

Write-Host "Generating version.pbi..."
$versionFileContent | Out-File -FilePath "version.pbi" -Encoding ascii -Force

# 3. Update README.md
if (Test-Path "README.md") {
    Write-Host "Updating README.md..."
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $readmePath = (Get-Item "README.md").FullName
    $readmeContent = [System.IO.File]::ReadAllText($readmePath, $utf8NoBom)
    
    $versaoString = "Vers{0}o" -f [char]227
    
    # Replace version at the top header
    $readmeContent = $readmeContent -replace '(?mi)^# MSX Disk Manager Utility - Vers.*$', "# MSX Disk Manager Utility - $versaoString $version (Build $buildHex)"
    
    # Replace Version details in version history
    $readmeContent = $readmeContent -replace '(?mi)^- \*\*Vers.*\(Esta Vers.*\)\*\*:', "- **$versaoString $version (Esta $versaoString)**:"
    
    [System.IO.File]::WriteAllText($readmePath, $readmeContent, $utf8NoBom)
} else {
    Write-Warning "README.md not found!"
}

# 4. Compile executables
Write-Host "Compiling msxdisk.exe (CLI Console)..."
& pbcompiler.exe msxdisk.pb /CONSOLE /OUTPUT msxdisk.exe

Write-Host "Compiling MSXDisk.dll (Dynamic Library)..."
& pbcompiler.exe MSXDiskDLL.pb /DLL /OUTPUT MSXDisk.dll

# 5. Package for distribution
$zipName = "msxDiskUtil_1.8b.zip"
$tempDist = "temp_dist"

Write-Host "Creating distribution package $zipName..."

# Clean old dist folder and zip if exist
if (Test-Path $tempDist) {
    Remove-Item -Recurse -Force $tempDist
}
if (Test-Path $zipName) {
    Remove-Item -Force $zipName
}

# Create temp dist directory
New-Item -ItemType Directory -Path $tempDist | Out-Null

# List of files to copy into the distribution package
$filesToPackage = @(
    "msxdisk.exe",
    "MSXDisk.dll",
    "MSXDisk.lib",
    "LICENSE",
    "README.md",
    "msxdos.dsk",
    "msxdos.sys",
    "command.com",
    "MSXDisk.pbi",
    "msxdisk.pb",
    "MSXDiskDLL.pb"
)

foreach ($file in $filesToPackage) {
    if (Test-Path $file) {
        Copy-Item -Path $file -Destination $tempDist
    } else {
        Write-Warning "Warning: Required file '$file' not found, skipping packaging for it."
    }
}

# Compress to ZIP
Compress-Archive -Path "$tempDist\*" -DestinationPath $zipName

# Cleanup temp folder
Remove-Item -Recurse -Force $tempDist

Write-Host "Build and packaging completed successfully!" -ForegroundColor Green
Write-Host "Output package: $zipName" -ForegroundColor Green
