# Linux Mint (MATE, X11) — Entorno de desarrollo

## Para el humano

Setup de desarrollo sobre **Linux Mint 22.3 "Zena" con escritorio MATE (sesión X11)**.
A diferencia de [`../linux/bitacora.md`](../linux/bitacora.md) (CachyOS + labwc/Wayland), acá
**se conserva el escritorio MATE** y se le agregan los atajos y herramientas del flujo propio.

Construido y verificado el 2026-10-05 (PC de escritorio, un monitor `HDMI-1` 1920×1080).

### Atajos

| Atajo | Acción |
|---|---|
| `Alt+Space` / `Alt+F3` | Lanzador de apps (rofi, estilo Spotlight) — `Shift+←/→` cambia entre apps / comandos / ventanas; escribir `claudia` abre terminal con Claude sin restricciones; `word` / `excel` / `powerpoint` abren FreeOffice |
| `Alt+V` | Historial de clipboard (greenclip en rofi, con miniaturas de imágenes) — auto-pega lo elegido |
| `Super+Enter` / `Ctrl+Alt+T` | Terminal (WezTerm) |
| `Super+C` | Zed abierto en `~/Escritorio/DEV` (Claude vive en su panel de agente) |
| `Alt+N` | Escribe `~` (en latam es AltGr+4 / AltGr+ñ) |
| `Alt+Q` / `Alt+F4` | Cerrar ventana |
| `Super+1` / `Super+2` | Cambiar de escritorio virtual (hay 2) |
| `Super+Shift+1` / `Super+Shift+2` | Mover ventana a escritorio |
| `Alt+Tab` / `Alt+Shift+Tab` | Ciclar ventanas de **todos** los escritorios |
| `Alt+Shift+S` | Captura de área → al soltar el mouse va **directo al clipboard** (queda en `Alt+V`) |
| `Alt+Shift+4` | Captura de área → al soltar el mouse se **guarda en `~/Imágenes`** (`captura_<fecha>_<hora>.png`) |
| `Super+S` | Sublime Text en ventana nueva (no pestaña); si está cerrado, lo abre |
| `Alt+E` | Explorador de archivos: yazi en terminal nueva maximizada, en `~/Escritorio` (`q` cierra la ventana) |
| `Escape` / `Alt+Space` (dentro de rofi) | Cerrar rofi |

Dentro de yazi (además del preset):

```text
{ / }          subir / bajar 5 filas
j              easyjump: saltar a un archivo visible con 1-2 teclas (y entrar si es carpeta)
I              easyjump sin entrar
T / Ctrl+T     terminal nueva en la carpeta actual
F / Ctrl+O     revelar el archivo en Caja
Enter en .md   abre en Zed
```

Comportamiento de `Alt+V` al elegir una entrada:

```text
Texto de una línea   lo escribe en la ventana activa
Texto multilínea     lo escribe con Shift+Enter entre líneas (no envía formularios en Claude/ChatGPT)
Imagen               la deja en el clipboard y pega con Ctrl+V
```

### Para replicar en un PC nuevo
Clonar este repo, compartir este archivo con Claude Code y pedirle: *"implementa la sección Para la IA de esta bitácora en este sistema"*.
Los pasos con `sudo` los corre el humano (Claude no tiene la contraseña); Claude espera y aplica las configs.

---

## Para la IA — Implementación completa

### Contexto del setup

```text
Distro        Linux Mint 22.3 (base Ubuntu 24.04 → paquetes vía apt)
Escritorio    MATE, gestor de ventanas Marco, sesión X11
Lanzador      rofi (repo apt, 1.7.5)  ← reemplaza bemenu + j4-dmenu-desktop de la bitácora CachyOS
Clipboard     greenclip (binario) + rofi + xdotool  ← reemplaza cliphist + bemenu + wtype
Terminal      WezTerm + IosevkaTerm Nerd Font + Tokyo Night  ← reemplaza foot (Wayland-only); la más cercana a iTerm2
Explorador    yazi (binario GitHub, /usr/local/bin) con flavor tokyo-night
Atajos        dconf de MATE (/org/mate/desktop/keybindings/customN)  ← reemplaza rc.xml de labwc
Usuario       andysierra (rutas absolutas en greenclip.toml y mate-keybindings.sh: ajustar si cambia)
```

### Archivos de esta carpeta → destino

