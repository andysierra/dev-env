# CachyOS + labwc — Alt como "Cmd" para Copiar/Pegar/Screenshot (estilo macOS)

Extra **opcional** de `linux/bitacora.md`: hace que `Alt+C` / `Alt+V` copien/peguen
(como `Cmd+C`/`Cmd+V` en macOS) y `Alt+Shift+S` dispare un screenshot de área
(como `Cmd+Shift+S`), en **todas las apps**, sin tocar `Ctrl+C`/`Ctrl+V` que
sigue funcionando igual.

## Para el humano

```text
Alt+C          copiar (equivale a Ctrl+C, funciona en cualquier app)
Alt+V          pegar  (equivale a Ctrl+V, funciona en cualquier app)
Alt+Shift+S    captura de área (mismo screenshot.sh de Super+Shift+S)
```

Los atajos con Super (`Super+V` historial de clipboard, `Super+Shift+S` captura)
siguen intactos: esto es un alias adicional, no un reemplazo.

**Aviso:** en bash/readline, `Alt+C` normalmente significa "capitalize word".
Con esto instalado, `Alt+C` en una terminal copia (sin selección, no hace nada
visible) en vez de capitalizar la palabra. Si usás ese atajo de readline
seguido, no instales esto o sacá la línea `c = C-c` del `[alt]` de keyd.

### Para replicar en un sistema nuevo
Compartí este archivo con Claude Code y pedile: *"implementa la sección Para
la IA de este spec en este sistema"*.

---

## Para la IA — leé esto antes de tocar nada

Este spec es autocontenido: **no necesitás nada de la conversación en la que
se creó.** Asume que ya está aplicada la bitácora base `linux/bitacora.md`
(labwc + grim/slurp/swappy para el screenshot).

## Qué vas a dejar instalado

```text
1. Paquete keyd (AUR/repo, disponible en CachyOS como cachyos-extra-v3/keyd)
   servicio systemd habilitado y corriendo
2. /etc/keyd/default.conf     Alt+C -> Ctrl+C, Alt+V -> Ctrl+V (system-wide)
3. keybind Alt+Shift+S en ~/.config/labwc/rc.xml -> mismo screenshot.sh
   que ya usa Super+Shift+S
```

## Entorno donde se construyó y verificó

```text
fecha       2026-08-30
distro      CachyOS (Arch-based)
compositor  labwc (wlroots), sesion Wayland
keyd        2.6.0-5.1 (repo cachyos-extra-v3)
screenshot  grim + slurp + swappy (ya presentes por linux/bitacora.md)
```

## Por qué Alt y no otra tecla

```text
Alt y no Super   Super ya esta cargado de atajos propios (Super+C abre Zed,
                 Super+V clipboard, Super+1/2 escritorios, etc.) — usarlo de
                 "Cmd" hubiera chocado. Alt+C y Alt+V estaban libres.
keyd y no un     Copiar/pegar no es una accion del compositor: cada app
keybind de labwc decide que hacer con Ctrl+C internamente. labwc (o cualquier
                 WM) no puede "interceptar el concepto de copiar", solo puede
                 mandar teclas o ejecutar comandos. Por eso hace falta un
                 remapeador a nivel de input (evdev) que reescriba la tecla
                 ANTES de que la app la vea.
Alt+Shift+S SI   Un screenshot SI es una accion externa (correr un comando),
via labwc        eso labwc lo hace nativamente con <keybind>+Execute — no
                 hace falta que keyd la toque.
```

## Reglas duras (no las cambies sin decírselo al humano)

```text
1. NO metas Alt+Shift+S dentro de keyd. Eso es un Execute de labwc, no un
   remapeo de tecla.
2. El [alt] de keyd es un nombre de layer especial: keyd asocia leftalt/
   rightalt a esa layer automaticamente. NO hace falta "leftalt = layer(alt)"
   en [main]. Si se agrega igual, no rompe nada, pero es redundante.
3. Solo mapear `c` y `v` dentro de [alt]. Cualquier otra tecla con Alt que
   NO este listada en el archivo sigue llegando a la app como Alt+esa-tecla
   sin cambios (asi es como Alt+Tab, Alt+F4, Alt+Q, Alt+Space, Alt+F3, Alt+N
   siguen funcionando: ver linux/bitacora.md).
4. Antes de escribir /etc/keyd/default.conf: si el sistema destino ya tenia
   un archivo (por otro remap previo, ej. capslock->esc), NO lo pises entero:
   fusiona el bloque [alt] con lo existente.
```

