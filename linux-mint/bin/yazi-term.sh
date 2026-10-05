#!/bin/bash
# Alt+E: ventana nueva de mate-terminal, maximizada, con yazi en ~/Escritorio.
# Siempre ventana nueva (mismo criterio que el Mac desde 2026-10-01).
# yazi se ejecuta directo (sin shell detrás): al salir con q, la ventana se cierra.
# yazi está en /usr/local/bin (install-yazi.sh), que sí está en el PATH de la sesión de MATE.
exec mate-terminal --window --maximize --title=yazi \
    --working-directory="$HOME/Escritorio" -e "yazi \"$HOME/Escritorio\""
