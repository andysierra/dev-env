#!/bin/bash
# Instala yazi + todas sus dependencias opcionales en Linux Mint 22.x, de una pasada.
# Uso:  sudo ./install-yazi.sh
#
# Binarios que no están (o están viejos) en apt van a /usr/local/bin, que la sesión
# de MATE sí tiene en el PATH (a diferencia de ~/.local/bin, ver bitacora.md).
# Se puede correr de nuevo para actualizar: siempre baja la última release.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Correr con sudo: sudo $0"; exit 1; }

BIN=/usr/local/bin
FONTS=/usr/local/share/fonts/iosevka-term-nerd
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

gh_latest() {  # gh_latest <owner/repo> <regex del asset> → URL de descarga
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
        | grep -oE "https://[^\"]*/download/[^\"]*/$2\"" | tr -d '"' | head -1
}

step() { echo; echo "==> $*"; }

# --- apt ---------------------------------------------------------------------
# fzf (0.44) e imagemagick (6.9) de apt no cumplen la versión mínima de yazi:
# fzf va por binario abajo; imagemagick se omite (solo fuentes/HEIC/JPEG XL).
step "Paquetes apt"
apt-get update -qq
apt-get install -y file unzip xz-utils curl \
    xclip ffmpeg jq fd-find ripgrep zoxide 7zip poppler-utils

# Debian/Ubuntu instala fd como "fdfind"
ln -sf /usr/bin/fdfind "$BIN/fd"

# --- yazi + ya ---------------------------------------------------------------
step "yazi"
curl -fsSL -o "$TMP/yazi.zip" "$(gh_latest sxyazi/yazi 'yazi-x86_64-unknown-linux-gnu\.zip')"
unzip -q "$TMP/yazi.zip" -d "$TMP/yazi"
install -m755 "$TMP"/yazi/*/yazi "$TMP"/yazi/*/ya "$BIN/"

# --- fzf (>= 0.53) -----------------------------------------------------------
step "fzf"
curl -fsSL "$(gh_latest junegunn/fzf 'fzf-[0-9.]+-linux_amd64\.tar\.gz')" | tar xz -C "$TMP"
install -m755 "$TMP/fzf" "$BIN/fzf"

# --- resvg (preview SVG) -----------------------------------------------------
step "resvg"
mkdir -p "$TMP/resvg"
curl -fsSL "$(gh_latest linebender/resvg 'resvg-linux-x86_64\.tar\.gz')" | tar xz -C "$TMP/resvg"
install -m755 "$(find "$TMP/resvg" -type f -name resvg | head -1)" "$BIN/resvg"

# --- Nerd Font: Iosevka Term -------------------------------------------------
step "Iosevka Term Nerd Font"
mkdir -p "$FONTS"
curl -fsSL "$(gh_latest ryanoasis/nerd-fonts 'IosevkaTerm\.tar\.xz')" | tar xJ -C "$FONTS"
chmod 644 "$FONTS"/*
fc-cache -f

# --- verificación ------------------------------------------------------------
step "Versiones instaladas"
for cv in yazi:--version ya:--version fzf:--version resvg:--version fd:--version \
          rg:--version zoxide:--version jq:--version ffmpeg:-version 7z:i \
          pdftoppm:-v xclip:-version file:--version; do
    c=${cv%%:*}
    if command -v "$c" >/dev/null; then
        printf "  %-9s %s\n" "$c" "$("$c" "${cv#*:}" 2>&1 | grep -m1 . || true)"
    else
        printf "  %-9s FALTA\n" "$c"
    fi
done
printf "  %-9s %s estilos\n" "nerdfont" "$(fc-list | grep -c 'IosevkaTerm Nerd')"
