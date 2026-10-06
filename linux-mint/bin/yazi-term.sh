#!/bin/bash
# Alt+E: ventana nueva de WezTerm, maximizada, con yazi en ~/Escritorio.
# Siempre ventana nueva (mismo criterio que el Mac desde 2026-10-01).
# --always-new-process: proceso propio → corre el evento gui-startup de wezterm.lua, que maximiza
#   las ventanas cuyo comando es "yazi". yazi va directo (sin shell detrás): al salir con q se cierra.
# wezterm (/usr/bin) y yazi (/usr/local/bin) están en el PATH de la sesión de MATE.
exec wezterm start --always-new-process --cwd "$HOME/Escritorio" -- yazi "$HOME/Escritorio"
