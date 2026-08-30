# CachyOS + labwc — Entorno de desarrollo minimalista

## Para el humano

Wayland minimalista para desarrollo backend/frontend/mobile. Sin DE, sin daemons innecesarios.
Hardware original: HP laptop (`eDP-1` 1366×768, pantalla dañada arriba) + LG Ultragear (`HDMI-A-1` 1920×1080).

Los nombres de salida de video (`HDMI-A-1`, `eDP-1`) y la posición del monitor (`277,1080`) son específicos de este hardware — ajustar en `autostart` y `rc.xml` según el sistema destino.

### Atajos

| Atajo | Acción |
|---|---|
| `Super+Enter` | Terminal (foot) |
| `Super+C` | Zed abierto en `~/work` (Claude vive en su panel de agente) |
| `Super+Alt+E` | Explorador de archivos (yazi, maximizado) — instancia única: si ya hay una abierta, le da foco en vez de crear otra |
| `Alt+Space` / `Alt+F3` | Lanzador de apps (estilo Spotlight de macOS) — escribir `claudia` abre terminal con Claude sin restricciones; `word`/`excel`/`powerpoint` abren FreeOffice |
| `Alt+N` | Escribe el símbolo `~` (tilde) — atajo cómodo en reemplazo de AltGr+4 |
| `Super+V` | Historial de clipboard |
| `Super+Shift+S` | Captura de área |
| `Super+M` | Reposicionar monitores (dual) |
| `Super+1` / `Super+2` | Cambiar escritorio virtual |
| `Super+Shift+1` / `Super+Shift+2` | Mover ventana a escritorio |
| `Alt+Tab` / `Alt+Shift+Tab` | Ciclar ventanas (todos los escritorios) |
| `Alt+F4` / `Alt+Q` | Cerrar ventana |
| `Alt+C` / `Alt+V` *(opcional)* | Copiar / Pegar estilo macOS — requiere `keyd`, ver [`spec-keyd-cmd-copypaste.md`](spec-keyd-cmd-copypaste.md) |
| `Alt+Shift+S` *(opcional)* | Captura de área, alias de `Super+Shift+S` — mismo spec de arriba |
| `Fn+Brillo↑↓` | Brillo |
| `Fn+Vol↑↓` / `Fn+Mute` | Volumen |
| Botón encendido (toque corto) | Suspender |
| Botón encendido (mantener) | Apagar |

### Para replicar en sistema nuevo
Compartí este archivo con Claude Code y pedile: *"implementa la sección IA de esta bitácora en este sistema"*.

---

## Para la IA — Implementación completa

### Contexto del setup
- Compositor Wayland: **labwc** (sin DE)
- Terminal: **foot**
- Shell: **bash**
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
sudo pacman -S --noconfirm labwc foot bash yazi 7zip \
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

### Arranque de labwc desde bash

Bash usa dos archivos: `.bash_profile` para shells de login (TTY), `.bashrc` para shells interactivos (terminales). El `.bash_profile` llama al `.bashrc`.

Cambiar shell por defecto: `chsh -s /bin/bash`

**`~/.bash_profile`:**
```bash
[[ -f ~/.bashrc ]] && source ~/.bashrc

# Launch labwc on TTY1
if [[ -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" == "1" ]]; then
    exec dbus-run-session labwc
fi
```

