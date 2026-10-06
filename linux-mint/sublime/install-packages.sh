#!/bin/bash
# Instala los paquetes de Sublime que usa la config (sin depender de que Package Control arranque):
#   gruvbox  → color_scheme "gruvbox (Dark) (Hard)"
#   Terminus → terminal integrada (alt+3 en el keymap)
# Baja el tag de GitHub, lo reempaqueta como .sublime-package (zip sin la carpeta raíz que agrega
# GitHub) y lo deja en "Installed Packages". Sublime los carga en caliente, sin reiniciar.
# Para actualizar: subir el tag y correr de nuevo.
set -euo pipefail

I="$HOME/.config/sublime-text/Installed Packages"
mkdir -p "$I"
T=$(mktemp -d); trap 'cd /; rm -rf "$T"' EXIT

pkg() {  # pkg <owner/repo> <tag> <nombre del paquete>
    cd "$T" && rm -rf x && mkdir x
    curl -fsSL -o src.zip "https://github.com/$1/archive/refs/tags/$2.zip"
    unzip -q src.zip -d x
    (cd x/*/ && zip -qr "$T/$3.sublime-package" .)
    cp "$T/$3.sublime-package" "$I/"
    echo "$3 $2 instalado"
}

pkg Briles/gruvbox   4.0.1   gruvbox
pkg randy3k/Terminus v0.3.37 Terminus