```text
linux-mint/
├── bitacora.md
├── bashrc-envdev.sh            → bloque a insertar en ~/.bashrc (ver sección bash)
├── install-yazi.sh            → sudo, una vez: yazi + deps + fzf/resvg + Nerd Font
├── mate-keybindings.sh         → correr una vez (idempotente): todos los atajos + 2 escritorios + Alt+Tab
├── hide-screensavers.sh       → correr una vez (idempotente): saca de rofi los ~250 salvapantallas
├── mate-no-lock.sh            → correr una vez (idempotente): la sesión nunca se bloquea
├── wezterm/wezterm.lua         → ~/.config/wezterm/wezterm.lua  (terminal por defecto)
├── mate-terminal.sh            → (legado, opcional) mismo look en mate-terminal; ya no se usa
├── yazi/yazi.toml, keymap.toml → ~/.config/yazi/ (resto del config: ../yazi/config/)
├── bin/yazi-term.sh            → ~/.local/bin/yazi-term.sh        (chmod +x)
├── bin/screenshot-save.sh      → ~/.local/bin/screenshot-save.sh  (chmod +x)
├── bin/zed-icon.py             → ~/.local/bin/zed-icon.py  (chmod +x) + applications/zed-icon-autostart.desktop
│                                 → ~/.config/autostart/zed-icon.desktop
├── bin/type-tilde.sh           → ~/.local/bin/type-tilde.sh       (chmod +x)
├── flameshot/flameshot.ini     → ~/.config/flameshot/flameshot.ini
├── icons/zed.svg               → ~/.local/share/icons/hicolor/scalable/apps/zed.svg
├── sublime/                    → ~/.config/sublime-text/ (ver sección Sublime; resto en ../sublime/)
├── nvim/init.vim               → ~/.config/nvim/init.vim  (vim: ../nvim/.vimrc y ../nvim/plugins.vim)
├── rofi/config.rasi            → ~/.config/rofi/config.rasi
├── greenclip/greenclip.toml    → ~/.config/greenclip.toml
├── greenclip/greenclip.desktop → ~/.config/autostart/greenclip.desktop
├── bin/clipboard.sh            → ~/.local/bin/clipboard.sh        (chmod +x)
└── applications/*.desktop      → ~/.local/share/applications/  (claudia + FreeOffice renombrados)
```

### 1. Paquetes (humano, requiere sudo)

```sh
sudo apt install git curl zip unzip rofi xdotool vim-gtk3 neovim flameshot
```

- **rofi**: usar el de apt (1.7.5). Bajar el tarball de GitHub (`rofi-2.0.0`) es **código fuente** —
  exige meson + ~20 paquetes `-dev`; la 2.0 aporta sobre todo Wayland, irrelevante en X11.
- **xdotool**: sin él `clipboard.sh` igual copia la entrada al clipboard pero **no auto-pega**
  (lo detecta con `command -v` y sale). Si "Alt+V no pega", lo primero es `dpkg -l xdotool`.

### 2. Programas fuera de apt (humano)

```sh
curl -fsSL https://claude.ai/install.sh | bash          # Claude Code → ~/.local/bin/claude
curl -f https://zed.dev/install.sh | sh                 # Zed → ~/.local/zed.app, link en ~/.local/bin/zed
curl -s "https://get.sdkman.io" | bash                  # SDKMAN (agrega su bloque al final de ~/.bashrc)

# greenclip: binario estático, sin sudo
curl -L -o ~/.local/bin/greenclip https://github.com/erebe/greenclip/releases/latest/download/greenclip
chmod +x ~/.local/bin/greenclip
```

SDKMAN (en una terminal nueva):
```sh
sdk install java 25.0.4-tem    # versión usada al construir esto; `sdk list java` para ver otras
sdk install gradle
```

### 3. bash — `~/.bashrc`

**Insertar** el contenido de `bashrc-envdev.sh` en el `~/.bashrc` que trae Mint, **justo antes**
del bloque de SDKMAN (que debe quedar último). No reemplazar el archivo: el de Mint trae historial,
bash-completion (necesario para `complete -d go`), lesspipe y colores. Respaldar antes:
`cp ~/.bashrc ~/.bashrc.bak-mint`. Validar con `bash -n ~/.bashrc`.

Diferencias respecto de `linux/.bashrc` (CachyOS):

