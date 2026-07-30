#!/bin/zsh
# Hotkey global (Option+Command+E, via Karabiner-Elements):
# abre yazi en ~/Desktop, en iTerm, maximizado y SIEMPRE en la misma ventana.
# Si esa ventana ya existe, solo la trae al frente en vez de abrir otra.

STATE="$HOME/.cache/yazi-desktop-window"
mkdir -p "${STATE:h}"

known=$(cat "$STATE" 2>/dev/null)
id=$(/usr/bin/osascript -l JavaScript "$HOME/bin/yazi-desktop.js" "$known" 2>/dev/null)

if [[ "$id" == <-> ]]; then
  print -r -- "$id" > "$STATE"
else
  rm -f "$STATE"
  exit 1
fi