**`~/.bashrc`:**
```bash
[[ $- != *i* ]] && return

export PATH="$HOME/.local/bin:$PATH"
export EDITOR=vim

# git-aware prompt (muestra la rama actual; bash no la trae por defecto como fish)
source /usr/share/git/completion/git-prompt.sh
GIT_PS1_SHOWDIRTYSTATE=1
PS1='\[\e[32m\]\w\[\e[33m\]$(__git_ps1 " (%s)")\[\e[0m\] \$ '

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# aliases
alias c="NO_COLOR=1 TERM=dumb claude"
alias claudia="claude --dangerously-skip-permissions"  # terminal lanzada desde bemenu (ver claudia.desktop)
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

gcp() {
    git add .
    git commit -m "$1"
    git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
    if [ $? -ne 0 ]; then
        branch=$(git symbolic-ref --short HEAD)
        echo "No upstream branch detected. Setting upstream to origin/$branch"
        git push --set-upstream origin "$branch"
    else
        git push
    fi
}

gch() {
    git checkout -b "$1"
}

go() {
    if [[ -n "$1" ]]; then
        cd "$1" && ls -la
    else
        ls -la
    fi
}

y() {
    local tmp
    tmp=$(mktemp -t yazi-cwd.XXXXXX)
    yazi "$@" --cwd-file="$tmp"
    local cwd
    cwd=$(cat -- "$tmp" 2>/dev/null)
    if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

complete -d go

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```

### ~/.local/bin/f

`f` abre una nueva ventana foot desde cualquier contexto — terminal, yazi (`:shell`), etc.

```bash
#!/bin/bash
foot &
```

```sh
chmod +x ~/.local/bin/f
```

### SDKMAN — gestión de JDKs y SDKs

Instalación (requiere `zip`): `sudo pacman -S --noconfirm zip`

```bash
curl -s "https://get.sdkman.io" | bash
```

El instalador agrega automáticamente su bloque al final de `.bashrc` (debe estar al final). Comandos principales:

```bash
sdk list java                  # ver versiones disponibles
sdk install java 21.0.7-tem   # instalar Java 21 (Temurin)
sdk install gradle             # instalar Gradle
sdk current java               # ver versión activa
sdk use java 17.x.x-tem       # cambiar versión en sesión actual
sdk default java 21.x.x-tem   # cambiar versión por defecto
```

### ~/.vimrc — yank de vim al clipboard del sistema

El vim de Arch viene compilado con `-clipboard` (sin soporte nativo). El registro `"` de vim queda aislado del portapapeles de Wayland. Este autocmd copia a `wl-copy` después de cada yank. `g:clipboard` (estilo Neovim) **no** funciona en este vim.

```vim
autocmd TextYankPost * call system('wl-copy', @")
```

- `@"` = registro donde vim deja lo copiado
- `wl-copy` = escribe en el clipboard de Wayland (paquete `wl-clipboard`)

### Zed — instalación e ícono personalizado

Instalación (script oficial, queda en `~/.local/zed.app/`):
```sh
curl -f https://zed.dev/install.sh | sh
```

El instalador crea `~/.local/share/applications/dev.zed.Zed.desktop`. El **app_id** real de la ventana es `dev.zed.Zed` (verificable con `strings ~/.local/zed.app/bin/zed | grep app_id`).

Para que labwc muestre un ícono propio, dos pasos:

1. **El ícono va en el tema de iconos, NO en `applications/`.** Copiar el SVG a:
   ```
   ~/.local/share/icons/hicolor/scalable/apps/zed.svg
   ```
2. **El `.desktop` referencia el ícono por NOMBRE, no por ruta absoluta.** labwc resuelve iconos vía el tema (libsfdo), no acepta bien rutas absolutas en `Icon=`:
   ```ini
   Icon=zed
   StartupWMClass=dev.zed.Zed
   ```

`StartupWMClass` debe igualar el app_id para que labwc asocie la ventana con el `.desktop`.

**Gotcha del caché de iconos:** `~/.local/share/icons/hicolor/icon-theme.cache` actúa como índice. Si quedó apuntando a un archivo viejo/borrado, labwc cae al ícono por defecto aunque el SVG correcto exista. Como no hay `index.theme` en ese dir, `gtk-update-icon-cache` falla y no lo regenera — la solución es **borrar el caché** para forzar escaneo en vivo, y reiniciar labwc:

```sh
rm -f ~/.local/share/icons/hicolor/icon-theme.cache
labwc --reconfigure
```

Mismo procedimiento aplica a cualquier app instalada fuera de pacman (IntelliJ, etc.): SVG en `hicolor/scalable/apps/`, `Icon=<nombre>` + `StartupWMClass=<app_id>` en el `.desktop`.