```text
git-prompt   /usr/share/git/completion/git-prompt.sh (Arch)  →  /usr/lib/git-core/git-sh-prompt (Debian/Mint)
PATH         export de ~/.local/bin dentro del bloque (lo pone el instalador de Claude; ~/.profile también)
```

**NO crear `~/.bash_profile`.** En CachyOS solo existía para lanzar labwc en TTY1. En Mint, si existe,
bash deja de leer `~/.profile` (que ya carga `.bashrc` y agrega `~/.local/bin` al PATH).

### 4. rofi — lanzador

```sh
mkdir -p ~/.config/rofi && cp rofi/config.rasi ~/.config/rofi/
```

Tema `gruvbox-dark-hard` (incluido en `/usr/share/rofi/themes`, mismo esquema que vim/Sublime).
**Búsqueda por prefijo:** `matching: "prefix"` + `sort`/`sorting-method: "fzf"` → "yo" abre YouTube, no
PolYOminoes (el default `normal` acepta el texto en cualquier parte). Solo en el lanzador: `clipboard.sh`
pasa `-matching normal` para buscar en medio del texto copiado. Probar sin interfaz:
`printf 'Polyominoes\nYouTube\n' | rofi -dmenu -i -filter yo -dump` (en dmenu `-i` es necesario).
**Salvapantallas en rofi:** "Braid", "Polyominoes", etc. no son apps: son los ~250 salvapantallas de
xscreensaver (`/usr/share/applications/screensavers/`, paquetes `xscreensaver-data*`/`-gl*` que trae
mate-screensaver) y rofi escanea subcarpetas. `./hide-screensavers.sh` los tapa con `.desktop`
`NoDisplay=true` en `~/.local/share/applications/screensavers/` (mismo id → gana el del usuario). rofi no
puede excluir por categoría (`drun-categories` es lista blanca). Revertir: `rm -r` de esa carpeta.
En rofi 1.7.5 la opción es `modes` (`modi` es el alias viejo). Verificar: `rofi -dump-config | grep -E 'modes|show-icons'`.

### 5. claudia — terminal Claude Code sin restricciones

```sh
cp applications/claudia.desktop ~/.local/share/applications/
desktop-file-validate ~/.local/share/applications/claudia.desktop
```

`bash -i` hace que se cargue `.bashrc` y resuelva el alias `claudia`. Aparece en rofi al escribir `claudia`.

### 5b. FreeOffice 2024 — "word", "excel", "powerpoint" en rofi

Instalar el `.deb` de https://www.freeoffice.com (paquete `softmaker-freeoffice-2024`). Luego:

```sh
cp applications/{textmaker,planmaker,presentations}-free24.desktop ~/.local/share/applications/
```

Mismos archivos que `/usr/share/applications/*-free24.desktop` con solo `Name=` cambiado (el de
`~/.local/share/applications` con el mismo nombre de archivo tapa al del sistema):

```text
textmaker-free24.desktop       FreeOffice 2024 TextMaker      → Word (FreeOffice TextMaker)
planmaker-free24.desktop       FreeOffice 2024 PlanMaker      → Excel (FreeOffice PlanMaker)
presentations-free24.desktop   FreeOffice 2024 Presentations  → PowerPoint (FreeOffice Presentations)
```

- El de TextMaker trae una línea con un solo espacio (inválida): se borra. En CachyOS eso hacía que
  `j4-dmenu-desktop` descartara el archivo entero; validar con `desktop-file-validate`.
- Solo hay `GenericName[xx]` traducidos, no `Name[xx]` → cambiar `Name=` alcanza en español.
- Diferencias con CachyOS: **no falta `libxmu`** (`ldd /usr/share/freeoffice2024/planmaker` sin "not found") y
  el `.deb` **ya deja FreeOffice como app por defecto** de doc/docx/xls/xlsx/ppt/pptx (`xdg-mime query default …`).
- El paquete trae también `*-2024.desktop` (versión de pago) sin cabecera `[Desktop Entry]`: inválidos, no aparecen.
- Verificar sin interfaz (con el prefijo de rofi): listar los `Name=` de todas las apps y
  `rofi -dmenu -i -filter word -dump` → solo "Word (FreeOffice TextMaker)".

### 5c. Zed — ícono visible

El ícono oficial (cuadro gris oscuro con una Z de trazo fino) se pierde en el panel oscuro. `icons/zed.svg`:
logo oficial en `#1a1b26` sobre cuadro azul tokyo-night `#7aa2f7`.

