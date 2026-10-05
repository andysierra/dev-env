#!/bin/bash
# Atajos globales de MATE (Linux Mint) — idempotente, se puede correr varias veces.
# Los atajos personalizados viven en dconf: /org/mate/desktop/keybindings/customN/
# Ver resultado: dconf dump /org/mate/desktop/keybindings/

set -e

# Alt+Space viene ocupado por Marco ("menú de ventana"): liberarlo para rofi
gsettings set org.mate.Marco.window-keybindings activate-window-menu 'disabled'

bind() {  # bind <slot> <nombre> <comando> <tecla>
    local p="/org/mate/desktop/keybindings/$1"
    dconf write "$p/name"    "'$2'"
    dconf write "$p/action"  "'$3'"
    dconf write "$p/binding" "'$4'"
}

bind custom0 'rofi lanzador (Alt+Space)' 'rofi -show drun' '<Alt>space'
bind custom1 'rofi lanzador (Alt+F3)'    'rofi -show drun' '<Alt>F3'
# Ruta absoluta: la sesión de MATE puede no tener ~/.local/bin en el PATH
bind custom2 'Historial de clipboard (greenclip + rofi) Alt+V' "$HOME/.local/bin/clipboard.sh" '<Alt>v'

dconf dump /org/mate/desktop/keybindings/