### Bruno — cliente de API (AppImage)

Cliente de API open-source y *offline-first* (colecciones como archivos planos, sin nube ni cuenta). Elegido sobre Insomnia: 158 MB vs 1.6 GB, más liviano en RAM.

**Requisito: libfuse2.** Los AppImage necesitan `libfuse.so.2`; CachyOS trae solo fuse3. Sin esto el AppImage falla en silencio (no abre desde el lanzador). fuse2 es solo una librería, **no un daemon** — se usa solo mientras el AppImage está montado.
```sh
sudo pacman -S --noconfirm fuse2
```

Instalación: dejar el AppImage en `~/.local/share/bruno/bruno.AppImage` y darle permiso:
```sh
chmod +x ~/.local/share/bruno/bruno.AppImage
```

Extraer el ícono del propio AppImage (trae `.desktop` + iconos hicolor dentro):
```sh
cd /tmp
~/.local/share/bruno/bruno.AppImage --appimage-extract 'usr/share/icons/*'
cp /tmp/squashfs-root/usr/share/icons/hicolor/512x512/apps/bruno.png \
   ~/.local/share/icons/hicolor/512x512/apps/bruno.png
rm -rf /tmp/squashfs-root ~/.local/share/icons/hicolor/icon-theme.cache
```

El `.desktop` interno del AppImage da los datos exactos (`StartupWMClass=Bruno`, requiere `--no-sandbox`).

**`~/.local/share/applications/bruno.desktop`:**
```ini
[Desktop Entry]
Name=Bruno
GenericName=API Client
Comment=Opensource API Client for Exploring and Testing APIs
Exec=/home/andysierra/.local/share/bruno/bruno.AppImage --no-sandbox %U
Icon=bruno
Type=Application
Terminal=false
Categories=Development;
MimeType=x-scheme-handler/bruno;
StartupWMClass=Bruno
StartupNotify=true
```

**Actualizar**: reemplazar `bruno.AppImage` por la versión nueva con el mismo nombre. Nada más que tocar.

### claudia — terminal Claude Code sin restricciones (bemenu)

Lanzador para abrir rápido una terminal ejecutando `claude --dangerously-skip-permissions` desde el buscador de apps (`Alt+Space`, escribir `claudia`). Usa el mismo patrón de `foot --app-id ... bash -i -c "..."` que `yazi_cd.sh`, para que `bash -i` cargue el `.bashrc` y resuelva el alias `claudia`.

**`~/.local/share/applications/claudia.desktop`:**
```ini
[Desktop Entry]
Name=claudia
GenericName=Claude Code (skip permissions)
Comment=Abre una terminal ejecutando claude --dangerously-skip-permissions
Exec=foot --app-id claudia bash -i -c "claudia; exec bash"
Icon=utilities-terminal
Type=Application
Terminal=false
Categories=Development;Utility;
StartupNotify=true
```

### FreeOffice 2024 — suite ofimática (Word/Excel/PowerPoint)

Instalado en `~/freeoffice2024` (binarios de lanzamiento: `~/textmaker24free`, `~/planmaker24free`, `~/presentations24free`).

**Dependencia faltante tras instalar:** PlanMaker fallaba con `error while loading shared libraries: libXmu.so.6: cannot open shared object file`.
```sh
sudo pacman -S --noconfirm libxmu
```

**Asociaciones de archivos por defecto**, cubriendo todos los MimeType que trae cada `.desktop` (doc/docx/odt → TextMaker, xls/xlsx/ods → PlanMaker, ppt/pptx/odp → Presentations):
```sh
xdg-mime default textmaker-free24.desktop application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document application/vnd.oasis.opendocument.text application/rtf # + resto de MimeType del .desktop
xdg-mime default planmaker-free24.desktop application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.oasis.opendocument.spreadsheet text/csv # + resto
xdg-mime default presentations-free24.desktop application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation application/vnd.oasis.opendocument.presentation # + resto
```
Verificar con `xdg-mime query default <mimetype>`.

