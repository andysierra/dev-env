#!/bin/zsh
# Revierte el Caps Lock al comportamiento por defecto de macOS.
LABEL="local.capslock.nodelay"
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/${LABEL}.plist"
/usr/bin/hidutil property --set '{"CapsLockDelayOverride":100}' >/dev/null
echo "revertido: CapsLockDelayOverride = $(/usr/bin/hidutil property --get CapsLockDelayOverride)"
