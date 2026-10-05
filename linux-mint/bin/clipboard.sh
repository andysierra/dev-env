#!/bin/bash
# Alt+V: historial de clipboard (greenclip) en rofi, con auto-pegado (xdotool).
# Texto de una línea: lo escribe. Multilínea: Shift+Enter entre líneas (no envía
# formularios en Claude/ChatGPT). Imágenes: miniatura en la lista, se pegan con Ctrl+V.
# greenclip lista los saltos de línea como U+00A0 (nbsp); acá se revierten.
# Ruta absoluta: la sesión de MATE no tiene ~/.local/bin en el PATH.
GREENCLIP="$HOME/.local/bin/greenclip"
IMG_CACHE="$HOME/.cache/greenclip-img"   # = image_cache_directory de ~/.config/greenclip.toml

# -matching normal: en el historial sí se busca en medio del texto (el lanzador usa prefix).
# Las entradas "image/png ... <id>" llevan su PNG cacheado como ícono de rofi (\0icon\x1f<ruta>)
sel=$("$GREENCLIP" print \
    | sed -E "s|^(image/.* ([0-9]+))$|\1\x00icon\x1f$IMG_CACHE/\2.png|" \
    | rofi -dmenu -i -matching normal -p clipboard -show-icons -theme-str 'element-icon { size: 3em; }')
[ -z "$sel" ] && exit

"$GREENCLIP" print "$sel"                  # deja la entrada en el clipboard
command -v xdotool >/dev/null || exit      # sin xdotool: pegar a mano con Ctrl+V
sleep 0.1

if [[ "$sel" == image/* ]]; then
    xdotool key --clearmodifiers ctrl+v
    exit
fi

mapfile -t lines <<< "${sel//$'\xc2\xa0'/$'\n'}"
first=true
for line in "${lines[@]}"; do
    if $first; then
        first=false
    else
        xdotool key --clearmodifiers shift+Return
    fi
    xdotool type --clearmodifiers --delay 0 -- "$line"
done
