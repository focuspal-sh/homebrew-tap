#!/bin/bash
# Focus Pal - Standalone Binary Compiler & Packaging Pipeline
# Compiles Python source into a native macOS Mach-O binary (zero source code exposed).
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

VERSION="${1:-1.0.6}"
ARCH="$(uname -m)"
PACKAGE_NAME="focuspal-v${VERSION}-${ARCH}"

echo "=========================================================="
echo " 🤝  Focus Pal Standalone Binary Builder"
echo " Target Architecture: ${ARCH}"
echo " Release Version:     ${VERSION}"
echo "=========================================================="

# 1. Setup / Verify build virtual environment
VENV_DIR="$PROJECT_DIR/.build-venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "==> Creating build environment at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --upgrade pip pyinstaller
else
    echo "==> Using existing build environment at $VENV_DIR..."
    if [ ! -f "$VENV_DIR/bin/pyinstaller" ]; then
        "$VENV_DIR/bin/pip" install --upgrade pip pyinstaller
    fi
fi

# 2. Clean previous build artifacts
echo "==> Cleaning previous build artifacts..."
rm -rf build dist

# 3. Compile native Mach-O standalone binary
echo "==> Compiling native Mach-O binary with PyInstaller..."
export PYINSTALLER_CONFIG_DIR="$PROJECT_DIR/build/pyi_cache"
rm -rf "$PYINSTALLER_CONFIG_DIR"
mkdir -p "$PYINSTALLER_CONFIG_DIR"

"$VENV_DIR/bin/pyinstaller" \
  --noconfirm \
  --clean \
  --name "focuspal-engine" \
  --onefile \
  --paths "$PROJECT_DIR" \
  --add-data "$PROJECT_DIR/server/templates:server/templates" \
  --add-data "$PROJECT_DIR/server/static:server/static" \
  --add-data "$PROJECT_DIR/config/config.json:config" \
  --add-data "$PROJECT_DIR/config/quotes.json:config" \
  "$PROJECT_DIR/daemon/guardian.py"

echo "==> Binary successfully compiled:"
file "$PROJECT_DIR/dist/focuspal-engine"
ls -lh "$PROJECT_DIR/dist/focuspal-engine"

# 4. Assemble release package
echo "==> Assembling release distribution package..."
DIST_PKG="$PROJECT_DIR/dist/$PACKAGE_NAME"
mkdir -p "$DIST_PKG/bin" "$DIST_PKG/scripts"

# Copy compiled binary and CLI
cp "$PROJECT_DIR/dist/focuspal-engine" "$DIST_PKG/bin/"
cp "$PROJECT_DIR/bin/focuspal" "$DIST_PKG/bin/"
ln -sf focuspal "$DIST_PKG/bin/focus-guardian"
chmod +x "$DIST_PKG/bin/"*

# Copy management scripts
cp "$PROJECT_DIR/scripts/status.sh" "$DIST_PKG/scripts/"
cp "$PROJECT_DIR/scripts/reload.sh" "$DIST_PKG/scripts/"
cp "$PROJECT_DIR/scripts/uninstall.sh" "$DIST_PKG/scripts/"
cp "$PROJECT_DIR/scripts/start.sh" "$DIST_PKG/scripts/"
cp "$PROJECT_DIR/scripts/install.sh" "$DIST_PKG/scripts/"
cp "$PROJECT_DIR/scripts/verify-permissions.sh" "$DIST_PKG/scripts/"
cp "$PROJECT_DIR/scripts/install-root-daemon.sh" "$DIST_PKG/scripts/"
if [ -f "$PROJECT_DIR/scripts/com.focuspal.daemon.plist.template" ]; then
    cp "$PROJECT_DIR/scripts/com.focuspal.daemon.plist.template" "$DIST_PKG/scripts/"
fi
if [ -f "$PROJECT_DIR/scripts/com.focuspal.rootdaemon.plist.template" ]; then
    cp "$PROJECT_DIR/scripts/com.focuspal.rootdaemon.plist.template" "$DIST_PKG/scripts/"
fi
chmod +x "$DIST_PKG/scripts/"*.sh

# 5. Create compressed .tar.gz archive
TARBALL="$PROJECT_DIR/dist/${PACKAGE_NAME}.tar.gz"
tar -czvf "$TARBALL" -C "$PROJECT_DIR/dist/$PACKAGE_NAME" .

# 6. Compute SHA-256 Checksum
SHA256=$(shasum -a 256 "$TARBALL" | awk '{print $1}')

echo ""
echo "=========================================================="
echo " ✅ Build Complete!"
echo "=========================================================="
echo " • Archive: $TARBALL"
echo " • SHA-256: $SHA256"
echo ""
echo " 📋 Next Steps for Public Tap Distribution:"
echo " 1. Create public repo on GitHub: ShireenAzadSyed/homebrew-focuspal"
echo " 2. Upload '${PACKAGE_NAME}.tar.gz' to GitHub Releases (tag: v${VERSION})"
echo " 3. Put this SHA256 in your Formula/focuspal.rb:"
echo "    url \"https://github.com/ShireenAzadSyed/homebrew-focuspal/releases/download/v${VERSION}/${PACKAGE_NAME}.tar.gz\""
echo "    sha256 \"$SHA256\""
echo "=========================================================="
