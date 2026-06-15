# CachyOS + labwc — Entorno de desarrollo minimalista

## Para el humano

Wayland minimalista para desarrollo backend/frontend/mobile. Sin DE, sin daemons innecesarios.
Hardware original: HP laptop (`eDP-1` 1366×768, pantalla dañada arriba) + LG Ultragear (`HDMI-A-1` 1920×1080).

Los nombres de salida de video (`HDMI-A-1`, `eDP-1`) y la posición del monitor (`277,1080`) son específicos de este hardware — ajustar en `autostart` y `rc.xml` según el sistema destino.

### Atajos

| Atajo | Acción |
|---|---|
| `Super+Enter` | Terminal (foot) |
| `Super+C` | Claude Code (foot fullscreen, lanza claude automáticamente) |
| `Super+E` | Explorador de archivos (yazi, maximizado) |
| `Super+Space` / `Alt+F3` | Lanzador de apps |
| `Super+V` | Historial de clipboard |
| `Super+Shift+S` | Captura de área |
| `Super+M` | Reposicionar monitores (dual) |
| `Alt+Tab` / `Alt+Shift+Tab` | Ciclar ventanas |
| `Alt+F4` / `Alt+Q` | Cerrar ventana |
| `Fn+Brillo↑↓` | Brillo |
| `Fn+Vol↑↓` / `Fn+Mute` | Volumen |

### Para replicar en sistema nuevo
Compartí este archivo con Claude Code y pedile: *"implementa la sección IA de esta bitácora en este sistema"*.

---

## Para la IA — Implementación completa

### Contexto del setup
- Compositor Wayland: **labwc** (sin DE)
- Terminal: **foot**
- Shell: **fish**
- Explorador de archivos: **yazi**
- Lanzador: **bemenu** + **j4-dmenu-desktop**
- Clipboard: **cliphist** + **wtype**
- Captura: **grim** + **slurp** + **swappy**
- Monitores: **wlr-randr**
- Brillo: **brightnessctl**
- Volumen: **wpctl** (PipeWire, ya incluido)
- Cierre de tapa: **acpid**

### Paquetes

```sh
sudo pacman -S --noconfirm labwc foot fish yazi 7zip \
  bemenu-wayland j4-dmenu-desktop \
  wl-clipboard cliphist wtype \
  grim slurp swappy otf-font-awesome \
  wlr-randr brightnessctl acpid
```

Fuente del terminal (Iosevka Term):
```sh
# Descargar IosevkaTerm de https://github.com/be5invis/Iosevka/releases
# Descomprimir en ~/.local/share/fonts/iosevka/ y correr:
fc-cache -fv
```

### Arranque de labwc desde fish

`~/.config/fish/config.fish` — la línea `source` es específica de CachyOS, eliminarla o adaptarla en otras distros:

```fish
source /usr/share/cachyos-fish-config/cachyos-config.fish  # solo CachyOS

if status is-login; and test -z "$WAYLAND_DISPLAY"; and test "$XDG_VTNR" = 1
    exec dbus-run-session labwc
end
export PATH="$HOME/.local/bin:$PATH"
set -gx EDITOR vim

# aliases
alias c="NO_COLOR=1 TERM=dumb claude"
alias tf="terraform"
alias l="ls -lat"
alias helloworld="echo 'me gusta la pepitoria'"

# git aliases
alias gfp="git fetch -a --prune && git pull --all && git status"
alias gb="git branch -la"
alias gl="git log --oneline"
alias gdiff="git diff release develop && git diff stage release"
alias gdiffm="git diff release develop && git diff stage release && git diff main stage"
alias gup="git switch develop && git fetch -a --prune && git pull --all && git status && git switch release && git fetch -a --prune && git pull --all && git status && git switch stage && git fetch -a --prune && git pull --all && git status && git switch main && git fetch -a --prune && git pull --all && git status"

function gcp
    git add .
    git commit -m "$argv[1]"
    git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
    if test $status -ne 0
        set branch (git symbolic-ref --short HEAD)
        echo "No upstream branch detected. Setting upstream to origin/$branch"
        git push --set-upstream origin "$branch"
    else
        git push
    end
end

function gch
    git checkout -b $argv[1]
end

function go
    cd $argv[1] && ls -la
end

function y
    set tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file=$tmp
    if set cwd (cat -- $tmp 2>/dev/null); and test -n "$cwd"; and test "$cwd" != "$PWD"
        cd -- $cwd
    end
    rm -f -- $tmp
end
```

### ~/.local/bin/f

`f` abre una nueva ventana foot desde cualquier contexto — terminal, yazi (`:shell`), etc. Debe ser un script ejecutable en PATH, no una función fish, porque las funciones fish no están disponibles fuera de sesiones interactivas de fish.

```bash
#!/bin/bash
foot &
```

```sh
chmod +x ~/.local/bin/f
```

### ~/.config/fish/completions/go.fish

El autocompletado de `go` debe vivir en su propio archivo — fish no aplica `complete` definido en `config.fish` a tiempo. Este archivo le dice a fish que use las mismas completions que `cd`:

