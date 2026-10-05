#!/bin/zsh
# Hotkey global (Option+Command+E, via Karabiner-Elements):
# abre yazi en ~/Desktop, en una ventana NUEVA de iTerm, maximizada y titulada "yazi".
exec /usr/bin/osascript -l JavaScript "$HOME/bin/yazi-desktop.js" >/dev/null 2>&1
