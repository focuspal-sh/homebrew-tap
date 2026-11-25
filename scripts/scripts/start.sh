#!/bin/bash
# Focus Pal - Service Launcher (Detached Background by Default)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

mkdir -p "$PROJECT_DIR/logs"
chmod +x "$PROJECT_DIR/daemon/guardian.py" 2>/dev/null || true
chmod +x "$PROJECT_DIR/server/server.py" 2>/dev/null || true

# 1. Check if launchd is active and already managing the daemon
IS_LAUNCHD_ACTIVE=0
if launchctl list 2>/dev/null | grep -E -q "(com\.(focuspal|focusguardian|lockin)|homebrew\.mxcl\.(focuspal|focus-guardian|lockin))" \
   || sudo -n launchctl list 2>/dev/null | grep -E -q "(com\.(focuspal|focusguardian|lockin)|homebrew\.mxcl\.(focuspal|focus-guardian|lockin))" \
   || [ -f "/Library/LaunchDaemons/com.focuspal.rootdaemon.plist" ]; then
    IS_LAUNCHD_ACTIVE=1
fi

# If already running AND registered in launchd, trigger hot-reload and exit
if (pgrep -f "focuspal-engine" > /dev/null || pgrep -f "focus-guardian-engine" > /dev/null || pgrep -f "guardian.py" > /dev/null) && [ "$IS_LAUNCHD_ACTIVE" -eq 1 ]; then
    PID=$(pgrep -f "focuspal-engine" 2>/dev/null | head -n 1)
    [ -z "$PID" ] && PID=$(pgrep -f "focus-guardian-engine" 2>/dev/null | head -n 1)
    [ -z "$PID" ] && PID=$(pgrep -f "guardian.py" 2>/dev/null | head -n 1)
    echo "=========================================================="
    echo " 🤝  Focus Pal is ALREADY running and registered in launchd"
    echo "=========================================================="
    echo " • Process ID:   PID $PID (Launchd KeepAlive: active)"
    echo " • Triggering hot-reload to pick up latest code..."
    for RPATH in "$PROJECT_DIR/config/reload.trigger" "$HOME/.focuspal/config/reload.trigger" "$HOME/.focus-guardian/config/reload.trigger"; do
        mkdir -p "$(dirname "$RPATH")" 2>/dev/null || true
        touch "$RPATH" 2>/dev/null || true
    done
    echo " • Status:       focuspal status"
    echo " • View Logs:    tail -f $PROJECT_DIR/logs/guardian.log"
    echo " • Shutdown:     focuspal stop"
    echo "=========================================================="
    exit 0
fi

# 2. Foreground mode flag (--foreground, -f, or test)
if [ "$1" = "--foreground" ] || [ "$1" = "-f" ]; then
    echo "=========================================================="
    echo " 🔒  Starting Focus Pal in FOREGROUND mode..."
    echo " (Terminal attached • Press Ctrl+C to stop)"
    echo "=========================================================="
    if [ -x "$PROJECT_DIR/bin/focuspal-engine" ]; then
        exec "$PROJECT_DIR/bin/focuspal-engine"
    elif [ -x "$PROJECT_DIR/bin/focus-guardian-engine" ]; then
        exec "$PROJECT_DIR/bin/focus-guardian-engine"
    else
        exec python3 "$PROJECT_DIR/daemon/guardian.py"
    fi
fi

# 3. Default: Start Detached in Background
echo "=========================================================="
echo " 🔒  Starting Focus Pal in BACKGROUND..."
echo "=========================================================="

USER_PLIST="$HOME/Library/LaunchAgents/com.focuspal.daemon.plist"
OLD_USER_PLIST="$HOME/Library/LaunchAgents/com.focusguardian.daemon.plist"
ROOT_PLIST="/Library/LaunchDaemons/com.focuspal.rootdaemon.plist"
OLD_ROOT_PLIST="/Library/LaunchDaemons/com.focusguardian.rootdaemon.plist"

# Option A: Native macOS launchd service
if [ "$(uname)" = "Darwin" ]; then
    if [ -f "$ROOT_PLIST" ]; then
        echo "==> Triggering root system daemon..."
        sudo launchctl start com.focuspal.rootdaemon 2>/dev/null || true
    elif [ -f "$OLD_ROOT_PLIST" ]; then
        sudo launchctl start com.focusguardian.rootdaemon 2>/dev/null || true
    elif which brew >/dev/null 2>&1 && brew list focuspal >/dev/null 2>&1; then
        echo "==> Registering with Homebrew launchd service..."
        brew services start focuspal 2>/dev/null || true
    elif [ -f "$USER_PLIST" ]; then
        echo "==> Loading user LaunchAgent ($USER_PLIST)..."
        launchctl unload "$USER_PLIST" 2>/dev/null || true
        launchctl load -w "$USER_PLIST" 2>/dev/null || launchctl start com.focuspal.daemon 2>/dev/null || true
    elif [ -f "$PROJECT_DIR/scripts/install.sh" ]; then
        echo "==> Installing and registering persistent LaunchAgent..."
        "$PROJECT_DIR/scripts/install.sh"
    fi
fi

# Option B: Fallback detached background process (nohup + disown)
sleep 0.8
if ! pgrep -f "focuspal-engine" > /dev/null && ! pgrep -f "focus-guardian-engine" > /dev/null && ! pgrep -f "guardian.py" > /dev/null; then
    echo "==> Starting daemon detached via nohup..."
    ENGINE_BIN="$PROJECT_DIR/bin/focuspal-engine"
    [ ! -x "$ENGINE_BIN" ] && ENGINE_BIN="$PROJECT_DIR/bin/focus-guardian-engine"
    if [ -x "$ENGINE_BIN" ]; then
        nohup "$ENGINE_BIN" >> "$PROJECT_DIR/logs/stdout.log" 2>> "$PROJECT_DIR/logs/stderr.log" &
    else
        nohup python3 "$PROJECT_DIR/daemon/guardian.py" >> "$PROJECT_DIR/logs/stdout.log" 2>> "$PROJECT_DIR/logs/stderr.log" &
    fi
    disown
    sleep 0.6
fi

PID=$(pgrep -f "focuspal-engine" 2>/dev/null | head -n 1)
[ -z "$PID" ] && PID=$(pgrep -f "focus-guardian-engine" 2>/dev/null | head -n 1)
[ -z "$PID" ] && PID=$(pgrep -f "guardian.py" 2>/dev/null | head -n 1)

if [ -n "$PID" ]; then
    echo " ✅ Focus Pal is running in the background (PID: $PID)"
    echo " • Safe from accidental Ctrl+C or terminal closure."
    echo " • Check health: focuspal status"
    echo " • Stream logs:  tail -f $PROJECT_DIR/logs/guardian.log"
    echo " • Foreground:   focuspal test"
    echo " • Shutdown:     focuspal stop (with commitment pledge)"
    echo "=========================================================="
else
    echo " ⚠️  Could not verify process startup. Check: $PROJECT_DIR/logs/stderr.log"
fi