```fish
complete -c go --wraps cd
```

### ~/.config/labwc/environment

```
XKB_DEFAULT_LAYOUT=latam
GDK_DPI_SCALE=0.8
QT_SCALE_FACTOR=0.8
EDITOR=vim
```

### ~/.config/labwc/autostart

Los nombres de salida (`HDMI-A-1`, `eDP-1`) y la posición (`277,1080`) son específicos del hardware. Detectar outputs disponibles con `wlr-randr` y ajustar.

```sh
LID_STATE=$(cat /proc/acpi/button/lid/LID0/state 2>/dev/null || cat /proc/acpi/button/lid/LID/state 2>/dev/null)
if echo "$LID_STATE" | grep -q "closed"; then
    wlr-randr --output HDMI-A-1 --pos 0,0 --output eDP-1 --off
else
    wlr-randr --output HDMI-A-1 --pos 0,0 --output eDP-1 --pos 277,1080
fi &

wl-paste --watch cliphist store &

foot --config ~/.config/foot/claude-code.ini --app-id claude-code --title Claude-Code -e claude --dangerously-skip-permissions &
```

### ~/.config/labwc/rc.xml

labwc **no expande** `$HOME` ni `~` en `command`. Siempre usar `sh -c '~/.config/...'` para scripts con rutas. La acción de fullscreen es `ToggleFullscreen` (no `Fullscreen`).

```xml
<?xml version="1.0"?>
<labwc_config>
  <core>
    <gap>0</gap>
    <decoration>server</decoration>
  </core>

  <windowSwitcher preview="yes" outlines="yes" order="focus">
    <osd show="yes" style="thumbnail" />
  </windowSwitcher>

  <theme>
    <dropShadows>no</dropShadows>
    <font place="ActiveWindow"><name>Sans</name><size>9</size></font>
    <font place="InactiveWindow"><name>Sans</name><size>9</size></font>
  </theme>

  <windowRules>
    <windowRule identifier="claude-code">
      <action name="ToggleFullscreen" />
    </windowRule>
    <windowRule identifier="yazi">
      <action name="ToggleMaximize" />
    </windowRule>
  </windowRules>

  <keyboard>
    <default />
    <keybind key="W-Return"><action name="Execute" command="foot" /></keybind>
    <keybind key="W-c"><action name="Execute" command="sh -c 'foot --config ~/.config/foot/claude-code.ini --app-id claude-code --title Claude-Code -e claude --dangerously-skip-permissions'" /></keybind>
    <keybind key="W-e"><action name="Execute" command="sh -c '~/.config/labwc/scripts/yazi_cd.sh'" /></keybind>
    <keybind key="A-F4"><action name="Close" /></keybind>
    <keybind key="A-q"><action name="Close" /></keybind>
    <keybind key="W-m"><action name="Execute" command="wlr-randr --output HDMI-A-1 --pos 0,0 --output eDP-1 --pos 277,1080" /></keybind>
    <keybind key="A-Tab"><action name="NextWindow" /></keybind>
    <keybind key="A-S-Tab"><action name="PreviousWindow" /></keybind>
    <keybind key="A-F3"><action name="Execute" command="sh -c '~/.config/labwc/scripts/launcher_chromium_apps.sh'" /></keybind>
    <keybind key="W-space"><action name="Execute" command="sh -c '~/.config/labwc/scripts/launcher_chromium_apps.sh'" /></keybind>
    <keybind key="W-v"><action name="Execute" command="sh -c '~/.config/labwc/scripts/clipboard.sh'" /></keybind>
    <keybind key="W-S-s"><action name="Execute" command="sh -c '~/.config/labwc/scripts/screenshot.sh'" /></keybind>
    <keybind key="XF86MonBrightnessUp"><action name="Execute" command="brightnessctl set 10%+" /></keybind>
    <keybind key="XF86MonBrightnessDown"><action name="Execute" command="brightnessctl set 10%-" /></keybind>
    <keybind key="XF86AudioRaiseVolume"><action name="Execute" command="wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+" /></keybind>
    <keybind key="XF86AudioLowerVolume"><action name="Execute" command="wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-" /></keybind>
    <keybind key="XF86AudioMute"><action name="Execute" command="wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" /></keybind>
  </keyboard>
</labwc_config>
```

### ~/.config/labwc/themerc-override

```
window.button.height: 18
window.button.width: 18
window.titlebar.padding.height: 2
border.width: 2
window.active.border.color: #aaaaaa
window.inactive.border.color: #444444
window.active.title.bg.color: #aaaaaa
window.inactive.title.bg.color: #2a2a2a
window.active.label.text.color: #000000
window.inactive.label.text.color: #888888
```

### ~/.config/labwc/scripts/clipboard.sh

Texto de una línea: auto-pega con wtype. Multilínea: auto-pega con `Shift+Enter` entre líneas (evita enviar formularios en Claude/ChatGPT). Imágenes: solo clipboard, pegar con `Ctrl+V`.

