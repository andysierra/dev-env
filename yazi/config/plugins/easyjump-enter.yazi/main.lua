--- @since 25.12.29
--- Envoltorio de easyjump: salta con la etiqueta y, si el destino es una
--- carpeta, entra en ella. Si es un archivo, no hace nada (solo deja el cursor).
--- Si se cancela con <Esc>, no entra en nada.
---
--- Como sabe si salto o cancelo: easyjump emite el comando "arrow" SOLO cuando
--- el salto se confirma. Se intercepta ya.emit durante la llamada para
--- detectarlo. Esto funciona tambien cuando se salta a la entrada donde ya
--- estaba el cursor (arrow con delta 0), caso que una comparacion de posicion
--- antes/despues no puede distinguir de una cancelacion.

---@return boolean is_dir
local hovered_is_dir = ya.sync(function()
  local h = cx.active.current.hovered
  return h ~= nil and h.cha.is_dir
end)

return {
  entry = function()
    local jumped = false
    local original_emit = ya.emit

    ya.emit = function(cmd, args)
      if cmd == "arrow" then
        jumped = true
      end
      return original_emit(cmd, args)
    end

    local ok, err = pcall(function()
      require("easyjump"):entry({})
    end)

    ya.emit = original_emit

    if not ok then
      ya.notify({
        title = "easyjump-enter",
        content = tostring(err),
        timeout = 5,
        level = "error",
      })
      return
    end

    if not jumped then
      return
    end

    -- el salto se emite como comando "arrow": darle un instante al event loop
    -- para que se aplique antes de leer que hay bajo el cursor.
    pcall(ya.sleep, 0.05)

    if hovered_is_dir() then
      ya.emit("enter", {})
    end
  end,
}
