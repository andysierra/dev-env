# macOS — iTerm + yazi con hotkey global (⌥⌘E)

Explorador de archivos por teclado en macOS: **iTerm2 + yazi**, disparado con un hotkey
global, siempre **una sola ventana**, **maximizada** (no pantalla completa de macOS) y
abriendo en **~/Desktop**. Equivalente macOS del `Super+E` de `linux/bitacora.md`.

## Para el humano

```text
ATAJO          ⌥⌘E  (Option + Command + E)
QUÉ HACE       abre iTerm con yazi en ~/Desktop, ventana maximizada
SI YA ESTÁ     no abre otra: trae al frente la misma ventana y la re-maximiza
AL SALIR (q)   la ventana se cierra sola; el siguiente ⌥⌘E abre una limpia
ICONOS         los da la fuente Nerd Font del perfil de iTerm (no un plugin de yazi)

DENTRO DE YAZI
T (Shift+t)    abre una ventana NUEVA de iTerm en el directorio donde estás,
Ctrl+T         sin cerrar ni bloquear yazi. OJO: la "t" minúscula NO es esto;
               es el prefijo de tabs del preset (t t = new tab)
;              shell de yazi (espera a que termine el comando)
:              shell de yazi bloqueante (el que se usaba para meterle "zsh")
```

### Para replicar en un mac nuevo
Compartí este archivo con Claude Code y pedile: *"implementá la sección **Para la IA** de este
spec en este mac"*. Los archivos que hay que copiar están en `macos/iterm-yazi/`.

---

## Para la IA — Implementación completa

Seguí los pasos en orden. Todo es idempotente salvo el paso 5 (regla de Karabiner), que hace
backup antes de escribir. **No** uses `⌘E` a secas: ver "Decisiones" al final.

### Contexto del setup

```text
Terminal              iTerm2
Explorador            yazi (TUI)
Hotkey global          Karabiner-Elements (complex_modification -> shell_command)
Pegamento             AppleScript/JXA (osascript -l JavaScript) para controlar iTerm
Fuente del terminal   Cascadia Code NF (Nerd Font) -> de ahí salen los iconos
Estado del singleton  ~/.cache/yazi-desktop-window (id de ventana de iTerm)
Terminal desde yazi   Shift+T o Ctrl+T -> open -a iTerm <cwd> (keymap.toml, shell --orphan)
```

### Paso 1 — Software

```sh
# Homebrew (si el mac es nuevo)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Núcleo
brew install yazi
brew install --cask iterm2 karabiner-elements

# Fuente con iconos (Nerd Font). Esta es la que se usa acá:
brew install --cask font-cascadia-code-nf

# Opcionales de yazi (previews: imágenes, PDF, video, zip, búsqueda)
brew install ffmpeg sevenzip jq poppler fd ripgrep fzf zoxide imagemagick resvg
```

Verificar:

```sh
yazi --version
ls -d /Applications/iTerm.app ~/Applications/iTerm.app 2>/dev/null   # puede estar en cualquiera de los dos
ls -d /Applications/Karabiner-Elements.app
```

Karabiner-Elements pide, **la primera vez y a mano**, habilitar su extensión de sistema y
"Input Monitoring" (System Settings > Privacy & Security). Abrirlo una vez y seguir su
asistente; sin eso no hay hotkeys.

### Paso 2 — Iconos de yazi en iTerm (Nerd Font)

Importante entender esto antes de tocar nada: **yazi no necesita configuración para los
iconos**. Su set de iconos por defecto viene compilado en el binario y usa codepoints de
Nerd Font (mayormente `nf-md-*`, Material Design Icons). Si se ven cuadritos o `?`, el
problema es **la fuente del perfil de iTerm**, nunca yazi. En este mac no existe
`~/.config/yazi/` y los iconos se ven bien.

1. Instalar la Nerd Font (paso 1). Confirmar que quedó:
   ```sh
   ls ~/Library/Fonts | grep -i cascadiacodenf     # CascadiaCodeNF.ttf, CascadiaCodeNFItalic.ttf
   ```
2. iTerm2 > Settings (⌘,) > **Profiles** > perfil por defecto > **Text**:
   - **Font**: `CascadiaCodeNF-Regular` (aparece como "Cascadia Code NF"), tamaño 18.
   - **Use a different font for non-ASCII text**: **desactivado**. Si se activa, los glifos
     de iconos se dibujan con la fuente non-ASCII y se rompen.
3. Verificar sin abrir la UI (lee las prefs reales de iTerm):
   ```sh
   /usr/libexec/PlistBuddy -c "Print :'New Bookmarks':0:'Normal Font'" \
     ~/Library/Preferences/com.googlecode.iterm2.plist
   # esperado: CascadiaCodeNF-Regular 18
   /usr/libexec/PlistBuddy -c "Print :'New Bookmarks':0:'Use Non ASCII Font'" \
     ~/Library/Preferences/com.googlecode.iterm2.plist
   # esperado: false, o "Does Not Exist" (= default false)
   ```
