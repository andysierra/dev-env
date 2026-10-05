# Linux Mint (MATE, X11) — Entorno de desarrollo

## Para el humano

Setup de desarrollo sobre **Linux Mint 22.3 "Zena" con escritorio MATE (sesión X11)**.
A diferencia de [`../linux/bitacora.md`](../linux/bitacora.md) (CachyOS + labwc/Wayland), acá
**se conserva el escritorio MATE** y se le agregan los atajos y herramientas del flujo propio.

Construido y verificado el 2026-10-05 (PC de escritorio, un monitor `HDMI-1` 1920×1080).

### Atajos

| Atajo | Acción |
|---|---|
| `Alt+Space` / `Alt+F3` | Lanzador de apps (rofi, estilo Spotlight) — `Shift+←/→` cambia entre apps / comandos / ventanas; escribir `claudia` abre terminal con Claude sin restricciones |
| `Alt+V` | Historial de clipboard (greenclip en rofi, con miniaturas de imágenes) — auto-pega lo elegido |
| `Super+Enter` | Terminal (mate-terminal) |
| `Super+C` | Zed abierto en `~/Escritorio/DEV` (Claude vive en su panel de agente) |
| `Alt+N` | Escribe `~` (en latam es AltGr+4 / AltGr+ñ) |
| `Alt+Q` / `Alt+F4` | Cerrar ventana |
| `Super+1` / `Super+2` | Cambiar de escritorio virtual (hay 2) |
| `Super+Shift+1` / `Super+Shift+2` | Mover ventana a escritorio |
| `Alt+Tab` / `Alt+Shift+Tab` | Ciclar ventanas de **todos** los escritorios |
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
Terminal      mate-terminal + IosevkaTerm Nerd Font + paleta tokyo-night  ← reemplaza foot (Wayland-only)
Explorador    yazi (binario GitHub, /usr/local/bin) con flavor tokyo-night
Atajos        dconf de MATE (/org/mate/desktop/keybindings/customN)  ← reemplaza rc.xml de labwc
Usuario       andysierra (rutas absolutas en greenclip.toml y mate-keybindings.sh: ajustar si cambia)
```

### Archivos de esta carpeta → destino

```text
linux-mint/
├── bitacora.md
├── bashrc-devenv.sh            → bloque a insertar en ~/.bashrc (ver sección bash)
├── install-yazi.sh            → sudo, una vez: yazi + deps + fzf/resvg + Nerd Font
├── mate-keybindings.sh         → correr una vez (idempotente): todos los atajos + 2 escritorios + Alt+Tab
├── mate-terminal.sh            → correr una vez (idempotente): fuente Nerd + paleta tokyo-night
├── yazi/yazi.toml, keymap.toml → ~/.config/yazi/ (resto del config: ../yazi/config/)
├── bin/yazi-term.sh            → ~/.local/bin/yazi-term.sh        (chmod +x)
├── bin/type-tilde.sh           → ~/.local/bin/type-tilde.sh       (chmod +x)
├── nvim/init.vim               → ~/.config/nvim/init.vim  (vim: ../nvim/.vimrc y ../nvim/plugins.vim)
├── rofi/config.rasi            → ~/.config/rofi/config.rasi
├── greenclip/greenclip.toml    → ~/.config/greenclip.toml
├── greenclip/greenclip.desktop → ~/.config/autostart/greenclip.desktop
├── bin/clipboard.sh            → ~/.local/bin/clipboard.sh        (chmod +x)
└── applications/claudia.desktop→ ~/.local/share/applications/claudia.desktop
```

### 1. Paquetes (humano, requiere sudo)

```sh
sudo apt install git curl zip unzip rofi xdotool vim-gtk3 neovim
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

**Insertar** el contenido de `bashrc-devenv.sh` en el `~/.bashrc` que trae Mint, **justo antes**
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
En rofi 1.7.5 la opción es `modes` (`modi` es el alias viejo). Verificar: `rofi -dump-config | grep -E 'modes|show-icons'`.

### 5. claudia — terminal Claude Code sin restricciones