```sh
mkdir -p ~/.local/share/icons/hicolor/scalable/apps
cp icons/zed.svg ~/.local/share/icons/hicolor/scalable/apps/zed.svg
rm -f ~/.local/share/icons/hicolor/icon-theme.cache   # caché vieja → cae al ícono por defecto
F=~/.local/share/applications/dev.zed.Zed.desktop     # lo crea el instalador de Zed
sed -i 's|^Icon=.*|Icon=zed|' "$F"
grep -q '^StartupWMClass=' "$F" || sed -i '0,/^Icon=zed$/s//Icon=zed\nStartupWMClass=dev.zed.Zed/' "$F"
```

- `Icon=` por **nombre** (resuelto vía tema hicolor), no por ruta: igual que en la bitácora CachyOS.
- Con eso cambia el ícono en rofi y en el menú, **pero no en la barra de tareas**: la ventana de Zed no publica
  ícono propio (`xprop _NET_WM_ICON` vacío) y la lista de ventanas de MATE usa el ícono **de la ventana**, no el
  del `.desktop` → cuadro gris genérico. `bin/zed-icon.py` (python3-xlib, ya viene en Mint) corre en segundo
  plano, escucha `_NET_CLIENT_LIST` del root y a cada ventana `WM_CLASS=dev.zed.Zed` le escribe `_NET_WM_ICON`
  con el ícono `zed` del tema (16…128 px):
  ```sh
  cp bin/zed-icon.py ~/.local/bin/ && chmod +x ~/.local/bin/zed-icon.py
  cp applications/zed-icon-autostart.desktop ~/.config/autostart/zed-icon.desktop
  setsid ~/.local/bin/zed-icon.py >/dev/null 2>&1 &     # ya, sin esperar al próximo login
  ```
  Verificar: `xprop -id <ventana zed> _NET_WM_ICON` debe mostrar "Icon (16 x 16)…".
- `StartupWMClass=dev.zed.Zed` (= `WM_CLASS`) asocia la ventana con el `.desktop`.
- Si se reinstala Zed con `install.sh`, se regenera el `.desktop`: volver a correr los `sed`.
- Verificar: `python3 -c "import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk; print(Gtk.IconTheme.get_default().lookup_icon('zed',48,0).get_filename())"`.

### 6. greenclip — historial de clipboard

```sh
cp greenclip/greenclip.toml ~/.config/greenclip.toml
mkdir -p ~/.config/autostart && cp greenclip/greenclip.desktop ~/.config/autostart/
cp bin/clipboard.sh ~/.local/bin/ && chmod +x ~/.local/bin/clipboard.sh
setsid ~/.local/bin/greenclip daemon >/dev/null 2>&1 &   # arrancarlo ya, sin esperar al próximo login
```

Puntos de `greenclip.toml`:
- `image_cache_directory = ~/.cache/greenclip-img` — **no** el default `/tmp/greenclip`: `/tmp` se borra al
  reiniciar pero el historial (`~/.cache/greenclip.history`) persiste → las imágenes viejas quedarían rotas.
- `static_history = []` — la config que genera greenclip v4.2 trae un aviso obsoleto ("update to v4.1") como entrada fija.
- `enable_image_support = true`.

### 7. yazi — explorador de archivos

```sh
sudo ./install-yazi.sh      # apt: xclip ffmpeg jq fd-find ripgrep zoxide 7zip poppler-utils
                            # GitHub: yazi+ya, fzf, resvg → /usr/local/bin ; IosevkaTerm Nerd Font
# terminal: WezTerm (sección 7b) — con Nerd Font; sin ella yazi muestra símbolos raros en vez de íconos

mkdir -p ~/.config/yazi
cp ../yazi/config/{theme.toml,init.lua,package.toml} ~/.config/yazi/
cp -r ../yazi/config/plugins ~/.config/yazi/
cp yazi/yazi.toml yazi/keymap.toml ~/.config/yazi/      # variantes Linux (las de ../yazi/config son del Mac)
(cd ~/.config/yazi && ya pkg install)                    # baja easyjump + flavor tokyo-night
cp bin/yazi-term.sh ~/.local/bin/ && chmod +x ~/.local/bin/yazi-term.sh
```

