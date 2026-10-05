#!/bin/bash
# Oculta de rofi (y del menú) los ~250 salvapantallas de xscreensaver: "Braid", "Polyominoes", etc.
# Viven en /usr/share/applications/screensavers/ (paquetes xscreensaver-data*/gl*, que mate-screensaver
# arrastra) y rofi escanea subcarpetas. rofi no tiene "excluir categoría" (drun-categories es lista blanca),
# así que se tapa cada uno con un .desktop NoDisplay=true en la misma ruta relativa de ~/.local/share
# (mismo desktop-file-id → gana el del usuario). Sin sudo; idempotente: correr de nuevo si apt agrega más.
# Revertir: rm -r ~/.local/share/applications/screensavers

SRC=/usr/share/applications/screensavers
DST="$HOME/.local/share/applications/screensavers"
mkdir -p "$DST"
n=0
for f in "$SRC"/*.desktop; do
    name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
    printf '[Desktop Entry]\nType=Application\nName=%s\nNoDisplay=true\n' "$name" > "$DST/$(basename "$f")"
    n=$((n + 1))
done
echo "$n salvapantallas ocultos en $DST"