## Camino rápido

```sh
# 1. Instalar keyd
sudo pacman -S --noconfirm keyd
sudo systemctl enable --now keyd

# 2. Configurar keyd (fusionar si /etc/keyd/default.conf ya existe)
sudo mkdir -p /etc/keyd
sudo cp <dir-de-este-spec>/keyd-cmd-copypaste/default.conf /etc/keyd/default.conf
sudo systemctl restart keyd

# 3. Agregar el keybind de screenshot en labwc (justo despues de W-S-s)
#    Editar ~/.config/labwc/rc.xml a mano, agregando dentro de <keyboard>:
#      <keybind key="A-S-s">
#        <action name="Execute" command="sh -c '~/.config/labwc/scripts/screenshot.sh'" />
#      </keybind>
labwc --reconfigure   # o killall -HUP labwc — rc.xml no se relee solo
```

Sin el repo a mano: el contenido de `/etc/keyd/default.conf` está íntegro en
el **Anexo A**.

## Verificación

```text
CASO                                  ESPERADO                    ESTADO
──────────────────────────────────  ──────────────────────────  ──────────
seleccionar texto, Alt+C, Alt+V     copia y pega el texto        verificado
Alt+Tab, Alt+F4, Alt+Q, Alt+Space   siguen funcionando igual     verificado
Alt+Shift+S                          abre slurp -> swappy         verificado
Super+Shift+S (el original)         sigue funcionando igual      verificado
Super+V (clipboard history)         sigue funcionando igual      verificado
systemctl is-active keyd            active                       verificado
```

Comandos utiles para una IA sin ojos (verificar sin interactuar a mano):

```sh
systemctl is-active keyd
sudo journalctl -eu keyd --no-pager | tail -30    # errores de parseo del conf
cat /etc/keyd/default.conf
grep -A2 'A-S-s' ~/.config/labwc/rc.xml
```

## Troubleshooting

```text
SÍNTOMA                          CAUSA / ARREGLO
────────────────────────────────  ─────────────────────────────────────────
Alt+C / Alt+V no hacen nada       keyd no esta activo: systemctl is-active
                                   keyd. Si esta activo, revisar journalctl
                                   -eu keyd por error de sintaxis en el conf
                                   (un config roto deja el teclado SIN
                                   ninguna modificacion de keyd, no crashea)
Alt+Tab / Alt+F4 dejaron de       algo mas se agrego dentro de [alt] sin
funcionar                         querer, o [main] tiene "leftalt = layer(...)"
                                   apuntando a otra layer. Revisar el archivo
                                   completo, no solo el bloque nuevo.
Alt+Shift+S no hace nada          rc.xml no se recargo: labwc --reconfigure
                                   (o killall -HUP labwc). Los cambios en
                                   rc.xml NUNCA aplican solos.
en bash, Alt+C ya no capitaliza   comportamiento esperado (ver aviso arriba):
la palabra                        se resigna leer/mayor de readline por el
                                   remap global. No hay forma de tener ambos
                                   sin acotar el remap a menos apps (fuera
                                   de alcance de este spec).
teclado "se traba" tras editar    panic sequence de keyd: mantener
default.conf mal                  Backspace+Escape+Enter para forzar a keyd
                                   a terminar, y corregir el archivo.
```

## Revertir

```sh
sudo systemctl disable --now keyd
sudo pacman -R keyd
# sacar el <keybind key="A-S-s">...</keybind> de ~/.config/labwc/rc.xml
labwc --reconfigure
```

## Archivos que toca esta implementación

```text
NUEVOS
/etc/keyd/default.conf                nuevo remap Alt+C / Alt+V (o bloque
                                       [alt] fusionado si el archivo ya existia)

MODIFICADO
~/.config/labwc/rc.xml                +1 <keybind key="A-S-s"> junto al
                                       W-S-s existente (screenshot.sh)

NO SE TOCA
~/.config/labwc/scripts/screenshot.sh se reutiliza tal cual (no se duplica)
Super+V, Super+Shift+S y el resto de linux/bitacora.md
```

---

# Anexo A — contenido íntegro de `/etc/keyd/default.conf`

Espejo de `keyd-cmd-copypaste/default.conf` al 2026-08-30. Si tenés el repo,
la fuente de verdad es ese archivo.

```ini
[ids]
*

[main]

[alt]
c = C-c
v = C-v
```