Por qué así:
- **yazi no está en apt** → binario oficial. **fzf de apt (0.44) es menor al mínimo de yazi (0.53)** → binario.
  **ImageMagick de apt es 6.9, yazi pide ≥ 7.1** → se omite (solo aporta preview de fuentes/HEIC/JPEG XL;
  PNG/JPG/GIF los decodifica yazi solo).
- Todo a **`/usr/local/bin`**, no `~/.local/bin`: así lo encuentran también los atajos de MATE (ver gotcha del PATH).
- `fd` en Debian se llama `fdfind` → el script crea el link `fd`.
- El script resuelve siempre la última release vía la API de GitHub; correrlo de nuevo = actualizar.

Diferencias Linux vs Mac en `yazi.toml` / `keymap.toml`:

```text
                 Mac (../yazi/config)          Linux (yazi/)
.md              Readdown                      Zed (ruta absoluta ~/.local/bin/zed)
.drawio          PWA draw.io                   — (draw.io no instalado)
T / Ctrl+T       iTerm (~/bin/iterm-here.sh)   wezterm start --cwd "$PWD"
F / Ctrl+O       open -R (Finder)              caja --select %s1
placeholder      "$@"                          %s / %s1 / %d1 (yazi 26.9; "$@" = 0 archivos, sin error)
```

WezTerm reutiliza el proceso GUI ya abierto: sin `--cwd` abriría en el cwd de ese proceso, no en la carpeta de yazi.

`Alt+E` → `yazi-term.sh`: **siempre ventana nueva** (mismo criterio que el Mac),
`wezterm start --always-new-process --cwd ~/Escritorio -- yazi ~/Escritorio`. WezTerm no tiene `--maximize`:
lo hace el evento `gui-startup` de `wezterm.lua` para las ventanas cuyo comando es `yazi`, y ese evento solo
corre en un proceso nuevo (de ahí `--always-new-process`). yazi va directo (sin bash detrás) → `q` cierra la ventana.

### 7b. WezTerm — terminal por defecto (reemplaza mate-terminal)

Elegida por ser la más parecida a iTerm2 (tabs, splits, búsqueda, copy mode) y porque **muestra imágenes**:
mate-terminal (VTE 0.76 de Ubuntu) no implementa ningún protocolo de imágenes → yazi dejaba la preview vacía.

```sh
# repo apt oficial (https://wezterm.org/install/linux.html#using-the-apt-repo)
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo apt update && sudo apt install wezterm-nightly   # el instalado; "wezterm" (estable) es de 2024-02

mkdir -p ~/.config/wezterm && cp wezterm/wezterm.lua ~/.config/wezterm/
```

`wezterm.lua`: IosevkaTerm Nerd Font Mono 12, esquema `Tokyo Night` (mismo fondo `#1a1b26` que el flavor de
yazi), cerrar sin confirmar, 100k líneas de scroll, sin barra de tabs con una sola tab, sin campana, sin chequeo
de updates (los trae apt), y el `gui-startup` que maximiza yazi.

Dónde se usa (todo lo que antes abría mate-terminal):

```text
Super+Enter           custom4 → wezterm                              (mate-keybindings.sh)
Ctrl+Alt+T            Marco run-command-terminal → org.mate.applications-terminal exec='wezterm' exec-arg='-e'
                      (lo mismo usan "Abrir en terminal" de Caja y las apps con Terminal=true)
Alt+E                 bin/yazi-term.sh (ver sección yazi)
yazi T / Ctrl+T       wezterm start --cwd "$PWD"                     (yazi/keymap.toml)
claudia (rofi)        wezterm start --class claudia -- bash -i -c "claudia; exec bash"
```

- `wezterm -e cmd` es alias de `wezterm start -- cmd` → sirve como `exec-arg` de MATE.
- yazi detecta WezTerm por `TERM_PROGRAM=WezTerm` y usa **IIP** (protocolo de imágenes de iTerm2, igual que en
  el Mac). Verificar dentro de WezTerm: `ya env` → `Adapter / Drivers.matches: Iip`.
- `x-terminal-emulator` (alternativa de Debian) sigue en mate-terminal; MATE no la usa. Cambiarla es opcional:
  `sudo update-alternatives --config x-terminal-emulator`.
- Validar la config sin abrir ventana: `wezterm ls-fonts` (carga `wezterm.lua`; errores de Lua salen ahí).

### 8. vim / neovim