4. Test de glifos, **corriendo dentro de iTerm**:
   ```sh
   printf '%b\n' 'carpeta: \Uf024b  archivo: \Uf0224  rust: \Ue7a8'
   ```
   Si se ven los 3 iconos, yazi va a mostrar iconos. Si se ven cuadros vacíos: la fuente del
   perfil no es la NF (volver al punto 2).
5. Opcional — previews de imagen nativos: yazi detecta el protocolo inline de iTerm2 solo;
   comprobarlo con `yazi --debug | grep -A2 Adapter` **dentro de iTerm** (debe decir
   `Adapter.matches: Iterm2`, no `Chafa`).

### Paso 3 — Los dos scripts

Copiar desde el repo a `~/bin` (crear el directorio si no existe):

```sh
mkdir -p ~/bin
cp macos/iterm-yazi/yazi-desktop.sh macos/iterm-yazi/yazi-desktop.js ~/bin/
chmod +x ~/bin/yazi-desktop.sh
```

Qué hace cada uno:

```text
~/bin/yazi-desktop.sh   wrapper zsh. Lee el id de ventana guardado en
                        ~/.cache/yazi-desktop-window, llama al .js pasándoselo,
                        y guarda el id que el .js imprime. Si falla, borra el estado.

~/bin/yazi-desktop.js   JXA (JavaScript for Automation). Toda la lógica:
                        singleton, reuso en arranque en frío y maximizado real.
```

Lógica del `.js`, en orden:

```text
1. ¿iTerm no está corriendo?  -> iTerm.launch() y esperar a que haya ventana
                                 (launch, NO activate: menos ventanas espurias)
2. ¿el id guardado sigue vivo? -> activate + window.select() + maximizar. FIN.
3. ¿arranque en frío?          -> reutilizar la ventana que iTerm abre al lanzarse,
                                 pero SOLO si es un shell inactivo (ver abajo);
                                 se le escribe: cd ~/Desktop && exec yazi
4. si no hay nada reutilizable -> create window with default profile command
                                 "/bin/zsh -lc 'cd ~/Desktop && exec yazi'"
5. imprimir el id de la ventana usada (lo persiste el wrapper)
```

"Shell inactivo" = la ventana tiene 1 tab y 1 sesión, y en su tty no corre nada más que
`login`/`zsh`/`bash` (se comprueba con `ps -t <tty> -o comm=`). Así nunca se le inyecta
texto a una sesión donde el humano tenía trabajo.

Maximizado = se le asignan a la ventana los `bounds` del `visibleFrame` de la pantalla que la
contiene (excluye menu bar y Dock). **No** es `⌃⌘F` / fullscreen de macOS: sigue siendo una
ventana normal, en el mismo Space, con barra de título.

Probar el script solo, antes del hotkey:

```sh
~/bin/yazi-desktop.sh; echo "rc=$?"      # debe abrir yazi maximizado en ~/Desktop
```

### Paso 4 — Ajustar el path si el usuario no es el mismo

`karabiner-rule.json` trae el path absoluto `/Users/andressierra/bin/yazi-desktop.sh`.
Karabiner **no** expande `~` de forma confiable en `shell_command`, así que hay que dejar el
absoluto correcto del usuario destino (`$HOME/bin/yazi-desktop.sh`). El comando del paso 5 ya
lo genera con el `$HOME` real.

### Paso 5 — Regla de Karabiner (⌥⌘E)