**Nombres para bemenu**: los `.desktop` que trae el instalador se llaman "FreeOffice 2024 TextMaker/PlanMaker/Presentations" — no coinciden con lo que la gente realmente escribe en un lanzador. Se editó el campo `Name=` de cada uno (en `~/.local/share/applications/`) para que aparezcan al escribir "word", "excel" o "powerpoint":
```
textmaker-free24.desktop:     Name=Word (FreeOffice TextMaker)
planmaker-free24.desktop:     Name=Excel (FreeOffice PlanMaker)
presentations-free24.desktop: Name=PowerPoint (FreeOffice Presentations)
```

**Gotcha:** el `.desktop` de TextMaker traía una línea con un único espacio (inválida según el spec). `j4-dmenu-desktop` descarta el archivo completo en silencio ante esto (sin error visible) — por eso "word" no aparecía en bemenu mientras "excel"/"powerpoint" sí. Diagnosticado con `desktop-file-validate archivo.desktop`; se corrigió borrando la línea.

### ~/.config/labwc/environment

```
XKB_DEFAULT_LAYOUT=latam
GDK_DPI_SCALE=0.8
QT_FONT_DPI=77
EDITOR=vim
```

> **UI compacta en Qt — usar `QT_FONT_DPI`, NO `QT_SCALE_FACTOR`.**
> `QT_SCALE_FACTOR=0.8` (multiplicador bruto, escala fraccionaria) rompe apps Qt5
> viejas bajo XWayland: clipea texto de menús y colapsa barras (p.ej. VLC mostraba
> "Playba" sin barra de tiempo). Sustituido por `QT_FONT_DPI=77` (≈ 0.8×96), que
> encoge solo la fuente sin deformar los widgets — misma densidad, sin el bug.
> Para densidades distintas POR monitor, usar `wlr-randr --output X --scale N`
> (no una escala global). GTK sigue con `GDK_DPI_SCALE`; Chromium con
> `--force-device-scale-factor=0.8` (ambos toleran bien el 0.8).

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

# Zed abierto en ~/work. Claude se usa desde su panel de agente (claude-acp),
# que renderiza Mermaid, tablas y árboles — cosa que una terminal no puede hacer.
# Ruta absoluta: labwc no garantiza ~/.local/bin en PATH.
/home/andysierra/.local/zed.app/bin/zed /home/andysierra/work &
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
    <osd show="yes" style="classic" />
  </windowSwitcher>

  <theme>
    <dropShadows>no</dropShadows>
    <font place="ActiveWindow"><name>Sans</name><size>9</size></font>
    <font place="InactiveWindow"><name>Sans</name><size>9</size></font>
  </theme>

  <desktops>
    <names>
      <name>1</name>
      <name>2</name>
    </names>
    <popupTime>500</popupTime>
  </desktops>

  <windowRules>
    <windowRule identifier="yazi">
      <action name="ToggleMaximize" />
    </windowRule>
  </windowRules>

  <keyboard>
    <default />
    <keybind key="W-1"><action name="GoToDesktop" to="1" /></keybind>
    <keybind key="W-2"><action name="GoToDesktop" to="2" /></keybind>
    <keybind key="W-S-1"><action name="SendToDesktop" to="1" /></keybind>
    <keybind key="W-S-2"><action name="SendToDesktop" to="2" /></keybind>
    <keybind key="W-Return"><action name="Execute" command="foot" /></keybind>
    <keybind key="W-c"><action name="Execute" command="/home/andysierra/.local/zed.app/bin/zed /home/andysierra/work" /></keybind>
    <!-- ForEach + query + none = run-or-raise nativo: si ya hay ventana "yazi", enfoca; si no, la lanza -->
    <keybind key="W-A-e">
      <action name="ForEach">
        <query identifier="yazi" />
        <then>
          <action name="Focus" />
          <action name="Raise" />
        </then>
        <none>
          <action name="Execute" command="sh -c '~/.config/labwc/scripts/yazi_cd.sh'" />
        </none>
      </action>
    </keybind>
    <keybind key="A-F4"><action name="Close" /></keybind>
    <keybind key="A-q"><action name="Close" /></keybind>
    <keybind key="W-m"><action name="Execute" command="wlr-randr --output HDMI-A-1 --pos 0,0 --output eDP-1 --pos 277,1080" /></keybind>
    <keybind key="A-Tab"><action name="NextWindow" workspace="all" /></keybind>
    <keybind key="A-S-Tab"><action name="PreviousWindow" workspace="all" /></keybind>
    <keybind key="A-F3"><action name="Execute" command="sh -c '~/.config/labwc/scripts/launcher_chromium_apps.sh'" /></keybind>
    <keybind key="A-space"><action name="Execute" command="sh -c '~/.config/labwc/scripts/launcher_chromium_apps.sh'" /></keybind>
    <!-- Alt izquierdo puro: el layout latam ya usa Alt derecho (AltGr) como level3 para "~" -->
    <keybind key="A-n"><action name="Execute" command="sh -c '~/.config/labwc/scripts/type_tilde.sh'" /></keybind>
    <keybind key="W-v"><action name="Execute" command="sh -c '~/.config/labwc/scripts/clipboard.sh'" /></keybind>
    <keybind key="W-S-s"><action name="Execute" command="sh -c '~/.config/labwc/scripts/screenshot.sh'" /></keybind>
    <!-- opcional, ver linux/spec-keyd-cmd-copypaste.md -->
    <keybind key="A-S-s"><action name="Execute" command="sh -c '~/.config/labwc/scripts/screenshot.sh'" /></keybind>
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

