#!/bin/zsh
# Abre una ventana NUEVA de iTerm con el shell en un directorio, sin bloquear
# a quien lo llama. Usado desde yazi (tecla T) para "abrir terminal aqui".
#
# Uso: iterm-here.sh [dir-o-archivo]    (por defecto: $PWD)
# iTerm2 esta registrado como handler de carpetas, asi que `open -a iTerm <dir>`
# abre ventana nueva con cwd en <dir>: no hace falta AppleScript ni permisos.

dir="${1:-$PWD}"
[[ -d "$dir" ]] || dir="${dir:h}"   # si es un archivo, usar su carpeta

exec /usr/bin/open -a iTerm "$dir"
