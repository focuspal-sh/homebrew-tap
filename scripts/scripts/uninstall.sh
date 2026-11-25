#!/bin/bash
# Focus Pal - Anti-Tamper & Friction-Protected Uninstaller
# Designed to prevent impulsive quitting and keep you committed to your goals.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================================="
echo " 🔒  LOCKIN — COMMITMENT CHECK"
echo "=========================================================="

# -----------------------------------------------------------------------------
# 1. Native macOS System Warning Popup Dialog
# -----------------------------------------------------------------------------
if [ -z "$LOCKIN_FORCE" ] && [ -z "$FOCUS_GUARDIAN_FORCE" ]; then
    ALERT_RESULT=$(osascript << 'APPLESCRIPT' 2>/dev/null || echo "HEADLESS"
try
  set dialogResult to display alert "🔒 Focus Pal — Tamper Shield" message "Are you sure you want to disable your protection and surrender your focus?\n\nTake a deep breath before quitting." as critical buttons {"Stay Locked In", "I Want to Quit"} default button "Stay Locked In" cancel button "Stay Locked In"
  return "QUIT"
on error number -128
  return "STAY"
end try
APPLESCRIPT
)

    if [ "$ALERT_RESULT" = "STAY" ]; then
        echo ""
        echo " ✅ Decision Respected!"
        echo " Your Focus Pal Shield remains ACTIVE."
        echo " Back to deep work — your future self will thank you. 💪"
        echo "=========================================================="
        exit 0
    fi

    # -------------------------------------------------------------------------
    # 2. Impulsive Action Delay (30-Second Cooling-Off Period)
    # -------------------------------------------------------------------------
    echo ""
    echo "⚠️  You requested to stop Focus Pal."
    echo "⏳ 30-Second Cooling-off period active to break impulsive dopamine cravings..."
    echo "   Take 3 slow breaths. Press Ctrl+C at any moment to cancel and keep your focus."
    echo ""

    for i in {30..1}; do
        printf "\r   ⏳ Time remaining: %2d seconds (Press Ctrl+C to cancel)... " "$i"
        sleep 1
    done
    printf "\r   ⏳ Cooling-off complete.                                          \n\n"

    # -------------------------------------------------------------------------
    # 3. Cognitive Commitment Pledge Challenge
    # -------------------------------------------------------------------------
    PLEDGE="I choose distraction over my future"
    echo "To confirm shutdown, type the following phrase exactly as shown:"
    echo "   \"$PLEDGE\""
    echo ""
    read -r -p "Enter phrase: " USER_INPUT

    if [ "$USER_INPUT" != "$PLEDGE" ]; then
        echo ""
        echo "❌ Phrase did not match. Focus Pal remains ACTIVE."
        echo "   Stay focused and return to your goals."
        echo "=========================================================="
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# 4. Service Teardown — Immediate & Complete
# -----------------------------------------------------------------------------
echo ""
echo "==> Verified. Proceeding with immediate service shutdown..."

# 4a. Stop via brew services (marks it disabled so KeepAlive won't restart it)
if command -v brew &>/dev/null; then
    echo "==> Stopping brew service..."
    brew services stop focuspal 2>/dev/null || true
    brew services stop focus-guardian 2>/dev/null || true
    sleep 0.5
fi

# 4b. Unload and DISABLE the LaunchAgent so KeepAlive does NOT restart it
for PLIST_NAME in "com.focuspal.daemon.plist" "com.focusguardian.daemon.plist"; do
    USER_PLIST="$HOME/Library/LaunchAgents/$PLIST_NAME"
    if [ -f "$USER_PLIST" ]; then
        echo "==> Unloading and disabling user LaunchAgent ($PLIST_NAME)..."
        launchctl unload -w "$USER_PLIST" 2>/dev/null || true
        rm -f "$USER_PLIST"
    fi
done

launchctl bootout "gui/$(id -u)/com.focuspal.daemon" 2>/dev/null || true
launchctl bootout "gui/$(id -u)/com.focusguardian.daemon" 2>/dev/null || true
sleep 0.3

# 4c. Check and unload Root Daemon (requires sudo)
for ROOT_PLIST in "/Library/LaunchDaemons/com.focuspal.rootdaemon.plist" "/Library/LaunchDaemons/com.focusguardian.rootdaemon.plist"; do
    if [ -f "$ROOT_PLIST" ]; then
        echo "==> Detected Root Lock ($ROOT_PLIST). Root privileges required to unload..."
        sudo launchctl unload -w "$ROOT_PLIST" 2>/dev/null || true
        sudo rm -f "$ROOT_PLIST"
        echo "==> Root system daemon removed."
    fi
done

# 4d. Clear any reload triggers to avoid phantom restarts
rm -f "$PROJECT_DIR/config/reload.trigger" 2>/dev/null || true
rm -f "$HOME/.focuspal/config/reload.trigger" 2>/dev/null || true
rm -f "$HOME/.focus-guardian/config/reload.trigger" 2>/dev/null || true

# 4e. Force-kill any remaining processes (belt & suspenders)
echo "==> Terminating any remaining Focus Pal processes..."
pkill -SIGTERM -f "focuspal-engine" 2>/dev/null || true
pkill -SIGTERM -f "focus-guardian-engine" 2>/dev/null || true
pkill -SIGTERM -f "guardian.py" 2>/dev/null || true
pkill -SIGTERM -f "server.py" 2>/dev/null || true
sleep 0.5
# SIGKILL if still alive
pkill -SIGKILL -f "focuspal-engine" 2>/dev/null || true
pkill -SIGKILL -f "focus-guardian-engine" 2>/dev/null || true
pkill -SIGKILL -f "guardian.py" 2>/dev/null || true
pkill -SIGKILL -f "server.py" 2>/dev/null || true

# 4f. Verify shutdown (wait up to 2s)
STOPPED=0
for i in {1..4}; do
    sleep 0.5
    if ! pgrep -f "guardian.py" >/dev/null 2>&1 && ! pgrep -f "focuspal-engine" >/dev/null 2>&1 && ! pgrep -f "focus-guardian-engine" >/dev/null 2>&1; then
        STOPPED=1
        break
    fi
done

if [ "$STOPPED" -eq 1 ]; then
    echo "✅ All Focus Pal processes confirmed stopped immediately."
else
    echo "⚠️  Some processes may still be shutting down. Run 'focuspal status' to verify."
fi

echo "=========================================================="
echo " ⚠️  Focus Pal has been disabled."
echo " To reactivate anytime, run:"
echo "   focuspal start   (or brew services start focuspal)"
echo "=========================================================="