Abre yazi en `~/work` en vez de `$HOME` — es donde vive casi todo el trabajo diario.

```bash
#!/bin/bash
exec foot --app-id yazi bash -i -c "y /home/andysierra/work; exec bash"
```

### ~/.config/labwc/scripts/yazi_edit.sh

```bash
#!/bin/bash
/usr/bin/vim -- "$@"
```

### ~/.config/labwc/scripts/type_tilde.sh

labwc expande literalmente cualquier `~` dentro del atributo `command` de `Execute` (lo convierte en `$HOME`) **antes** de pasarlo a `execvp()` — no solo en rutas. Por eso `wtype -- '~'` directo en el keybind escribía `/home/andysierra` en vez del símbolo. Solución: mover el `~` real a un script aparte, fuera del alcance de ese preprocesamiento.

```bash
#!/bin/bash
wtype -- '~'
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

### ~/.config/tmux/tmux.conf

Config general de tmux para cualquier sesión lanzada desde foot. Prefix `C-a`, modo vi, mouse, e indicador visual cuando el prefix está esperando. `extended-keys`/`foot:extkeys` son clave para que `Shift+Enter` y similares lleguen a las apps de adentro (p. ej. para pegar multilínea sin que se dispare).

```tmux
set -g prefix C-a			# prefix C-a instead of C-b
unbind C-b
bind C-a send-prefix			# C-a C-a sends a literal C-a

set -g mouse on				# wheel scrolls, click selects pane
setw -g mode-keys vi			# vim keys for tmux

# --- look of copy/scroll mode ---
set -g mode-style "bg=colour208,fg=black,bold"
set -g copy-mode-match-style "bg=colour237,fg=white"
set -g copy-mode-current-match-style "bg=colour208,fg=black"

# flash an indicator when the prefix (C-a) is pressed and waiting
set -g status-left "#{?client_prefix,#[bg=colour208#,fg=black#,bold] ^A #[default],#[bg=colour237#,fg=white] #S #[default]} "

# show scroll % in the status bar while in copy mode
set -g status-right "#{?pane_in_mode,#[bg=colour208#,fg=black#,bold] SCROLL #{e|/:#{e|*:#{scroll_position},100},#{history_size}}%% #[default] ,}%H:%M"