Karabiner recarga `karabiner.json` solo al detectar el cambio; no hay que reiniciar nada.
El comando hace backup, **prepone** la regla y preserva las que ya existan (p. ej. "Disable
Command+Q"). Validá con `jq -e` antes de mover el archivo — un JSON roto deja el teclado sin
las modificaciones:

```sh
cd ~/.config/karabiner
cp karabiner.json "automatic_backups/karabiner-pre-yazi-hotkey.json"

jq --arg cmd "$HOME/bin/yazi-desktop.sh" '
  .profiles[0].complex_modifications.rules = ([{
    "description": "Option+Command+E -> iTerm con yazi en ~/Desktop",
    "manipulators": [{
      "type": "basic",
      "from": {
        "key_code": "e",
        "modifiers": { "mandatory": ["command", "option"], "optional": ["caps_lock"] }
      },
      "to": [ { "shell_command": $cmd } ]
    }]
  }] + .profiles[0].complex_modifications.rules)' karabiner.json > /tmp/kb.json

jq -e '.profiles[0].complex_modifications.rules | length >= 1' /tmp/kb.json \
  && mv /tmp/kb.json karabiner.json

jq -r '.profiles[0].complex_modifications.rules[].description' karabiner.json
```

`"optional": ["caps_lock"]` evita que el atajo falle con Bloq Mayús activo.

Si el perfil activo no es `profiles[0]`, apuntar al índice correcto:
`jq -r '.profiles | to_entries[] | "\(.key) \(.value.name) selected=\(.value.selected)"'`.

### Paso 6 — Permiso de Automatización (paso manual, una vez)

La **primera** pulsación de ⌥⌘E hace que macOS pregunte si
`karabiner_console_user_server` puede controlar **iTerm**. Hay que darle **Permitir**; si no,
el hotkey no hace nada silenciosamente. Si se negó por error:
System Settings > Privacy & Security > **Automation** > karabiner_console_user_server > iTerm ✓.

### Paso 7 — Abrir una terminal desde yazi (tecla `T`)

Problema: si dentro de yazi usás `:` (shell bloqueante) y escribís `zsh`, yazi queda
"congelado" detrás de ese shell. Lo que se quiere es una **terminal aparte**, con yazi vivo.

En Linux se lanza el emulador por CLI (`kitty`, `ghostty`, `wezterm`…). **iTerm2 no tiene
binario CLI**, pero está registrado como handler de carpetas, así que el equivalente exacto es:

```sh
open -a iTerm "<dir>"      # ventana nueva de iTerm con cwd en <dir>
```

```text
open -a iTerm <dir>    ventana nueva en la MISMA instancia de iTerm   <- lo que queremos
open -na iTerm <dir>   INSTANCIA nueva de la app (duplica el proceso) <- no usar
```

1. Copiar el script (no necesita argumentos: usa el cwd con el que yazi lo lanza):
   ```sh
   cp macos/iterm-yazi/iterm-here.sh ~/bin/ && chmod +x ~/bin/iterm-here.sh
   ```
2. Copiar el keymap de yazi:
   ```sh
   mkdir -p ~/.config/yazi
   cp macos/iterm-yazi/keymap.toml ~/.config/yazi/keymap.toml
   ```
   Contenido:
   ```toml
   [[mgr.prepend_keymap]]
   on   = "T"          # Shift+t
   run  = 'shell --orphan "$HOME/bin/iterm-here.sh"'
   desc = "Abrir iTerm (ventana nueva) en el directorio actual"

   [[mgr.prepend_keymap]]
   on   = "<C-t>"      # alias, para no depender del shift
   run  = 'shell --orphan "$HOME/bin/iterm-here.sh"'
   desc = "Abrir iTerm (ventana nueva) en el directorio actual"
   ```
3. Detalles que importan:
   - **`[mgr]`, no `[manager]`**: la sección se renombró en yazi 25.x. Con `[manager]` en
     yazi 26 el keymap no aplica (o avisa de config obsoleta).
   - `prepend_keymap` se suma al preset y gana sobre el default. `T` y `<C-t>` están
     **libres** en el preset de 26.5.6 (verificado contra
     `yazi-config/preset/keymap-default.toml`); si en una versión futura se ocupan, esta
     regla los pisa igual.
   - **La tecla es `T` mayúscula (Shift+t)**. La `t` minúscula es un *prefijo* del preset
     (`t t` = new tab, `t r`), así que pulsar `t` solo muestra el menú de tabs: es el error
     más fácil de cometer. Por eso también se bindea `<C-t>`.
   - yazi lee el keymap **al arrancar**: después de editarlo hay que salir (`q`) y reabrir.
   - `--orphan` desacopla el proceso: yazi no espera nada. (`--block` haría lo contrario.)
   - yazi lanza el comando **con cwd = el directorio que estás viendo**, por eso el script
     no recibe argumentos y usa `$PWD`.
   - No hace falta permiso de Automatización acá: `open` no es AppleScript.
4. Verificar: abrir yazi (⌥⌘E), navegar a cualquier carpeta, pulsar `T`. Debe aparecer una
   ventana nueva de iTerm con el prompt **en esa carpeta**, y yazi seguir vivo en su ventana.

### Paso 8 — Verificación

Casos que hay que probar:

```text
CASO                                        ESPERADO                              ESTADO
──────────────────────────────────────────  ────────────────────────────────────  ──────────
pulsar ⌥⌘E 3 veces seguidas                 1 ventana, 1 proceso yazi             verificado
cerrar la ventana y volver a pulsar         crea una nueva, sigue habiendo 1      verificado
cerrar la ventana y pulsar al instante      sin error (refs muertas toleradas)    verificado
iTerm cerrado del todo (arranque en frío)   1 ventana con yazi, sin fantasma      verificado
salir de yazi con q                         la ventana se cierra sola             verificado
pulsar Shift+T dentro de yazi               ventana nueva con cwd = dir de yazi,  verificado
                                            yazi sigue vivo
pulsar Ctrl+T dentro de yazi                idem                                  verificado
navegar (gh) y pulsar T                     la ventana nueva abre en el nuevo cwd verificado
ventana movida a otro monitor + ⌥⌘E         se maximiza en ESE monitor            sin probar
                                                                                  (1 pantalla)
```

Comandos útiles para chequear headless:

```sh
# ventanas de iTerm abiertas
osascript -l JavaScript -e 'const a=Application("iTerm"); JSON.stringify(a.windows().map(w=>w.id()))'
# procesos yazi y RAM
ps -Ao rss,comm | awk '/yazi/{s+=$1;n++} END{printf "yazi procs=%d %.0fMB\n", n, s/1024}'
# estado del singleton
cat ~/.cache/yazi-desktop-window
```

### Por qué el singleton (datos medidos, MacBook Air)

```text
proceso yazi                ~20 MB RSS cada uno
overhead de iTerm/ventana   ~12 MB RSS cada una
                            ───────────────────
por ventana olvidada        ~32 MB   -> 10 ventanas ≈ 320 MB
```

No es catastrófico, pero acumula y ensucia el ⌥⇥. Con el singleton no hay ventanas olvidadas.

### Decisiones (por qué así y no de otra forma)

```text
⌥⌘E y no ⌘E        ⌘E está tomado: IntelliJ/PyCharm (Recent Files), VS Code, Sublime,
                    Finder (Eject). Capturarlo global rompe esas apps.
Karabiner y no      Karabiner es 100% scripteable (karabiner.json) y global. El hotkey de
Raycast/skhd        Raycast se asigna a mano por UI; skhd sería una dependencia más.
maximizar por       Rectangle/UI no son scripteables cómodamente; asignar bounds =
bounds              visibleFrame es exacto y no entra en fullscreen de macOS.
zsh -lc + exec      -l carga el .zshrc del usuario (PATH, config de yazi, EDITOR);
                    exec reemplaza el shell -> al salir de yazi la ventana se cierra.
```

### Gotchas encontrados (ahorran horas)

```text
window.frontmost = true       falla en iTerm ("Apple Event handler error"). Usar
                              window.select() para traer al frente.
iTerm.activate() en frío      abre una ventana extra. launch() + reuso de la ventana
                              inactiva evita la ventana fantasma.
refs de ventana muertas       w.id() lanza excepción si la ventana se está cerrando;
                              hay que iterar con try/catch por ventana (findWindow()).
coordenadas invertidas        bounds de AppleScript = origen arriba-izquierda de la
                              pantalla principal; NSScreen = abajo-izquierda.
                              y_bounds = alturaPrimaria - (vis.origin.y + vis.size.height)
multi-monitor                 elegir la pantalla por el centro de la ventana
                              (NSPointInRect), no mainScreen a ciegas.
yazi [manager] vs [mgr]       en yazi >= 25 la seccion del keymap es [mgr]; con
                              [manager] el binding no aplica.
open -na iTerm                crea otra INSTANCIA de la app. Para "otra ventana"
                              es open -a iTerm <dir> (sin -n).
```

### Extra opcional — `y` en el shell (cd al salir de yazi)

Mismo helper que en `linux/bitacora.md`, para `~/.zshrc`:

```sh
y() {
    local tmp; tmp=$(mktemp -t yazi-cwd.XXXXXX)
    yazi "$@" --cwd-file="$tmp"
    local cwd; cwd=$(cat -- "$tmp" 2>/dev/null)
    [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd -- "$cwd"
    rm -f -- "$tmp"
}
```

### Revertir

```sh
rm -f ~/bin/yazi-desktop.sh ~/bin/yazi-desktop.js ~/bin/iterm-here.sh \
      ~/.cache/yazi-desktop-window ~/.config/yazi/keymap.toml
cp ~/.config/karabiner/automatic_backups/karabiner-pre-yazi-hotkey.json \
   ~/.config/karabiner/karabiner.json
```

### Archivos que toca esta implementación

```text
NUEVOS
~/bin/yazi-desktop.sh                 wrapper + estado (chmod +x)
~/bin/yazi-desktop.js                 lógica JXA
~/bin/iterm-here.sh                   terminal nueva en el cwd (chmod +x)
~/.config/yazi/keymap.toml            teclas T / Ctrl+T -> iterm-here.sh

MODIFICADO
~/.config/karabiner/karabiner.json    regla ⌥⌘E prepuesta

BACKUP
~/.config/karabiner/automatic_backups/karabiner-pre-yazi-hotkey.json

RUNTIME (se recrea solo, no versionar)
~/.cache/yazi-desktop-window          id de la ventana actual de yazi

NO SE TOCA
.zshrc, preferencias de iTerm (salvo la fuente del paso 2), LaunchAgents
```
