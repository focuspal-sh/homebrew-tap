#!/bin/bash
# Focus Pal - Universal macOS Background Service Installer
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
OS_NAME="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS_NAME" = "Darwin" ]; then
    if [ "$(id -u)" = "0" ]; then
        echo "Run focuspal install from your macOS login session without sudo." >&2
        exit 1
    fi
    domain="gui/$(id -u)"
    for label in com.focuspal.rootdaemon com.focusguardian.rootdaemon; do
        if launchctl print "system/$label" >/dev/null 2>&1; then
            echo "A legacy root service is still running. Remove it with focuspal uninstall before installing the login agent." >&2
            exit 1
        fi
    done
    packaged_agent="/Library/LaunchAgents/com.focuspal.daemon.plist"
    if [ "$PROJECT_DIR" = "/Library/Application Support/FocusPal" ] && [ -f "$packaged_agent" ]; then
        "$SCRIPT_DIR/activate-package.sh"
        echo "Focus Pal is registered in your login session. Run focuspal permissions to enable a browser."
        exit 0
    fi
fi

# If invoked via `curl ... | bash` (no local bin/focuspal), locate existing install or download latest release
if [ ! -f "$PROJECT_DIR/bin/focuspal" ]; then
    if [ -f "/opt/homebrew/opt/focuspal/libexec/bin/focuspal" ]; then
        PROJECT_DIR="/opt/homebrew/opt/focuspal/libexec"
    elif [ -f "/usr/local/opt/focuspal/libexec/bin/focuspal" ]; then
        PROJECT_DIR="/usr/local/opt/focuspal/libexec"
    elif [ -f "/Library/Application Support/FocusPal/bin/focuspal" ]; then
        PROJECT_DIR="/Library/Application Support/FocusPal"
    elif [ -f "$HOME/.focuspal/app/bin/focuspal" ] && [ -z "${FOCUSPAL_FORCE_DOWNLOAD:-}" ]; then
        PROJECT_DIR="$HOME/.focuspal/app"
    else
        INSTALL_ROOT="$HOME/.focuspal/app"
        mkdir -p "$INSTALL_ROOT"
        echo " • Fetching latest Focus Pal release for $OS_NAME ($ARCH)..."
        ASSET_URL="$(curl -fsSL "https://api.github.com/repos/focuspal-sh/homebrew-tap/releases/latest" \
            | python3 -c "
import sys, json
data = json.load(sys.stdin)
os_name = '$OS_NAME'.lower()
arch = '$ARCH'.lower()
assets = data.get('assets', [])
url = ''
if os_name == 'linux':
    for a in assets:
        n = a['name'].lower()
        if f'linux-{arch}.tar.gz' in n:
            url = a['browser_download_url']; break
    if not url:
        for a in assets:
            if a['name'] == 'focuspal-linux-runtime.tar.gz':
                url = a['browser_download_url']; break
else:
    for a in assets:
        n = a['name'].lower()
        if n.endswith(f'-{arch}.tar.gz') and 'linux' not in n:
            url = a['browser_download_url']; break
print(url)
")"
        if [ -z "$ASSET_URL" ]; then
            echo "❌ Could not find a release asset for $OS_NAME ($ARCH) on focuspal-sh/homebrew-tap."
            exit 1
        fi
        TMP_TGZ="/tmp/focuspal-latest.tar.gz"
        curl -fsSL "$ASSET_URL" -o "$TMP_TGZ"
        rm -rf "${INSTALL_ROOT:?}"/*
        if tar -tzf "$TMP_TGZ" | grep -q '^bin/focuspal$'; then
            tar -xzf "$TMP_TGZ" -C "$INSTALL_ROOT"
        else
            tar -xzf "$TMP_TGZ" -C "$INSTALL_ROOT" --strip-components=1
        fi
        rm -f "$TMP_TGZ"
        PROJECT_DIR="$INSTALL_ROOT"
    fi
fi

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

# 3. Register OS background service
if [ "$OS_NAME" = "Darwin" ]; then
    # Stop and unload any existing service
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
    launchctl enable "$domain/com.focuspal.daemon"
    launchctl load -w "$TARGET_PLIST"
    launchctl start com.focuspal.daemon

    # 6. Verify service is active
    sleep 1
    if launchctl list | grep -q "com.focuspal.daemon"; then
        echo " • launchd Status:  ACTIVE (Auto-restarts if killed)"
    else
        echo " • Warning: Service registered. Checking process..."
    fi
else
    # Linux systemd user service (fallback to background script if no systemd user session)
    if command -v systemctl >/dev/null 2>&1 && systemctl --user status >/dev/null 2>&1; then
        SYSTEMD_DIR="$HOME/.config/systemd/user"
        mkdir -p "$SYSTEMD_DIR"
        if [ -x "$PROJECT_DIR/bin/focuspal-engine" ]; then
            EXEC_START="$PROJECT_DIR/bin/focuspal-engine"
        else
            EXEC_START="$PYTHON_BIN $PROJECT_DIR/daemon/guardian.py"
        fi
        cat <<EOF > "$SYSTEMD_DIR/focuspal.service"
[Unit]
Description=Focus Pal Distraction Blocker Daemon
After=graphical-session.target

[Service]
Type=simple
WorkingDirectory=$PROJECT_DIR
ExecStart=$EXEC_START
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
EOF
        systemctl --user daemon-reload
        systemctl --user enable --now focuspal
        echo " • systemd Status:  ACTIVE (~/.config/systemd/user/focuspal.service)"
    elif [ -x "$PROJECT_DIR/scripts/start.sh" ]; then
        "$PROJECT_DIR/scripts/start.sh"
    fi
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

if [ "$(uname)" = "Darwin" ]; then
    echo ' • Browser setup: Open a browser, then run focuspal permissions'
fi

echo "=========================================================="
echo " ✅ Focus Pal successfully installed and started!"
echo " • CLI Command:  focuspal {status|uninstall|reload|start|permissions}"
echo " • Web UI:       http://127.0.0.1:8989/blocked"
echo " • View Logs:    tail -f $PROJECT_DIR/logs/guardian.log"
echo "=========================================================="