# highlight the active window in the status bar (instead of the *)
set -g window-status-current-style "bg=colour208,fg=black,bold"
set -g window-status-current-format " #I:#W "
set -g window-status-format " #I:#W "

set -g history-limit 10000
set -g base-index 1			# window numbering starts in 1
setw -g pane-base-index 1
set -g default-terminal "tmux-256color"
set -s extended-keys on			# pass Shift+Enter etc. through to apps
set -as terminal-features 'foot:extkeys'	# foot speaks extended keys

bind v copy-mode			# enter copy/scroll mode (easier than [)
bind c new-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
bind '"' split-window -v -c "#{pane_current_path}"
```

### ~/.config/yazi/yazi.toml

```toml
[manager]
show_hidden = true

[opener]
vlc = [
  { run = 'vlc %s', orphan = true, desc = "Reproducir en VLC", for = "unix" },
]
md-viewer = [
  { run = 'md-viewer-fresh %s', orphan = true, desc = "Ver en md-viewer", for = "unix" },
]

[open]
prepend_rules = [
  { url = "*.ts", use = "vlc" },
  { url = "*.TS", use = "vlc" },
  { mime = "video/mp2t", use = "vlc" },
  { url = "*.md", use = "md-viewer" },
  { url = "*.MD", use = "md-viewer" },
]
```

**Placeholder de `run` en `[opener]`: `%s`, no `"$@"`.** Yazi sustituye el token `%s` (o `%s1`, `%S`, `%S1`) directamente en el string del comando; nunca pasa los archivos como argv al shell. Poner `"$@"` hace que el opener se ejecute igual pero **sin ningún archivo** (0 args) — el error es silencioso, no tira nada a stderr.

### ~/.config/yazi/init.lua

`show_hidden = true` en yazi.toml no tiene efecto en yazi 26.x — este workaround lo activa al arrancar:

```lua
ya.emit("hidden", { "toggle" })
```

### md-viewer — visor de markdown, abierto por default al seleccionar *.md en yazi

Instalación (deja el binario en `~/.local/bin/md-viewer`):
```sh
curl -fsSL https://raw.githubusercontent.com/aydiler/md-viewer/main/scripts/install.sh | sh
```

`md-viewer` tiene instancia única: si ya hay una ventana abierta, un segundo lanzamiento le pasa el foco a esa ventana pero **no le reenvía el archivo nuevo** (bug de la app — confirmado inspeccionando `/proc/<pid>/cmdline`, queda sin argumentos). Además restaura la sesión anterior (`open_tabs` en `~/.local/share/md-viewer/app.ron`) al arrancar en frío, pisando igual el archivo pasado por CLI. El wrapper de abajo mata cualquier instancia previa y limpia ese estado antes de lanzar, para que cada apertura muestre siempre el archivo correcto.

**`~/.local/bin/md-viewer-fresh`:**
```bash
#!/bin/bash
# Lanza md-viewer con el archivo pasado, siempre en una instancia nueva.
#
# md-viewer tiene un lock de instancia unica: si ya hay un proceso vivo,
# el segundo lanzamiento cede el foco a esa ventana pero NO le reenvia el
# archivo (bug de la app, verificado via /proc/<pid>/cmdline). Ademas
# restaura open_tabs de app.ron al arrancar en frio, lo que tambien pisa
# el argumento. Se mata cualquier instancia previa y se limpia el estado
# guardado antes de lanzar, para que cada apertura sea realmente limpia.

pkill -x md-viewer 2>/dev/null
for _ in $(seq 1 20); do
    pgrep -x md-viewer >/dev/null || break
    sleep 0.1
done

STATE="$HOME/.local/share/md-viewer/app.ron"
if [[ -f "$STATE" ]]; then
    sed -i \
        -e 's/open_tabs:Some(\[[^]]*\])/open_tabs:Some([])/' \
        -e 's/active_tab:Some([0-9]*)/active_tab:Some(0)/' \
        "$STATE"
fi

