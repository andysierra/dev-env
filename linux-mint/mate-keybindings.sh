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
bind custom3 'yazi en terminal maximizada (Alt+E)' "$HOME/.local/bin/yazi-term.sh" '<Alt>e'
bind custom4 'Terminal (Super+Enter)'     'mate-terminal'                          '<Mod4>Return'
bind custom5 'Zed en ~/Escritorio/DEV (Super+C)' "$HOME/.local/bin/zed $HOME/Escritorio/DEV" '<Mod4>c'
bind custom6 'Escribir ~ (Alt+N)'         "$HOME/.local/bin/type-tilde.sh"         '<Alt>n'
# Alt+Q = Alt+F4: Marco admite una sola tecla por acción → wmctrl cierra la ventana activa (cierre normal, no kill)
bind custom7 'Cerrar ventana (Alt+Q)'     'wmctrl -c :ACTIVE:'                     '<Alt>q'
# -s (--accept-on-select): la captura termina al soltar el mouse, sin Enter ni botón de copiar
bind custom8 'Captura de área al clipboard (Alt+Shift+S)' 'flameshot gui -c -s'          '<Alt><Shift>s'

M=org.mate.Marco

# --- Alt+Shift+4: captura de área a ~/Imágenes ---
# Va por Marco (run-command-N), no como customN: los atajos propios de mate-settings-daemon
# no se disparan con Shift+número (ni como "4" ni como "dollar"); Marco sí los toma.
gsettings set org.mate.Marco.keybinding-commands command-1 "$HOME/.local/bin/screenshot-save.sh"
gsettings set org.mate.Marco.global-keybindings  run-command-1 '<Alt><Shift>4'
# Alt+Shift+4 venía ocupado por la captura de pantalla completa de MATE (mate-screenshot)
gsettings set org.mate.Marco.global-keybindings  run-command-screenshot 'disabled'

# --- Escritorios virtuales: 2, como en la bitácora CachyOS ---
gsettings set $M.general num-workspaces 2
gsettings set $M.global-keybindings switch-to-workspace-1 '<Mod4>1'
gsettings set $M.global-keybindings switch-to-workspace-2 '<Mod4>2'
gsettings set $M.window-keybindings move-to-workspace-1  '<Mod4><Shift>1'
gsettings set $M.window-keybindings move-to-workspace-2  '<Mod4><Shift>2'

# --- Alt+Tab recorre las ventanas de TODOS los escritorios (por defecto solo el actual) ---
gsettings set $M.global-keybindings switch-windows              'disabled'
gsettings set $M.global-keybindings switch-windows-backward     'disabled'
gsettings set $M.global-keybindings switch-windows-all          '<Alt>Tab'
gsettings set $M.global-keybindings switch-windows-all-backward '<Shift><Alt>Tab'

dconf dump /org/mate/desktop/keybindings/
