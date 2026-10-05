#!/bin/bash
# mate-terminal (perfil "Default"): fuente Nerd + paleta tokyo-night (combina con el flavor de yazi).
# Idempotente. Requiere la fuente IosevkaTerm Nerd Font (la instala install-yazi.sh).
# Sin Nerd Font, yazi muestra rectángulos/símbolos raros en lugar de íconos.

P=/org/mate/terminal/profiles/default

dconf write $P/use-system-font false
dconf write $P/font "'IosevkaTerm Nerd Font Mono 12'"

# tokyo-night (colores de folke/tokyonight.nvim, variante "night")
dconf write $P/use-theme-colors false
dconf write $P/background-color "'#1a1b26'"
dconf write $P/foreground-color "'#c0caf5'"
dconf write $P/bold-color-same-as-fg true
dconf write $P/palette "'#15161e:#f7768e:#9ece6a:#e0af68:#7aa2f7:#bb9af7:#7dcfff:#a9b1d6:#414868:#f7768e:#9ece6a:#e0af68:#7aa2f7:#bb9af7:#7dcfff:#c0caf5'"

# Cerrar ventana/pestaña sin preguntar aunque haya un proceso corriendo (lo mata)
gsettings set org.mate.terminal.global confirm-window-close false

dconf dump $P/
