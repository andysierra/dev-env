-- WezTerm — terminal por defecto en Linux Mint (reemplaza mate-terminal).
-- Elegida por ser la más cercana a iTerm2 (tabs, splits, búsqueda, copy mode) y porque muestra
-- imágenes (protocolos iTerm2 y kitty): yazi previsualiza PNG/JPG, cosa que mate-terminal (VTE) no puede.
-- Destino: ~/.config/wezterm/wezterm.lua (se recarga sola al guardar).

local wezterm = require 'wezterm'
local mux = wezterm.mux
local config = wezterm.config_builder()

-- Misma apariencia que tenía mate-terminal: IosevkaTerm Nerd Font 12 + tokyo-night (= flavor de yazi)
config.font = wezterm.font 'IosevkaTerm Nerd Font Mono'
config.font_size = 12
config.color_scheme = 'Tokyo Night'

-- Cerrar sin preguntar aunque haya un proceso corriendo (como confirm-window-close=false en mate-terminal)
config.window_close_confirmation = 'NeverPrompt'

config.scrollback_lines = 100000
config.hide_tab_bar_if_only_one_tab = true
config.audible_bell = 'Disabled'
config.check_for_updates = false  -- se actualiza por apt (repo oficial de WezTerm)
config.window_padding = { left = 4, right = 4, top = 2, bottom = 2 }

-- Alt+E lanza `wezterm start --always-new-process -- yazi ...` (bin/yazi-term.sh): esa ventana sale
-- maximizada. Con --always-new-process cada Alt+E es un proceso nuevo y este evento siempre corre.
wezterm.on('gui-startup', function(cmd)
  local _, _, window = mux.spawn_window(cmd or {})
  if cmd and cmd.args and cmd.args[1] == 'yazi' then
    window:gui_window():maximize()
  end
end)

return config
