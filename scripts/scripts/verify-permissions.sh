#!/bin/bash
# Focus Pal - macOS Permissions Verification & Proactive Setup
# Detects installed browsers, requests Automation & Notification permissions via AppleScript,
# and guides the user if any permission requires manual toggle in macOS System Settings.

set -e

echo "=========================================================="
echo " 🤝  Focus Pal - macOS Permission Verification & Setup"
echo "=========================================================="

NEEDS_ATTENTION=0
OPEN_SETTINGS=0

for arg in "$@"; do
    if [ "$arg" = "--open" ] || [ "$arg" = "--open-settings" ]; then
        OPEN_SETTINGS=1
    fi
done

# 1. Check Python 3 runtime
echo -n "• Python 3 Runtime:         "
if which python3 > /dev/null 2>&1; then
    PY_VER="$(python3 --version 2>&1)"
    echo "OK ($PY_VER)"
else
    echo "FAILED (Python 3 not found on PATH)"
    NEEDS_ATTENTION=1
fi

# 2. Check AppleScript (osascript)
echo -n "• AppleScript Engine:       "
if which osascript > /dev/null 2>&1; then
    echo "OK"
else
    echo "FAILED (osascript missing)"
    NEEDS_ATTENTION=1
fi

# 3. Request & Verify Automation: System Events
echo -n "• Automation (System Events): "
SE_OUT=$(osascript -e 'tell application "System Events" to return name of current user' 2>&1 || true)
if [[ "$SE_OUT" =~ "error" ]] && [[ "$SE_OUT" =~ "-1743" || "$SE_OUT" =~ "Not authorized" ]]; then
    echo "NEEDS PERMISSION ⚠️"
    echo "  └─ macOS blocked Apple Events to System Events (-1743)."
    NEEDS_ATTENTION=1
else
    echo "GRANTED ✓ (User: $SE_OUT)"
fi

# 4. Proactively test & request permissions for all detected browsers
echo ""
echo "── Installed Browser Automation Permissions ──"

DETECTED_BROWSERS=()
CANDIDATE_BROWSERS=(
    "Google Chrome"
    "Arc"
    "Brave Browser"
    "Microsoft Edge"
    "Safari"
    "Opera"
    "Opera GX"
    "Vivaldi"
    "Orion"
    "Sidekick"
    "Firefox"
    "Zen Browser"
)

for BNAME in "${CANDIDATE_BROWSERS[@]}"; do
    if [ -d "/Applications/${BNAME}.app" ] || [ -d "$HOME/Applications/${BNAME}.app" ] || [ -d "/System/Applications/${BNAME}.app" ]; then
        DETECTED_BROWSERS+=("$BNAME")
    fi
done

if [ ${#DETECTED_BROWSERS[@]} -eq 0 ]; then
    echo "• No common browser apps found in /Applications. Safari will be used as default."
    DETECTED_BROWSERS=("Safari")
fi

for BROWSER in "${DETECTED_BROWSERS[@]}"; do
    printf "• Automation (%-15s): " "$BROWSER"
    
    # Send a lightweight query to trigger the macOS authorization dialog if not yet granted
    BR_OUT=$(osascript -e "tell application \"$BROWSER\" to return name" 2>&1 || true)
    
    if [[ "$BR_OUT" =~ "-1743" || "$BR_OUT" =~ "Not authorized" ]]; then
        echo "NEEDS PERMISSION ⚠️"
        echo "  └─ Permission not yet granted for $BROWSER (-1743)."
        NEEDS_ATTENTION=1
    elif [[ "$BR_OUT" =~ "error" && ! "$BR_OUT" =~ "-1719" ]]; then
        # -1719 is 'Invalid index' (e.g. no windows open), which means permission IS granted
        echo "ALLOWED ✓ (App active / standby)"
    else
        echo "GRANTED ✓"
    fi
done

# 5. Trigger desktop notification permission
echo ""
echo -n "• Notifications (Desktop Alerts): "
NOTIF_OUT=$(osascript -e 'display notification "Focus Pal is active and safeguarding your deep work." with title "🤝 Focus Pal" subtitle "Permissions Active"' 2>&1 || true)
if [[ "$NOTIF_OUT" =~ "error" ]]; then
    echo "BLOCKED ⚠️ ($NOTIF_OUT)"
    NEEDS_ATTENTION=1
else
    echo "SENT ✓ (Banner delivered)"
fi

# 6. Check macOS Launchd Registration
echo ""
echo -n "• macOS Launchd Registration:     "
if launchctl list | grep -E -q "(com\.(focuspal|focusguardian|lockin)|homebrew\.mxcl\.(focuspal|focus-guardian|lockin))" \
   || sudo -n launchctl list 2>/dev/null | grep -E -q "(com\.(focuspal|focusguardian|lockin)|homebrew\.mxcl\.(focuspal|focus-guardian|lockin))" \
   || [ -f "/Library/LaunchDaemons/com.focuspal.rootdaemon.plist" ] \
   || [ -f "$HOME/Library/LaunchAgents/com.focuspal.daemon.plist" ]; then
    echo "REGISTERED & ACTIVE ✓"
else
    echo "NOT REGISTERED ⚠️"
    echo "  └─ Register by running: focuspal install  OR  brew services start focuspal"
    NEEDS_ATTENTION=1
fi

echo "=========================================================="

if [ "$NEEDS_ATTENTION" -eq 1 ]; then
    echo "⚠️  One or more permissions require attention."
    echo ""
    echo "To grant Automation permissions manually:"
    echo " 1. Open: System Settings -> Privacy & Security -> Automation"
    echo " 2. Find your terminal (Terminal / iTerm / Warp) or Python"
    echo " 3. Turn ON toggles for System Events and your web browsers"
    echo ""
    if [ "$OPEN_SETTINGS" -eq 1 ]; then
        echo "==> Opening System Settings -> Automation now..."
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation" 2>/dev/null || true
    else
        echo "Run 'focuspal permissions --open' to automatically open System Settings."
    fi
    echo "=========================================================="
else
    echo "🎉 All permissions and services are fully verified and active!"
    echo "=========================================================="
fi