```sh
cp applications/claudia.desktop ~/.local/share/applications/
desktop-file-validate ~/.local/share/applications/claudia.desktop
```

`bash -i` hace que se cargue `.bashrc` y resuelva el alias `claudia`. Aparece en rofi al escribir `claudia`.

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
./mate-terminal.sh          # sin Nerd Font en la terminal, yazi muestra símbolos raros en vez de íconos

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
T / Ctrl+T       iTerm (~/bin/iterm-here.sh)   mate-terminal --window --working-directory="$PWD"
F / Ctrl+O       open -R (Finder)              caja --select %s1
placeholder      "$@"                          %s / %s1 / %d1 (yazi 26.9; "$@" = 0 archivos, sin error)
```

`mate-terminal` reutiliza un proceso servidor: sin `--working-directory` abriría en el cwd del servidor,
no en la carpeta de yazi. **`mate-terminal` no tiene `-x`** (gnome-terminal sí): para ejecutar un comando
se usa `-e "cmd args"` (un solo string).

`Alt+E` → `yazi-term.sh`: **siempre ventana nueva** (mismo criterio que el Mac), `--maximize`, yazi lanzado
directo con `-e` (sin bash detrás) → al salir con `q` la ventana se cierra. Arranca en `~/Escritorio`.

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

### 9. Atajos de MATE

```sh
./mate-keybindings.sh
```

Requiere antes en `~/.local/bin`: `clipboard.sh`, `yazi-term.sh`, `type-tilde.sh` (y Zed instalado).
Hace, en vivo y sin cerrar sesión:

```text
custom0..7         Alt+Space, Alt+F3 (rofi) · Alt+V (clipboard) · Alt+E (yazi) · Super+Enter (terminal)
                   Super+C (Zed en ~/Escritorio/DEV) · Alt+N (~) · Alt+Q (cerrar, wmctrl -c :ACTIVE:)
Marco              libera Alt+Space (activate-window-menu) · 2 escritorios (venía con 4)
                   Super+1/2 y Super+Shift+1/2 · Alt+Tab → switch-windows-all (todos los escritorios)
```

Equivalencia con `rc.xml` de la bitácora CachyOS: `Super+Alt+E` → `Alt+E`, `Super+V` → `Alt+V` (elegidos así);
`Super+M` (monitores) y `Fn+brillo/volumen` no aplican (un monitor; MATE maneja las teclas multimedia);
`Super+Shift+S` (captura) sigue pendiente. Alternativa gráfica: *Centro de control → Atajos de teclado*.

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
- **Openers de yazi 26.x**: `%s` (todos), `%s1` (el primero), `%d1` (su carpeta). Verificable en el preset
  embebido: `strings /usr/local/bin/yazi | grep xdg-open`. La sección es `[mgr]` (no `[manager]`).
- **`.desktop` con varias categorías principales** (`Development;Utility;`) genera warning en
  `desktop-file-validate` y la app puede salir duplicada en el menú de MATE → una sola.

### No aplica en Mint (queda en la bitácora CachyOS)

```text
labwc, rc.xml, themerc, environment     → MATE/Marco hace de escritorio
foot / foot.ini                         → mate-terminal
wl-copy, cliphist, wtype                → greenclip + xdotool
grim + slurp + swappy                   → pendiente (candidato: flameshot)
wlr-randr, acpid (tapa), monitores      → un solo monitor; MATE gestiona pantallas
.bash_profile (exec labwc)              → no crear (ver sección bash)
.vimrc con wl-copy                      → vim-gtk3 (+clipboard nativo), ver sección vim
```

### Pendiente de migrar

Del inventario de configs del repo aún no aplicado en Mint: Zed (`zed/settings_linux.json`,
`keybindings_linux.json`), Claude (`claude/CLAUDE.md`, `settings.json`, hook Mermaid, skills),
tmux, fuentes del repo (`fonts/`), captura de área (`Super+Shift+S`), Bruno, FreeOffice, botón de encendido, Chromium, IDEs (VS Code, IntelliJ, DBeaver…).