exec md-viewer "$@"
```
```sh
chmod +x ~/.local/bin/md-viewer-fresh
```

El opener de yazi (sección anterior, `[opener].md-viewer` + regla `*.md`) apunta a este wrapper, no al binario directo.

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

### /etc/systemd/logind.conf.d/power-key.conf — botón de encendido suspende

Hacer que el **botón físico de encendido suspenda** en vez de apagar. Drop-in (no toca el `logind.conf` principal, sobrevive a updates):

```ini
[Login]
HandlePowerKey=suspend            # toque corto → suspende
HandlePowerKeyLongPress=poweroff  # mantener pulsado → apaga (válvula de escape)
```

Instalar:
```sh
sudo install -Dm644 power-key.conf /etc/systemd/logind.conf.d/power-key.conf
```

**Aplicar el cambio: reiniciar la PC** (recomendado). ⚠️ NO usar `systemctl restart systemd-logind` con la sesión gráfica abierta — logind administra el seat y al reiniciarse **tumba labwc y te deja en el TTY** (el drop-in en disco ya queda permanente igual).

Verificar el valor efectivo (es config de logind, no del unit → `systemctl show` no sirve, va por D-Bus):
```sh
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager HandlePowerKey   # → s "suspend"
```

> Nota sobre hibernación: requiere swap en disco ≥ RAM. Este equipo solo tiene **zram** (swap comprimida en RAM, inútil para hibernar) y el disco está sin espacio libre para partición → habría que montar un **swapfile en btrfs** (subvolumen sin CoW + `resume=`/`resume_offset=`). Pendiente.

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

### Extras opcionales

- **Alt como "Cmd" para Copiar/Pegar/Screenshot** (estilo macOS, vía `keyd`):
  spec aparte, autocontenido → [`spec-keyd-cmd-copypaste.md`](spec-keyd-cmd-copypaste.md).

### Limitaciones conocidas

- **yazi `prepend_keymap`**: completamente no funcional en yazi 26.x. Ningún binding personalizado dispara, incluso `run = "quit"`. No crear `keymap.toml`.
- **labwc windowRules**: no soporta `opacity` ni `inactiveOpacity`. No soporta `background.color` en themerc-override.
- **Firefox/Chromium CSD**: el compositor no puede agregar borde ni sombra — usan Client Side Decorations.
- **Clipboard imágenes**: Wayland no permite auto-paste de datos binarios con wtype. Solo `Ctrl+V`.
- **Wallpaper sin daemon**: labwc no tiene soporte nativo de wallpaper. Requiere `swaybg` u otro daemon. Se dejó el fondo negro por defecto.
- **`show_hidden` en yazi.toml**: ignorado en 26.x, workaround via `init.lua`.
- **windowSwitcher `style="thumbnail"`**: las flechas arriba/abajo no navegan la grilla (solo izquierda/derecha) y el OSD puede aparecer descentrado en multi-monitor. Se usa `style="classic"` (lista vertical, flechas funcionales).
- **Iconos por ruta absoluta en `.desktop`**: labwc (libsfdo) resuelve iconos por nombre vía tema, no por ruta. Usar `Icon=<nombre>` con el archivo en `hicolor/scalable/apps/`.
- **labwc `Execute` expande `~` literalmente**: no solo en rutas — cualquier `~` en el atributo `command` se convierte en `$HOME` antes de ejecutar. Si un comando necesita el carácter `~` de verdad (ej. `wtype -- '~'`), moverlo a un script aparte referenciado por ruta.
- **labwc no relee `rc.xml` solo — hay que recargarlo**: los cambios no aplican hasta enviar `SIGHUP` al proceso (`labwc --reconfigure`, `killall -HUP labwc`, o vía el menú raíz). Fácil de olvidar al editar keybinds.
- **`j4-dmenu-desktop` descarta `.desktop` inválidos en silencio**: un solo error de sintaxis (ej. línea con un espacio suelto) hace que el archivo entero no aparezca en bemenu, sin ningún mensaje. Verificar con `desktop-file-validate archivo.desktop`.
