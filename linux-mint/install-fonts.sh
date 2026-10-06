#!/bin/bash
# Fuentes del repo + Fira Code, en ~/.local/share/fonts (sin sudo). Idempotente.
#   Comic Code   → ../fonts/*.otf
#   Fira Code    → release oficial de GitHub (el repo solo guarda css/README; Zed la usa: buffer_font_family)
#   Ubuntu Mono  → NO: Mint ya la trae (versión variable); instalar los TTF del repo la duplicaría
#   Iosevka Term Nerd Font → la instala install-yazi.sh (a nivel sistema)
set -euo pipefail
cd "$(dirname "$0")"
F="$HOME/.local/share/fonts"

mkdir -p "$F/comic-code"
cp ../fonts/Comic\ Code*.otf "$F/comic-code/"

mkdir -p "$F/fira-code"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
curl -fsSL -o "$T/fira.zip" "https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip"
unzip -qo "$T/fira.zip" 'ttf/*' 'variable_ttf/*' -d "$T"
cp "$T"/ttf/*.ttf "$T"/variable_ttf/*.ttf "$F/fira-code/"

fc-cache -f "$F"
fc-list : family | grep -E '^(Comic Code|Fira Code)' | sort -u
