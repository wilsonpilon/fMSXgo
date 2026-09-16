#!/bin/bash
# build.sh
# Build script for MSX Disk Manager Utility (Linux/WSL)
# Generates msxdisk, libmsxdisk.so, updates README.md, and creates the distribution tarball.

# Exit immediately if any command fails
set -e

VERSION="1.8b"

echo "=== MSX Disk Manager Utility - Linux/WSL Build ==="

# 1. Locate PureBasic Compiler
if [ -n "$PBCOMPILER" ]; then
    COMPILER_PATH="$PBCOMPILER"
elif command -v pbcompiler >/dev/null 2>&1; then
    COMPILER_PATH=$(command -v pbcompiler)
elif [ -f "$HOME/purebasic/compilers/pbcompiler" ]; then
    COMPILER_PATH="$HOME/purebasic/compilers/pbcompiler"
elif [ -f "/home/barney/purebasic/compilers/pbcompiler" ]; then
    # Fallback to standard location on this environment
    COMPILER_PATH="/home/barney/purebasic/compilers/pbcompiler"
elif [ -f "/opt/purebasic/compilers/pbcompiler" ]; then
    COMPILER_PATH="/opt/purebasic/compilers/pbcompiler"
else
    echo "Error: pbcompiler not found!"
    echo "Please install PureBasic or set the PBCOMPILER environment variable."
    echo "Example: export PBCOMPILER=/path/to/purebasic/compilers/pbcompiler"
    exit 1
fi

echo "Using compiler: $COMPILER_PATH"

# 2. Set PUREBASIC_HOME if not already set
if [ -z "$PUREBASIC_HOME" ]; then
    # Extract PureBasic home directory (two levels up from compilers/pbcompiler)
    PUREBASIC_HOME=$(dirname "$(dirname "$COMPILER_PATH")")
    export PUREBASIC_HOME
fi
echo "PUREBASIC_HOME is set to: $PUREBASIC_HOME"

# 3. Generate Build Number (UNIX timestamp in UTC represented in Hexadecimal)
BUILD_HEX=$(printf '%X' $(date -u +%s))
echo "Build version: $VERSION (Build: $BUILD_HEX)"

# 4. Generate version.pbi
echo "Generating version.pbi..."
cat <<EOF > version.pbi
#VERSION$ = "$VERSION"
#BUILD$ = "$BUILD_HEX"
EOF

# 5. Update README.md
if [ -f "README.md" ]; then
    echo "Updating README.md..."
    # Using perl to perform inline regex replacements similar to PowerShell
    # This replaces the top header version/build info
    perl -pi -e "s/^# MSX Disk Manager Utility - Vers.*$/# MSX Disk Manager Utility - Versão \$VERSION (Build \$BUILD_HEX)/mi" README.md
    # This replaces the version details in version history
    perl -pi -e "s/^- \*\*Vers.*\(Esta Vers.*\)\*\*:/- \*\*Versão \$VERSION (Esta Versão)\*\*:/mi" README.md
else
    echo "Warning: README.md not found!"
fi

# 6. Compile executable (Console CLI)
echo "Compiling msxdisk (Console CLI)..."
"$COMPILER_PATH" msxdisk.pb -cl -o msxdisk

# 7. Compile Shared Library (Shared Object)
echo "Compiling libmsxdisk.so (Shared Object)..."
"$COMPILER_PATH" MSXDiskDLL.pb -so libmsxdisk.so

# 8. Create Distribution Package
DIST_NAME="msxDiskUtil_linux_${VERSION}"
TAR_NAME="${DIST_NAME}.tar.gz"
TEMP_DIST="temp_dist"

echo "Creating distribution package $TAR_NAME..."

# Cleanup old dist folder/tarball if they exist
rm -rf "$TEMP_DIST" "$TAR_NAME"
mkdir "$TEMP_DIST"

# List of files to copy into the distribution package
FILES_TO_PACKAGE=(
    "msxdisk"
    "libmsxdisk.so"
    "LICENSE"
    "README.md"
    "msxdos.dsk"
    "msxdos.sys"
    "command.com"
    "MSXDisk.pbi"
    "msxdisk.pb"
    "MSXDiskDLL.pb"
)

for file in "${FILES_TO_PACKAGE[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "$TEMP_DIST/"
    else
        echo "Warning: Required file '$file' not found, skipping packaging for it."
    fi
done

# Compress to tar.gz
tar -czf "$TAR_NAME" -C "$TEMP_DIST" .

# Cleanup temp folder
rm -rf "$TEMP_DIST"

echo "Build and packaging completed successfully!"
echo "Output package: $TAR_NAME"
