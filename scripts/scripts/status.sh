#!/bin/bash
# Focus Pal - Status Check

echo "=========================================================="
echo " 🤝  Focus Pal Status Check"
echo "=========================================================="

echo -n "• Daemon Process: "
if pgrep -f "focuspal-engine" > /dev/null || pgrep -f "focus-guardian-engine" > /dev/null || pgrep -f "guardian.py" > /dev/null; then
    PID=$(pgrep -f "focuspal-engine" 2>/dev/null | head -n 1)
    [ -z "$PID" ] && PID=$(pgrep -f "focus-guardian-engine" 2>/dev/null | head -n 1)
    [ -z "$PID" ] && PID=$(pgrep -f "guardian.py" 2>/dev/null | head -n 1)
    echo "RUNNING (PID: $PID)"
else
    echo "NOT RUNNING"
fi

echo -n "• Reflection HTTP Server: "
if curl -s http://127.0.0.1:8989/api/status | grep -q "running"; then
    echo "HEALTHY (http://127.0.0.1:8989/blocked)"
else
    echo "OFFLINE"
fi

echo -n "• macOS Launchd Registration: "
if launchctl list | grep -E -q "(com\.(focuspal|focusguardian|lockin)|homebrew\.mxcl\.(focuspal|focus-guardian|lockin))" \
   || sudo -n launchctl list 2>/dev/null | grep -E -q "(com\.(focuspal|focusguardian|lockin)|homebrew\.mxcl\.(focuspal|focus-guardian|lockin))" \
   || [ -f "/Library/LaunchDaemons/com.focuspal.rootdaemon.plist" ] \
   || [ -f "/Library/LaunchDaemons/com.focusguardian.rootdaemon.plist" ] \
   || [ -f "$HOME/Library/LaunchAgents/com.focuspal.daemon.plist" ] \
   || [ -f "$HOME/Library/LaunchAgents/homebrew.mxcl.focuspal.plist" ]; then
    echo "REGISTERED & ACTIVE (KeepAlive: true)"
else
    echo "NOT REGISTERED (Run: focuspal install  OR  brew services start focuspal)"
fi

echo "=========================================================="
