#!/bin/bash
# Focus Pal - Universal macOS Background Service Installer
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.focuspal.daemon.plist"
TARGET_PLIST="$LAUNCH_AGENTS_DIR/$PLIST_NAME"
TEMPLATE_PLIST="$PROJECT_DIR/scripts/com.focuspal.daemon.plist.template"
[ ! -f "$TEMPLATE_PLIST" ] && TEMPLATE_PLIST="$PROJECT_DIR/scripts/com.focusguardian.daemon.plist.template"

echo "=========================================================="
echo " 🔒  Installing Focus Pal as a macOS Background Service"
echo "=========================================================="

# 1. Resolve Python 3 executable
PYTHON_BIN="$(which python3 || echo "/usr/bin/python3")"
echo " • Detected Python: $PYTHON_BIN"
echo " • Project Dir:     $PROJECT_DIR"

# 2. Ensure log directory exists
mkdir -p "$PROJECT_DIR/logs"

# 3. Stop and unload any existing service
if launchctl list | grep -q "com.focuspal.daemon"; then
    echo " • Unloading existing Focus Pal service..."
    launchctl unload "$TARGET_PLIST" 2>/dev/null || true
fi
if launchctl list | grep -q "com.focusguardian.daemon"; then
    echo " • Unloading legacy service..."
    launchctl unload "$LAUNCH_AGENTS_DIR/com.focusguardian.daemon.plist" 2>/dev/null || true
fi

# 4. Generate dynamic LaunchAgent plist
mkdir -p "$LAUNCH_AGENTS_DIR"
if [ -x "$PROJECT_DIR/bin/focuspal-engine" ]; then
    PROGRAM_ARGS="        <string>$PROJECT_DIR/bin/focuspal-engine</string>"
elif [ -x "$PROJECT_DIR/bin/focus-guardian-engine" ]; then
    PROGRAM_ARGS="        <string>$PROJECT_DIR/bin/focus-guardian-engine</string>"
else
    PROGRAM_ARGS="        <string>$PYTHON_BIN</string>
        <string>$PROJECT_DIR/daemon/guardian.py</string>"
fi

cat <<EOF > "$TARGET_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.focuspal.daemon</string>
    <key>ProgramArguments</key>
    <array>
$PROGRAM_ARGS
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

# 5. Load and start the LaunchAgent
echo " • Registering with macOS launchd: $TARGET_PLIST"
launchctl load -w "$TARGET_PLIST"
launchctl start com.focuspal.daemon

# 6. Verify service is active
sleep 1
if launchctl list | grep -q "com.focuspal.daemon"; then
    echo " • launchd Status:  ACTIVE (Auto-restarts if killed)"
else
    echo " • Warning: Service registered. Checking process..."
fi

# 7. Symlink focuspal CLI to system PATH
echo "==> Setting up 'focuspal' command in your PATH..."
CLI_SRC="$PROJECT_DIR/bin/focuspal"
chmod +x "$CLI_SRC" 2>/dev/null || true

LINKED=0
for BIN_DIR in "/opt/homebrew/bin" "/usr/local/bin" "$HOME/.local/bin"; do
    if [ -d "$BIN_DIR" ] && [ -w "$BIN_DIR" ]; then
        ln -sf "$CLI_SRC" "$BIN_DIR/focuspal"
        ln -sf "$CLI_SRC" "$BIN_DIR/focus-guardian"
        echo " • Linked: $BIN_DIR/focuspal (and alias focus-guardian)"
        LINKED=1
        break
    fi
done

if [ "$LINKED" -eq 0 ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$CLI_SRC" "$HOME/.local/bin/focuspal"
    ln -sf "$CLI_SRC" "$HOME/.local/bin/focus-guardian"
    echo " • Linked: $HOME/.local/bin/focuspal"
fi

# 8. Verify and proactively request all required macOS permissions
if [ "$(uname)" = "Darwin" ] && [ -f "$PROJECT_DIR/scripts/verify-permissions.sh" ]; then
    echo ""
    chmod +x "$PROJECT_DIR/scripts/verify-permissions.sh"
    "$PROJECT_DIR/scripts/verify-permissions.sh"
fi

echo "=========================================================="
echo " ✅ Focus Pal successfully installed and started!"
echo " • CLI Command:  focuspal {status|stop|reload|start|permissions}"
echo " • Web UI:       http://127.0.0.1:8989/blocked"
echo " • View Logs:    tail -f $PROJECT_DIR/logs/guardian.log"
echo "=========================================================="