```bash
#!/bin/bash
entry=$(cliphist list | bemenu -b)
[ -z "$entry" ] && exit

if echo "$entry" | grep -q "\[\[ binary"; then
    echo "$entry" | cliphist decode | wl-copy
else
    text=$(echo "$entry" | cliphist decode)
    echo -n "$text" | wl-copy
    sleep 0.1
    if [ "$(printf '%s' "$text" | wc -l)" -eq 0 ]; then
        wtype -- "$text"
    else
        mapfile -t lines <<< "$text"
        first=true
        for line in "${lines[@]}"; do
            if $first; then
                first=false
            else
                wtype -M shift -k return -m shift
            fi
            wtype -- "$line"
        done
    fi
fi
```

### ~/.config/labwc/scripts/launcher_chromium_apps.sh

```bash
#!/bin/bash
export XDG_DATA_HOME="$HOME/.local/share"
j4-dmenu-desktop --dmenu="bemenu -b -i"
```

### ~/.config/labwc/scripts/screenshot.sh

```bash
#!/bin/bash
grim -g "$(slurp)" - | swappy -f -
```

### ~/.config/labwc/scripts/yazi_cd.sh

```bash
#!/bin/bash
exec foot --app-id yazi fish -c "y ~"
```

### ~/.config/labwc/scripts/yazi_edit.sh

```bash
#!/bin/bash
/usr/bin/vim -- "$@"
```

Hacer ejecutables todos los scripts:
```sh
chmod +x ~/.config/labwc/scripts/*.sh
```

### ~/.config/foot/foot.ini

```ini
[main]
font=Iosevka Term:size=12
initial-window-size-pixels=960x1080
```

### ~/.config/foot/claude-code.ini

```ini
[main]
font=Iosevka Term:size=12
initial-window-size-pixels=960x1080

[colors-dark]
background=0d0010
foreground=ffffff
```

### ~/.config/yazi/yazi.toml

```toml
[manager]
show_hidden = true
```

### ~/.config/yazi/init.lua

`show_hidden = true` en yazi.toml no tiene efecto en yazi 26.x — este workaround lo activa al arrancar:

```lua
ya.emit("hidden", { "toggle" })
```

### ~/.local/share/applications/claude-code.desktop

```ini
[Desktop Entry]
Name=Claude Code
Exec=foot --app-id claude-code --title "Claude Code"
Icon=claude-code
Type=Application
```

### ~/.local/share/icons/hicolor/scalable/apps/claude-code.svg

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="50" fill="#D4622A"/>
  <text x="50" y="62" font-family="Sans" font-size="36" font-weight="bold" fill="white" text-anchor="middle">CC</text>
</svg>
```

### /etc/acpi/ — cierre de tapa (requiere sudo)

Evitar suspensión al cerrar tapa — editar `/etc/systemd/logind.conf`:
```
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
```
Luego: `sudo systemctl restart systemd-logind`

Habilitar acpid: `sudo systemctl enable --now acpid`

**`/etc/acpi/events/lid`:**
```
event=button/lid.*
action=/etc/acpi/actions/lid.sh %e
```

**`/etc/acpi/actions/lid.sh`** — ajustar nombres de output y usuario:
```bash
#!/bin/bash
USER=$(whoami)
WAYLAND_DISPLAY=wayland-0
LID_STATE=$(cat /proc/acpi/button/lid/LID0/state 2>/dev/null || cat /proc/acpi/button/lid/LID/state 2>/dev/null)
if echo "$LID_STATE" | grep -q "closed"; then
    runuser -l $USER -c "WAYLAND_DISPLAY=$WAYLAND_DISPLAY wlr-randr --output HDMI-A-1 --off"
else
    runuser -l $USER -c "WAYLAND_DISPLAY=$WAYLAND_DISPLAY wlr-randr --output HDMI-A-1 --pos 0,0 --output eDP-1 --pos 277,1080"
fi
```
```sh
sudo chmod +x /etc/acpi/actions/lid.sh
sudo systemctl restart acpid
```

### Chromium — escala

`~/.config/chromium-flags.conf`:
```
--force-device-scale-factor=0.8
```

### Bluetooth — emparejar dispositivo (solo una vez)

```sh
bluetoothctl
scan on
pair <MAC>
trust <MAC>
connect <MAC>
exit
```

### Limitaciones conocidas

- **yazi `prepend_keymap`**: completamente no funcional en yazi 26.x. Ningún binding personalizado dispara, incluso `run = "quit"`. No crear `keymap.toml`.
- **labwc windowRules**: no soporta `opacity` ni `inactiveOpacity`. No soporta `background.color` en themerc-override.
- **Firefox/Chromium CSD**: el compositor no puede agregar borde ni sombra — usan Client Side Decorations.
- **Clipboard imágenes**: Wayland no permite auto-paste de datos binarios con wtype. Solo `Ctrl+V`.
- **Wallpaper sin daemon**: labwc no tiene soporte nativo de wallpaper. Requiere `swaybg` u otro daemon. Se dejó el fondo negro por defecto.
- **`show_hidden` en yazi.toml**: ignorado en 26.x, workaround via `init.lua`.
