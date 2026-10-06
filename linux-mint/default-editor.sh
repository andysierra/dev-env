#!/bin/bash
# Sublime Text como editor de texto por defecto (en vez de xed, el que trae Mint). Idempotente.
# xed solo declara text/plain; los demás tipos de texto (text/x-python, etc.) lo heredaban por ser
# subtipos. Se fija text/plain y, explícitos, formatos de desarrollo que no tenían app o tenían otra
# (application/xml lo tomaba Brave). HTML/CSV no se tocan (navegador / FreeOffice).
# Queda en ~/.config/mimeapps.list. Verificar: xdg-mime query default text/x-python

APP=sublime_text.desktop
TYPES=(
    text/plain text/markdown text/x-log
    text/x-python text/x-python3 text/x-java text/x-c text/x-c++ text/x-csrc text/x-chdr text/x-go text/rust
    text/x-shellscript application/x-shellscript text/x-script.python
    application/json application/x-yaml text/x-yaml application/toml text/x-toml
    application/xml text/xml application/javascript text/javascript text/css text/x-sql
    application/x-desktop text/x-makefile text/x-cmake text/x-gradle application/x-wine-extension-ini
)
xdg-mime default "$APP" "${TYPES[@]}"
for t in text/plain text/x-python application/json text/markdown application/xml; do
    printf '  %-20s → %s\n' "$t" "$(xdg-mime query default "$t")"
done
