#!/bin/zsh
# macOS - Caps Lock sin delay. Idempotente: se puede correr las veces que sea.
set -e

LABEL="local.capslock.nodelay"
PLIST_SRC="$(cd "$(dirname "$0")" && pwd)/${LABEL}.plist"
PLIST_DST="$HOME/Library/LaunchAgents/${LABEL}.plist"

# 1. aplicar YA en la sesion actual
/usr/bin/hidutil property --set '{"CapsLockDelayOverride":0}' >/dev/null

# 2. dejarlo persistente en cada login
mkdir -p "$HOME/Library/LaunchAgents"
cp "$PLIST_SRC" "$PLIST_DST"
/usr/bin/plutil -lint "$PLIST_DST" >/dev/null
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"

# 3. verificar
echo "CapsLockDelayOverride = $(/usr/bin/hidutil property --get CapsLockDelayOverride)"
launchctl print "gui/$(id -u)/${LABEL}" | grep -E '^\s+state = ' || true
