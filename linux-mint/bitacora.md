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
| `Escape` / `Alt+Space` (dentro de rofi) | Cerrar rofi |

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
Terminal      mate-terminal  ← reemplaza foot (Wayland-only)
Atajos        dconf de MATE (/org/mate/desktop/keybindings/customN)  ← reemplaza rc.xml de labwc
Usuario       andysierra (rutas absolutas en greenclip.toml y mate-keybindings.sh: ajustar si cambia)
```

### Archivos de esta carpeta → destino

```text
linux-mint/
├── bitacora.md
├── bashrc-devenv.sh            → bloque a insertar en ~/.bashrc (ver sección bash)
├── mate-keybindings.sh         → correr una vez (idempotente): Alt+Space, Alt+F3, Alt+V
├── rofi/config.rasi            → ~/.config/rofi/config.rasi
├── greenclip/greenclip.toml    → ~/.config/greenclip.toml
├── greenclip/greenclip.desktop → ~/.config/autostart/greenclip.desktop
├── bin/clipboard.sh            → ~/.local/bin/clipboard.sh        (chmod +x)
└── applications/claudia.desktop→ ~/.local/share/applications/claudia.desktop
```

### 1. Paquetes (humano, requiere sudo)

```sh
sudo apt install git curl zip unzip rofi xdotool
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

### 7. Atajos de MATE

```sh
./mate-keybindings.sh
```

Desactiva `activate-window-menu` de Marco (ocupaba `Alt+Space`) y crea `custom0..2`. Aplica en vivo,
sin cerrar sesión. Alternativa gráfica: *Centro de control → Atajos de teclado*.

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
.vimrc con wl-copy                      → pendiente: vim-gtk3 (+clipboard) o xclip
```

### Pendiente de migrar

Del inventario de configs del repo aún no aplicado en Mint: vim/neovim, Zed (`zed/settings_linux.json`,
`keybindings_linux.json`), Claude (`claude/CLAUDE.md`, `settings.json`, hook Mermaid, skills),
yazi, tmux, fuentes, atajos restantes de escritorio (`Super+Enter`, `Super+C`, `Super+Alt+E`, `Alt+N` → `~`),
captura de área, Bruno, FreeOffice, botón de encendido, Chromium, IDEs (VS Code, IntelliJ, DBeaver…).
