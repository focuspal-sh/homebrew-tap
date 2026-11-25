#!/bin/bash
# Focus Pal - Enterprise macOS PKG Builder for MDM Deployment (Jamf, Kandji, Intune)
set -e
export COPYFILE_DISABLE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

VERSION="${1:-1.0.6}"
PKG_NAME="FocusPal-v${VERSION}.pkg"
BUILD_DIR="$PROJECT_DIR/build/pkg-build"
PKG_ROOT="$BUILD_DIR/root"
PKG_SCRIPTS="$BUILD_DIR/scripts"

echo "=========================================================="
echo " 🏢 Focus Pal Enterprise PKG Builder"
echo " Target Package: $PKG_NAME"
echo "=========================================================="

# 1. Ensure standalone binary exists
BINARY_SOURCE="$PROJECT_DIR/dist/focuspal-engine"
if [ ! -f "$BINARY_SOURCE" ]; then
    ARCH="$(uname -m)"
    if [ -f "$PROJECT_DIR/dist/focuspal-v${VERSION}-${ARCH}/bin/focuspal-engine" ]; then
        BINARY_SOURCE="$PROJECT_DIR/dist/focuspal-v${VERSION}-${ARCH}/bin/focuspal-engine"
    elif [ -f "$PROJECT_DIR/dist/focus-guardian-v${VERSION}-${ARCH}/bin/focuspal-engine" ]; then
        BINARY_SOURCE="$PROJECT_DIR/dist/focus-guardian-v${VERSION}-${ARCH}/bin/focuspal-engine"
    else
        echo "==> Native binary not found. Compiling binary first..."
        "$PROJECT_DIR/scripts/build-binary.sh" "$VERSION"
    fi
fi

# 2. Prepare payload structure
echo "==> Preparing PKG filesystem payload..."
rm -rf "$BUILD_DIR"
mkdir -p "$PKG_ROOT/usr/local/bin"
mkdir -p "$PKG_ROOT/Library/LaunchDaemons"
mkdir -p "$PKG_ROOT/Library/Application Support/FocusPal/config"
mkdir -p "$PKG_ROOT/Library/Application Support/FocusPal/scripts"
mkdir -p "$PKG_SCRIPTS"

# Binaries
cp "$BINARY_SOURCE" "$PKG_ROOT/usr/local/bin/focuspal-engine"
cp "$PROJECT_DIR/bin/focuspal" "$PKG_ROOT/usr/local/bin/focuspal"
chmod 755 "$PKG_ROOT/usr/local/bin/"*

# Ensure ad-hoc code signature with bundle identifier for TCC matching
codesign -s - --force --identifier com.focuspal.engine "$PKG_ROOT/usr/local/bin/focuspal-engine" 2>/dev/null || true

# Management Scripts
cp "$PROJECT_DIR/scripts/status.sh" "$PKG_ROOT/Library/Application Support/FocusPal/scripts/"
cp "$PROJECT_DIR/scripts/verify-permissions.sh" "$PKG_ROOT/Library/Application Support/FocusPal/scripts/"
cp "$PROJECT_DIR/scripts/start.sh" "$PKG_ROOT/Library/Application Support/FocusPal/scripts/"
cp "$PROJECT_DIR/scripts/reload.sh" "$PKG_ROOT/Library/Application Support/FocusPal/scripts/"
cp "$PROJECT_DIR/scripts/uninstall.sh" "$PKG_ROOT/Library/Application Support/FocusPal/scripts/"
cp "$PROJECT_DIR/scripts/install-root-daemon.sh" "$PKG_ROOT/Library/Application Support/FocusPal/scripts/"
cp "$PROJECT_DIR/scripts/install.sh" "$PKG_ROOT/Library/Application Support/FocusPal/scripts/"
chmod 755 "$PKG_ROOT/Library/Application Support/FocusPal/scripts/"*

# LaunchDaemon Plist
cat <<EOF > "$PKG_ROOT/Library/LaunchDaemons/com.focuspal.rootdaemon.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.focuspal.rootdaemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/focuspal-engine</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/focuspal.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/focuspal-error.log</string>
    <key>WorkingDirectory</key>
    <string>/Library/Application Support/FocusPal</string>
</dict>
</plist>
EOF
chmod 644 "$PKG_ROOT/Library/LaunchDaemons/com.focuspal.rootdaemon.plist"

# Configuration defaults
cp "$PROJECT_DIR/config/config.json" "$PKG_ROOT/Library/Application Support/FocusPal/config/config.json"
cp "$PROJECT_DIR/config/quotes.json" "$PKG_ROOT/Library/Application Support/FocusPal/config/quotes.json"

# 3. Create postinstall script
cat <<'EOF' > "$PKG_SCRIPTS/postinstall"
#!/bin/bash
set -e

# Set proper ownership & permissions
chown -R root:wheel "/Library/Application Support/FocusPal"
chown root:wheel "/Library/LaunchDaemons/com.focuspal.rootdaemon.plist"
chmod 644 "/Library/LaunchDaemons/com.focuspal.rootdaemon.plist"
chmod 755 "/usr/local/bin/focuspal" "/usr/local/bin/focuspal-engine"
chmod 755 "/Library/Application Support/FocusPal/scripts/"*

# Load root LaunchDaemon
if [ -f "/Library/LaunchDaemons/com.focuspal.rootdaemon.plist" ]; then
    launchctl bootout system/com.focuspal.rootdaemon 2>/dev/null || true
    launchctl bootstrap system "/Library/LaunchDaemons/com.focuspal.rootdaemon.plist" 2>/dev/null || \
    launchctl load -w "/Library/LaunchDaemons/com.focuspal.rootdaemon.plist" 2>/dev/null || true
fi

exit 0
EOF
chmod 755 "$PKG_SCRIPTS/postinstall"

# 4. Clean extended attributes & build .pkg with macOS pkgbuild
echo "==> Cleaning extended attributes & building installer package..."
find "$PKG_ROOT" -name "._*" -delete 2>/dev/null || true
xattr -cr "$PKG_ROOT" 2>/dev/null || true
dot_clean -m "$PKG_ROOT" 2>/dev/null || true
mkdir -p "$PROJECT_DIR/dist"

SIGN_ARGS=()
if [ -n "$SIGN_IDENTITY" ]; then
    echo "==> Signing package with certificate: $SIGN_IDENTITY"
    SIGN_ARGS+=(--sign "$SIGN_IDENTITY")
fi

pkgbuild --root "$PKG_ROOT" \
         --identifier com.focuspal.pkg \
         --version "$VERSION" \
         --install-location / \
         --scripts "$PKG_SCRIPTS" \
         "${SIGN_ARGS[@]}" \
         "$PROJECT_DIR/dist/$PKG_NAME"

echo ""
echo "=========================================================="
echo " ✅ Enterprise PKG Ready: dist/$PKG_NAME"
echo " 📄 Silent TCC Profile:   scripts/com.focuspal.tcc.mobileconfig"
echo "=========================================================="

