#!/bin/bash
# Focus Pal - Hot Reload Trigger
# Also called automatically by brew upgrade / brew services start
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Trigger locations: dev/source mode & frozen brew-installed mode
RELOAD_PATHS=(
    "$PROJECT_DIR/config/reload.trigger"
    "$HOME/.focuspal/config/reload.trigger"
    "$HOME/.focus-guardian/config/reload.trigger"
)

echo "==> Triggering Focus Pal daemon reload..."

for RPATH in "${RELOAD_PATHS[@]}"; do
    mkdir -p "$(dirname "$RPATH")" 2>/dev/null || true
    touch "$RPATH" 2>/dev/null || true
done

# Give daemon up to 3s to pick up the reload trigger
for i in {1..6}; do
    sleep 0.5
    # Check if trigger was consumed (daemon picked it up)
    PENDING=0
    for RPATH in "${RELOAD_PATHS[@]}"; do
        [ -f "$RPATH" ] && PENDING=1
    done
    [ "$PENDING" -eq 0 ] && break
done

echo "==> Checking status after reload..."
"$PROJECT_DIR/scripts/status.sh"
