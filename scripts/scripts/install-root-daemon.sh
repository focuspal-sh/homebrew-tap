#!/bin/bash
# Focus Pal - Universal Root System Daemon Installer (Permanent & Tamper-Proof)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PYTHON_BIN="$(which python3 || echo "/usr/bin/python3")"

PLIST_NAME="com.focuspal.rootdaemon.plist"
TEMPLATE_PLIST="$PROJECT_DIR/scripts/com.focuspal.rootdaemon.plist.template"
TARGET_DIR="/Library/LaunchDaemons"
TARGET_PLIST="$TARGET_DIR/$PLIST_NAME"

echo "=========================================================="
echo " 🔒  Installing Focus Pal as a Root System Daemon"
echo " (Requires sudo password once to lock against uninstallation)"
echo "=========================================================="
echo " • Detected Project Directory: $PROJECT_DIR"
echo " • Detected Python 3 Runtime:  $PYTHON_BIN"

# 1. Ensure logs directory exists
mkdir -p "$PROJECT_DIR/logs"
chmod 777 "$PROJECT_DIR/logs"

# 2. Make scripts executable
chmod +x "$PROJECT_DIR/scripts/"*.sh 2>/dev/null || true
if [ -d "$PROJECT_DIR/bin" ]; then
    chmod +x "$PROJECT_DIR/bin/"* 2>/dev/null || true
fi

# 3. Generate root plist dynamically
TEMP_PLIST="/tmp/$PLIST_NAME"

ENGINE_BIN="$PROJECT_DIR/bin/focuspal-engine"
[ ! -x "$ENGINE_BIN" ] && ENGINE_BIN="$PROJECT_DIR/bin/focus-guardian-engine"

if [ -x "$ENGINE_BIN" ]; then
    cat << EOF > "$TEMP_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.focuspal.rootdaemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>$ENGINE_BIN</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$PROJECT_DIR/logs/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$PROJECT_DIR/logs/stderr.log</string>
    <key>WorkingDirectory</key>
    <string>$PROJECT_DIR</string>
</dict>
</plist>
EOF
else
    chmod +x "$PROJECT_DIR/daemon/guardian.py" 2>/dev/null || true
    chmod +x "$PROJECT_DIR/server/server.py" 2>/dev/null || true
    sed -e "s|{{PYTHON_BIN}}|$PYTHON_BIN|g" \
        -e "s|{{PROJECT_DIR}}|$PROJECT_DIR|g" \
        "$TEMPLATE_PLIST" > "$TEMP_PLIST"
fi

# 4. Copy to /Library/LaunchDaemons with root ownership
echo "==> Installing into $TARGET_DIR..."
sudo cp "$TEMP_PLIST" "$TARGET_PLIST"
rm -f "$TEMP_PLIST"
sudo chown root:wheel "$TARGET_PLIST"
sudo chmod 644 "$TARGET_PLIST"

# 5. Load into root launchd
echo "==> Registering with root launchd (KeepAlive=true, RunAtLoad=true)..."
sudo launchctl unload "$TARGET_PLIST" 2>/dev/null || true
sudo launchctl load -w "$TARGET_PLIST"

echo "=========================================================="
echo " ✅ Focus Pal is now locked as a ROOT SYSTEM DAEMON!"
echo ""
echo " • Status: Running with root privileges."
echo " • Tamper Protection: Normal users cannot kill it in Activity Monitor."
echo " • Auto-Respawn: If terminated, macOS restarts it immediately."
echo " • Multi-Browser: Guards Safari, Chrome, Brave, Arc, Edge, etc."
echo " • Reflection Page: http://127.0.0.1:8989/blocked"
echo "=========================================================="
