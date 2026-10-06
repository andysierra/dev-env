#!/bin/bash
# Shift+Super+←/→: mueve la ventana activa al escritorio anterior/siguiente (sin seguirla, igual que
# Super+Shift+1/2). Uso: move-window-ws.sh -1 | +1
# Las acciones move-to-workspace-left/right de Marco no responden en este setup (ni con su tecla de
# fábrica Ctrl+Shift+Alt+←/→), así que se hace con wmctrl. En el primer/último escritorio no hace nada.
step=${1:?uso: $0 -1|+1}
n=$(wmctrl -d | wc -l)
id=$(xdotool getactivewindow) || exit 0
cur=$(wmctrl -l | awk -v w="$(printf '0x%08x' "$id")" '$1==w{print $2}')
[[ -z "$cur" || "$cur" == -1 ]] && exit 0          # sin ventana o ventana "en todos los escritorios"
dst=$((cur + step))
(( dst < 0 || dst >= n )) && exit 0
wmctrl -i -r "$id" -t "$dst"