```sh
sudo apt install vim-gtk3 neovim     # vim-gtk3, NO "vim": el de apt es -clipboard
cp ../nvim/.vimrc ~/.vimrc
mkdir -p ~/.vim/autoload ~/.config/nvim
cp ../nvim/plugins.vim ~/.vim/plugins.vim
cp nvim/init.vim ~/.config/nvim/init.vim
curl -fsSLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim -es -u ~/.vimrc -i NONE -c 'PlugInstall --sync' -c 'qa!'     # 9 plugins → ~/.vim/plugged
```

- **Clipboard:** `vim-gtk3` trae `+clipboard`/`+xterm_clipboard` → `set clipboard=unnamedplus` del `.vimrc`
  funciona nativo en X11. El `autocmd ... wl-copy` de `../linux/.vimrc` es solo Wayland: no se usa.
  neovim usa `xclip` (instalado por install-yazi.sh). Lo copiado queda también en greenclip (`Alt+V`).
- **neovim** comparte config y plugins con vim: `init.vim` agrega `~/.vim` al runtimepath y hace `source ~/.vimrc`.
  (El `../nvim/init.vim` original apuntaba a `$HOME/vim`, sin punto y con comillas que vim no expande.)
- **gruvbox:** `g:gruvbox_contrast_dark` tiene que ir **antes** de `colorscheme` (después no tiene efecto).
  `silent! colorscheme` evita el error en el primer arranque, antes de `PlugInstall`.
- **`vi` → vim.gtk3**: apt lo registra en `update-alternatives`. Importa para yazi: su opener `edit` usa
  `${EDITOR:-vi}` y lanzado con `Alt+E` (sin bash) no hay `EDITOR` → cae en `vi` = vim completo.
- Verificar: `vim --version | grep clipboard` → `+clipboard`.

### 8b. Sublime Text 4

