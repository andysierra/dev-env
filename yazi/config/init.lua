-- easyjump.yazi — saltar a cualquier archivo visible con 1-2 teclas (estilo easymotion/hop)
require("easyjump"):setup({
  icon_fg = "#7dcfff",      -- color de la etiqueta
  first_key_fg = "#565f89", -- color del 1er caracter en etiquetas de 2 teclas
})

-- Titulo "yazi: <ultimo componente del path>" en la ventana/pestana del terminal
-- (yazi >= 26: title_format fue reemplazado por este evento). En "/" no hay nombre: queda "yazi: /".
ps.sub("ind-app-title", function(args)
  local cwd = cx.active.current.cwd
  args.value = "yazi: " .. tostring(cwd.name or cwd)
  return args
end)