Instalar desde el repo apt oficial (https://www.sublimetext.com/docs/linux_repositories.html), paquete
`sublime-text` (probado con build 4215). Luego:

```sh
U=~/.config/sublime-text/Packages/User; mkdir -p "$U"
cp sublime/Preferences.sublime-settings "sublime/Package Control.sublime-settings" "$U/"
cp ../sublime/keymap.txt "$U/Default (Linux).sublime-keymap"
cp ../sublime/Terminus.sublime-settings.json "$U/Terminus.sublime-settings"
cp ../sublime/auto_reveal_in_sidebar.py.paste_in_roaming_packages_user "$U/auto_reveal_in_sidebar.py"
./sublime/install-packages.sh     # gruvbox 4.0.1 + Terminus v0.3.37 desde GitHub
```

```text
repo (../sublime/, Windows)                  Linux (~/.config/sublime-text/Packages/User/)
-------------------------------------------  -----------------------------------------------
settings.txt                                 Preferences.sublime-settings  (sublime/ — variante)
keymap.txt                                   Default (Linux).sublime-keymap
Terminus.sublime-settings.json               Terminus.sublime-settings (Git Bash solo aplica a Windows)
auto_reveal_in_sidebar.py.paste_in_...       auto_reveal_in_sidebar.py
open folder with sublime.reg                 — (Windows)
```

- **Paquetes:** el `color_scheme` necesita **gruvbox** y `alt+3` necesita **Terminus**. Sin ellos, al abrir:
  *"Error loading colour scheme … Unable to find Packages/gruvbox/…"*. Package Control con
  `installed_packages` debería instalarlos solo, pero en la primera prueba no lo hizo (Sublime se cerró antes).
  `install-packages.sh` los baja del tag de GitHub y los deja como `.sublime-package` en `Installed Packages`
  (zip sin la carpeta raíz que agrega GitHub); Sublime los carga en caliente.
- La variante Linux **no ignora Package Control** (el `settings.txt` original sí, en `ignored_packages`).
- `Super+S` → `subl --launch-or-new-window` (`mate-keybindings.sh`, custom9): ventana nueva aunque
  `open_files_in_new_window` sea false; si Sublime está cerrado lo abre (con `-n` saldrían dos ventanas).

### 9. flameshot — captura de área

```sh
mkdir -p ~/.config/flameshot && cp flameshot/flameshot.ini ~/.config/flameshot/
flameshot config --check     # → "No errors detected."
```

```sh
cp bin/screenshot-save.sh ~/.local/bin/ && chmod +x ~/.local/bin/screenshot-save.sh
```

Reemplaza `grim + slurp + swappy`. **Sin clics extra**: los dos atajos usan `-s` (`--accept-on-select`), la
captura termina al soltar el mouse (sin Enter ni botón de copiar; sin anotación):

```text
Alt+Shift+S   flameshot gui -c -s                       → clipboard
Alt+Shift+4   flameshot gui -s -p "$(xdg-user-dir PICTURES)"  (screenshot-save.sh) → ~/Imágenes
```

Para anotar antes de copiar: `flameshot gui` sin `-s` (no tiene atajo). Config: sin ícono
de bandeja, sin mensaje de inicio / notificaciones / ayuda, sin chequeo de updates, nombre `captura_<fecha>_<hora>`.
El atajo (`flameshot gui`) lo crea `mate-keybindings.sh`. Tras copiar, flameshot queda corriendo en segundo plano:
es el dueño del clipboard (en X11 el contenido vive en el proceso que copió) — normal.

### 10. Atajos de MATE

```sh
./mate-keybindings.sh
```

Requiere antes en `~/.local/bin`: `clipboard.sh`, `yazi-term.sh`, `type-tilde.sh` (y Zed instalado).
Hace, en vivo y sin cerrar sesión:

```text
custom0..9         Alt+Space, Alt+F3 (rofi) · Alt+V (clipboard) · Alt+E (yazi) · Super+Enter (terminal)
                   Super+C (Zed en ~/Escritorio/DEV) · Alt+N (~) · Alt+Q (cerrar, wmctrl -c :ACTIVE:)
                   Alt+Shift+S (flameshot gui -c -s) · Super+S (subl --launch-or-new-window)
Marco              libera Alt+Space (activate-window-menu) · 2 escritorios (venía con 4)
                   Super+1/2 y Super+Shift+1/2 · Alt+Tab → switch-windows-all (todos los escritorios)
                   run-command-1: Alt+Shift+4 (screenshot-save.sh)
                   run-command-screenshot (captura completa de MATE, venía en Alt+Shift+4) → disabled
```

Equivalencia con `rc.xml` de la bitácora CachyOS: `Super+Alt+E` → `Alt+E`, `Super+V` → `Alt+V` (elegidos así);
`Super+M` (monitores) y `Fn+brillo/volumen` no aplican (un monitor; MATE maneja las teclas multimedia).

Alternativa gráfica: *Centro de control → Atajos de teclado*.

### 11. Sin bloqueo de sesión

```sh
./mate-no-lock.sh
```

Mint MATE activa el salvapantallas tras 5 min de inactividad (`org.mate.session idle-delay`) y, con
`org.mate.screensaver lock-enabled=true`, pide contraseña al volver. El script apaga eso y además el bloqueo
al volver de suspender/hibernar y cuando el ahorro de energía apaga la pantalla (`org.mate.power-manager lock-*`).
La pantalla igual se apaga a los 30 min sin uso (`sleep-display-ac 1800`), pero sin bloquear.

### Audio — auriculares USB (Logitech G435)

Si no suena con el receptor USB conectado: el kernel lo ve (`aplay -l` → tarjeta "G435") y PipeWire crea su
salida, pero (1) Mint no cambia la salida por defecto sola → `pactl set-default-sink <alsa_output.usb-...>` o
ícono de sonido; y (2) **el G435 puede estar en modo Bluetooth** (enlazado a otro equipo): el PC le manda audio
al receptor sin errores (`pw-top`, columna ERR en 0) pero los auriculares no escuchan la radio del receptor.

### Gotchas (lo que costó descubrir)

- **La sesión de MATE no tiene `~/.local/bin` en el PATH** si la carpeta no existía al iniciar sesión
  (`~/.profile` la agrega solo si existe en ese momento; en un PC nuevo la crean después los instaladores
  de Claude/Zed). Los atajos corren con el PATH de la sesión → `greenclip` "no existía" y rofi abría
  **vacío** sin ningún error. Por eso `clipboard.sh` y `mate-keybindings.sh` usan rutas absolutas.
  Diagnóstico: `tr '\0' '\n' < /proc/$(pgrep -f mate-settings-daemon | head -1)/environ | grep ^PATH=`.
- **greenclip lista los saltos de línea como U+00A0 (nbsp)** en `greenclip print`. `clipboard.sh` los
  revierte a `\n` para tipear multilínea. `greenclip print "<entrada>"` (con la línea tal cual) la restaura al clipboard.
- **Imágenes en greenclip** aparecen como `image/png [app origen] <id>`; el PNG está en
  `<image_cache_directory>/<id>.png`. `clipboard.sh` se lo pasa a rofi como ícono (`texto\0icon\x1f<ruta>`
  + `-show-icons`) para mostrar miniatura.
- **Auto-pegar imágenes sí se puede en X11** (`xdotool key ctrl+v`). La bitácora CachyOS decía que no:
  era una limitación de Wayland/wtype.
- **`Alt+V` global le gana a las apps**: se pierden los mnemónicos `Alt+V` (menú "Ver") y `Alt+V` en
  terminal/vim. **Choca con el spec opcional de keyd** (`../linux/spec-keyd-cmd-copypaste.md`, donde
  `Alt+V` = pegar): si se instala keyd, quitar la línea `v = C-v` de su `[alt]`.
- **`Alt+E` global**: se pierde el mnemónico `Alt+E` (menú "Editar") dentro de las apps.
- **Atajo que escribe texto (Alt+N) no escribía nada:** mientras la tecla del atajo sigue apretada,
  mate-settings-daemon mantiene el teclado capturado (*passive grab*) y lo que tipea `xdotool` va a parar
  al que capturó, no a la ventana. `type-tilde.sh` espera 0.25 s (a que se suelte la N) y usa
  `--clearmodifiers` por si Alt sigue apretado. El atajo sí se disparaba (verificable cambiando la acción
  por `sh -c "date >> /tmp/fired"`).
- **Marco admite una sola tecla por acción** (`close` = `Alt+F4`): `Alt+Q` va como atajo propio con
  `wmctrl -c :ACTIVE:` (cierre normal, como Alt+F4; no `xdotool windowclose`, que destruye la ventana).
- **Alt+Tab en MATE recorre solo el escritorio actual** (`switch-windows`); para todos es `switch-windows-all`.
- **flameshot no abría (proceso vivo, sin capa de selección):** había abierto un diálogo
  *"Resolve configuration errors"* por `savePath=/home/andysierra/Imágenes`: Qt no lee bien la `á` cruda en
  el `.ini`. Diagnóstico: `flameshot config --check`. Solución: no definir `savePath` (el default ya es la
  carpeta de imágenes XDG).
- **Shift+número no funciona en los atajos propios (customN)** de mate-settings-daemon: `<Mod4><Shift>4` ni
  `<Mod4><Shift>dollar` se disparan (probado con Super; Alt+Shift+4 también va por Marco). Marco sí los toma (por eso `Super+Shift+1/2` andan): esos atajos van en
  `org.mate.Marco.keybinding-commands command-N` + `global-keybindings run-command-N`.
- **Openers de yazi 26.x**: `%s` (todos), `%s1` (el primero), `%d1` (su carpeta). Verificable en el preset
  embebido: `strings /usr/local/bin/yazi | grep xdg-open`. La sección es `[mgr]` (no `[manager]`).
- **`.desktop` con varias categorías principales** (`Development;Utility;`) genera warning en
  `desktop-file-validate` y la app puede salir duplicada en el menú de MATE → una sola.

### No aplica en Mint (queda en la bitácora CachyOS)

```text
labwc, rc.xml, themerc, environment     → MATE/Marco hace de escritorio
foot / foot.ini                         → WezTerm (wezterm/wezterm.lua)
wl-copy, cliphist, wtype                → greenclip + xdotool
grim + slurp + swappy                   → flameshot (Alt+Shift+S)
wlr-randr, acpid (tapa), monitores      → un solo monitor; MATE gestiona pantallas
.bash_profile (exec labwc)              → no crear (ver sección bash)
.vimrc con wl-copy                      → vim-gtk3 (+clipboard nativo), ver sección vim
```

### Pendiente de migrar

Del inventario de configs del repo aún no aplicado en Mint: Zed (`zed/settings_linux.json`,
`keybindings_linux.json`), Claude (`claude/CLAUDE.md`, `settings.json`, hook Mermaid, skills),
tmux, fuentes del repo (`fonts/`), Bruno, FreeOffice, botón de encendido, Chromium, IDEs (VS Code, IntelliJ, DBeaver…).
