# macOS — iTerm + yazi con hotkey global (⌥⌘E)

Explorador de archivos por teclado en macOS: **iTerm2 + yazi**, disparado con un hotkey
global, siempre **una sola ventana**, **maximizada** (no pantalla completa de macOS) y
abriendo en **~/Desktop**. Equivalente macOS del `Super+E` de `linux/bitacora.md`.

## Para el humano

```text
ATAJO GLOBAL   ⌥⌘E  (Option + Command + E)
QUÉ HACE       abre iTerm con yazi en ~/Desktop, ventana maximizada
SI YA ESTÁ     no abre otra: trae al frente la misma ventana y la re-maximiza
AL SALIR (q)   la ventana se cierra sola; el siguiente ⌥⌘E abre una limpia
ICONOS         los da la fuente Nerd Font del perfil de iTerm (no un plugin de yazi)

DENTRO DE YAZI
Shift+T        abre una ventana NUEVA de iTerm en el directorio donde estás,
Ctrl+T         sin cerrar ni bloquear yazi. Las dos teclas hacen lo mismo.
               OJO: la "t" minúscula NO es esto — es el prefijo de tabs del
               preset de yazi (t t = new tab).
;              shell de yazi (espera a que termine el comando)
:              shell de yazi bloqueante (el que se usaba para meterle "zsh")
```

### Para replicar en un mac nuevo
Compartí este archivo con Claude Code (o cualquier IA con acceso a shell) y pedile:
*"implementá la sección **Para la IA** de este spec en este mac"*. Todo lo scripteable lo
hace `iterm-yazi/install.sh`; lo manual está listado explícitamente.

---

# Para la IA — leé esto antes de tocar nada

Este spec es autocontenido: **no necesitás nada de la conversación en la que se creó.**

## Qué vas a dejar instalado

```text
1. Hotkey global ⌥⌘E (Karabiner-Elements) -> ~/bin/yazi-desktop.sh
2. ~/bin/yazi-desktop.js  logica JXA: ventana unica (singleton), maximizado real,
                          arranque en frio sin ventanas fantasma
3. ~/bin/iterm-here.sh    abre otra ventana de iTerm en un directorio dado
4. ~/.config/yazi/keymap.toml  Shift+T / Ctrl+T -> iterm-here.sh (terminal aqui)
5. Fuente Nerd Font en el perfil de iTerm -> iconos en yazi
```

## Entorno donde se construyó y verificó

```text
fecha            2026-07-30
macOS            Darwin 25.5.0 (Apple Silicon, arm64)
Homebrew         /opt/homebrew
shell            /bin/zsh  (el default de macOS; los scripts son zsh)
yazi             26.5.6 (Homebrew)
iTerm2           instalado en ~/Applications/iTerm.app (funciona igual en /Applications)
Karabiner        Karabiner-Elements (con una regla previa "Disable Command+Q" que se preservó)
fuente iTerm     CascadiaCodeNF-Regular 18
pantallas        1 (el caso multi-monitor está implementado pero NO verificado)
```

Si el mac destino difiere (Intel: `/usr/local` en vez de `/opt/homebrew`; otro shell por
defecto; yazi < 25), ajustá lo señalado en cada paso — el resto aplica igual.

## Dónde están los archivos

Los 5 archivos viven **junto a este spec**, en el subdirectorio `iterm-yazi/`:

```text
<dir-de-este-spec>/iterm-yazi/
├── install.sh          instalador idempotente (hace los pasos 3, 4 y 6)
├── yazi-desktop.sh     wrapper del hotkey
├── yazi-desktop.js     lógica JXA
├── iterm-here.sh       "abrir terminal aquí" para yazi
├── keymap.toml         keymap de yazi (T / Ctrl+T)
└── karabiner-rule.json la regla, solo como referencia legible
```

Repo: `git@github.com:andysierra/env-dev.git`, típicamente clonado en
`~/Desktop/DEV/env-dev` (este spec es `macos/spec-iterm-yazi-hotkey.md`).

**Si NO tenés el repo a mano**: el contenido íntegro de los 4 archivos que se instalan está
en el **Anexo A** al final. Creálos con ese contenido exacto y seguí el camino manual.

## Reglas duras (no las cambies sin decírselo al humano)

```text
1. NO uses ⌘E a secas para el hotkey global: lo usan IntelliJ/PyCharm (Recent Files),
   VS Code, Sublime y Finder (Eject). El atajo es ⌥⌘E.
2. En el keymap de yazi la sección es [mgr], NO [manager] (renombrada en yazi 25).
3. La tecla de "terminal aquí" es T MAYÚSCULA (Shift+t); la t minúscula es un prefijo
   del preset. Por eso hay alias <C-t>.
4. Para abrir otra ventana de iTerm: `open -a iTerm <dir>`. NUNCA `open -na` (eso crea
   otra INSTANCIA de la app).
5. Antes de escribir karabiner.json: validá el JSON con `jq -e`. Un archivo roto deja el
   teclado sin ninguna modificación de Karabiner.
6. Siempre backup de karabiner.json antes de tocarlo.
7. "Maximizado" = bounds del visibleFrame de la pantalla. NO es fullscreen de macOS
   (⌃⌘F): el humano lo pidió explícitamente así.
```

## Camino rápido (recomendado)

```sh
SPEC_DIR="<dir-donde-está-este-spec>"          # p.ej. ~/Desktop/DEV/env-dev/macos
zsh "$SPEC_DIR/iterm-yazi/install.sh" --dry-run   # muestra qué haría, no escribe
zsh "$SPEC_DIR/iterm-yazi/install.sh"             # aplica
```

`install.sh` es **idempotente** (correrlo dos veces deja el mismo resultado; verificado):
chequea dependencias, copia los 3 scripts a `~/bin`, instala/anexa el keymap de yazi
(si ya había uno propio lo respalda y **anexa** en vez de sobreescribir), y reemplaza la
regla de Karabiner por description (respetando las demás reglas) con backup timestampeado.
Detecta solo el índice del perfil activo de Karabiner.

**Lo que `install.sh` NO puede hacer** (imprime el recordatorio al final):
- instalar software (paso 1),
- poner la Nerd Font en el perfil de iTerm (paso 2) — solo avisa si no la detecta,
- habilitar la extensión de Karabiner ni aceptar el permiso de Automatización (paso 5).

Después de correrlo, salta al **paso 7 (verificación)**.

---

# Camino manual, paso a paso

### Paso 0 — Preflight: mirá con qué te encontrás

Primero fijá `SPEC_DIR` = el directorio donde está **este** archivo (los pasos 3 y 6 lo usan):

```sh
SPEC_DIR="$HOME/Desktop/DEV/env-dev/macos"        # ajustá si el repo está en otro lado
ls "$SPEC_DIR/iterm-yazi/"                        # deben aparecer los 6 archivos
```

Y mirá el estado del mac:

```sh
uname -m; sw_vers -productVersion; echo "shell=$SHELL"; brew --prefix 2>/dev/null
command -v yazi jq
ls -d /Applications/iTerm.app ~/Applications/iTerm.app 2>/dev/null
ls -d /Applications/Karabiner-Elements.app 2>/dev/null
ls ~/.config/karabiner/karabiner.json 2>/dev/null
ls ~/.config/yazi/ 2>/dev/null                  # ¿ya hay keymap propio del usuario?
/usr/libexec/PlistBuddy -c "Print :'New Bookmarks':0:'Normal Font'" \
  ~/Library/Preferences/com.googlecode.iterm2.plist 2>/dev/null
```

Si ya existe `~/.config/yazi/keymap.toml` con bindings del usuario, **no lo sobreescribas**:
anexá los dos bloques del paso 6 y avisá.

### Paso 1 — Software

```sh
# Homebrew (si el mac es nuevo)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Núcleo (jq es obligatorio: se usa para editar karabiner.json)
brew install yazi jq
brew install --cask iterm2 karabiner-elements

# Fuente con iconos (Nerd Font). Esta es la que se usa acá:
brew install --cask font-cascadia-code-nf

# Opcionales de yazi (previews: imágenes, PDF, video, zip, búsqueda)
brew install ffmpeg sevenzip poppler fd ripgrep fzf zoxide imagemagick resvg
```

Verificar:

```sh
yazi --version && jq --version
ls -d /Applications/iTerm.app ~/Applications/iTerm.app 2>/dev/null   # cualquiera de las dos sirve
ls -d /Applications/Karabiner-Elements.app
```

Karabiner-Elements pide, **la primera vez y a mano**, habilitar su extensión de sistema y
"Input Monitoring" (System Settings > Privacy & Security). Abrilo una vez y seguí su
asistente; sin eso no hay hotkeys, y `~/.config/karabiner/karabiner.json` no existe todavía.

### Paso 2 — Iconos de yazi en iTerm (Nerd Font)

Entendé esto antes de tocar nada: **yazi no necesita configuración para los iconos**. Su set
de iconos por defecto viene compilado en el binario y usa codepoints de Nerd Font (mayormente
`nf-md-*`, o sea Material Design Icons). Si se ven cuadritos o `?`, el problema es **la fuente
del perfil de iTerm**, nunca yazi. En el mac de referencia no existe `theme.toml` ni ningún
plugin de iconos, y los iconos se ven perfectos.

1. Instalar la Nerd Font (paso 1) y confirmar:
   ```sh
   ls ~/Library/Fonts | grep -i cascadiacodenf     # CascadiaCodeNF.ttf, CascadiaCodeNFItalic.ttf
   ```
2. iTerm2 > Settings (⌘,) > **Profiles** > perfil por defecto > **Text**:
   - **Font**: `CascadiaCodeNF-Regular` (en el selector aparece como "Cascadia Code NF"),
     tamaño 18.
   - **Use a different font for non-ASCII text**: **desactivado**. Si se activa, los glifos de
     iconos se dibujan con la fuente non-ASCII y se rompen.
3. Verificar sin abrir la UI (lee las prefs reales de iTerm):
   ```sh
   /usr/libexec/PlistBuddy -c "Print :'New Bookmarks':0:'Normal Font'" \
     ~/Library/Preferences/com.googlecode.iterm2.plist
   # esperado: CascadiaCodeNF-Regular 18
   /usr/libexec/PlistBuddy -c "Print :'New Bookmarks':0:'Use Non ASCII Font'" \
     ~/Library/Preferences/com.googlecode.iterm2.plist
   # esperado: false, o "Does Not Exist" (= default false)
   ```
   Alternativa scripteada (**no verificada** en el mac de referencia; hacela solo con **iTerm
   cerrado**, porque iTerm reescribe sus prefs al salir):
   ```sh
   /usr/libexec/PlistBuddy -c "Set :'New Bookmarks':0:'Normal Font' 'CascadiaCodeNF-Regular 18'" \
     ~/Library/Preferences/com.googlecode.iterm2.plist
   ```
   Preferí la UI: es la vía segura.
4. Test de glifos, **corriendo dentro de iTerm**:
   ```sh
   printf '%b\n' 'carpeta: \Uf024b  archivo: \Uf0224  rust: \Ue7a8'
   ```
   Si se ven los 3 iconos, yazi va a mostrar iconos. Si se ven cuadros vacíos: la fuente del
   perfil no es la NF (volvé al punto 2).
5. Opcional — previews de imagen nativos: yazi detecta el protocolo inline de iTerm2 solo.
   Comprobalo **dentro de iTerm** con `yazi --debug | grep -A2 Adapter`: debe decir
   `Adapter.matches: Iterm2` (en Terminal.app dice `Chafa`).

### Paso 3 — Scripts en ~/bin

```sh
mkdir -p ~/bin
cp "$SPEC_DIR"/iterm-yazi/{yazi-desktop.sh,yazi-desktop.js,iterm-here.sh} ~/bin/
chmod +x ~/bin/yazi-desktop.sh ~/bin/iterm-here.sh
```

(Sin el repo: creá los 3 con el contenido del **Anexo A**.) No hace falta que `~/bin` esté en
el PATH: todo se invoca por ruta absoluta.

Qué hace cada uno:

```text
~/bin/yazi-desktop.sh   wrapper zsh. Lee el id de ventana guardado en
                        ~/.cache/yazi-desktop-window, llama al .js pasándoselo,
                        y guarda el id que el .js imprime. Si falla, borra el estado.

~/bin/yazi-desktop.js   JXA (JavaScript for Automation). Toda la lógica:
                        singleton, reuso en arranque en frío y maximizado real.

~/bin/iterm-here.sh     open -a iTerm "${1:-$PWD}" (con fallback a la carpeta si le
                        pasan un archivo). Lo usa el keymap de yazi.
```

Lógica del `.js`, en orden:

```text
1. ¿iTerm no está corriendo?   -> iTerm.launch() y esperar a que haya ventana
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
`login`/`zsh`/`bash` (se comprueba con `ps -t <tty> -o comm=`). Así nunca se le inyecta texto
a una sesión donde el humano tenía trabajo.

Maximizado = se le asignan a la ventana los `bounds` del `visibleFrame` de la pantalla que la
contiene (excluye menu bar y Dock). **No** es `⌃⌘F` / fullscreen de macOS: sigue siendo una
ventana normal, en el mismo Space, con barra de título.

Probalo solo, antes del hotkey:

```sh
~/bin/yazi-desktop.sh; echo "rc=$?"      # debe abrir yazi maximizado en ~/Desktop
```

Si el usuario destino no es `andressierra`, no hay nada que editar en los scripts: usan
`$HOME`. El único path absoluto es el de la regla de Karabiner (paso 4), que se genera con el
`$HOME` real.

### Paso 4 — Regla de Karabiner (⌥⌘E)

Karabiner recarga `karabiner.json` al detectar el cambio; no hay que reiniciar nada. El
bloque de abajo: detecta el **perfil activo** (no asume `profiles[0]`), hace backup,
**reemplaza** la regla con la misma `description` (idempotente) y **preserva** las demás:

```sh
KB=~/.config/karabiner/karabiner.json
DESC="Option+Command+E -> iTerm con yazi en ~/Desktop"
IDX=$(jq '[.profiles[].selected] | index(true) // 0' "$KB")
cp "$KB" ~/.config/karabiner/automatic_backups/karabiner-pre-yazi-hotkey-$(date +%Y%m%d-%H%M%S).json

jq --argjson i "$IDX" --arg cmd "$HOME/bin/yazi-desktop.sh" --arg desc "$DESC" '
  .profiles[$i].complex_modifications.rules = ([{
    "description": $desc,
    "manipulators": [{
      "type": "basic",
      "from": {
        "key_code": "e",
        "modifiers": { "mandatory": ["command", "option"], "optional": ["caps_lock"] }
      },
      "to": [ { "shell_command": $cmd } ]
    }]
  }] + (.profiles[$i].complex_modifications.rules | map(select(.description != $desc))))
' "$KB" > /tmp/kb.json

# validar ANTES de escribir
jq -e --argjson i "$IDX" --arg desc "$DESC" \
  '.profiles[$i].complex_modifications.rules[0].description == $desc' /tmp/kb.json \
  && mv /tmp/kb.json "$KB"

jq -r --argjson i "$IDX" '.profiles[$i].complex_modifications.rules[].description' "$KB"
```

Notas:
- `"optional": ["caps_lock"]` evita que el atajo falle con Bloq Mayús activo.
- Karabiner **no** expande `~` de forma confiable en `shell_command`: por eso el path
  absoluto vía `$HOME`.
- `iterm-yazi/karabiner-rule.json` es la misma regla suelta, para leerla o pegarla a mano.

### Paso 5 — Permiso de Automatización (manual, una vez)

La **primera** pulsación de ⌥⌘E hace que macOS pregunte si `karabiner_console_user_server`
puede controlar **iTerm**. Hay que darle **Permitir**; si no, el hotkey no hace nada, y sin
mensaje de error. Si se negó por error:
System Settings > Privacy & Security > **Automation** > karabiner_console_user_server > iTerm ✓.

(El paso 6 no necesita este permiso: `open` no es AppleScript.)

### Paso 6 — Abrir una terminal desde yazi (Shift+T / Ctrl+T)

Problema que resuelve: si dentro de yazi usás `:` (shell bloqueante) y escribís `zsh`, yazi
queda "congelado" detrás de ese shell. Lo que se quiere es una **terminal aparte**, con yazi
vivo.

En Linux se lanza el emulador por CLI (`kitty`, `ghostty`, `wezterm`…). **iTerm2 no tiene
binario CLI**, pero está registrado como handler de carpetas, así que el equivalente exacto es:

```text
open -a iTerm <dir>    ventana nueva en la MISMA instancia de iTerm   <- lo que queremos
open -na iTerm <dir>   INSTANCIA nueva de la app (duplica el proceso) <- no usar
```

```sh
mkdir -p ~/.config/yazi
cp "$SPEC_DIR/iterm-yazi/keymap.toml" ~/.config/yazi/keymap.toml   # ver Paso 0 si ya existía
```

Contenido relevante:

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

Detalles que importan:
- **`[mgr]`, no `[manager]`**: la sección se renombró en yazi 25.x. Con `[manager]` en yazi 26
  el binding no aplica. (Muchas respuestas de IA todavía dicen `[manager]`.)
- `prepend_keymap` se suma al preset y gana sobre el default. `T` y `<C-t>` están **libres** en
  el preset de 26.5.6 (verificado contra `yazi-config/preset/keymap-default.toml` del tag); si
  en una versión futura se ocupan, esta regla los pisa igual.
- **La tecla es `T` mayúscula (Shift+t)**. La `t` minúscula es un *prefijo* del preset
  (`t t` = new tab, `t r` = ...), así que pulsar `t` solo muestra el menú de tabs: es el error
  más fácil de cometer, y parece que el binding no funciona. Por eso el alias `<C-t>`.
- yazi lee el keymap **al arrancar**: después de editarlo hay que salir (`q`) y reabrir.
- `--orphan` desacopla el proceso: yazi no espera nada (`--block` haría lo contrario).
- yazi lanza el comando **con cwd = el directorio que estás viendo**, por eso el script no
  recibe argumentos y usa `$PWD`.

### Paso 7 — Verificación

```text
CASO                                        ESPERADO                              ESTADO
──────────────────────────────────────────  ────────────────────────────────────  ──────────
pulsar ⌥⌘E 3 veces seguidas                 1 ventana, 1 proceso yazi             verificado
cerrar la ventana y volver a pulsar         crea una nueva, sigue habiendo 1      verificado
cerrar la ventana y pulsar al instante      sin error (refs muertas toleradas)    verificado
iTerm cerrado del todo (arranque en frío)   1 ventana con yazi, sin fantasma      verificado
salir de yazi con q                         la ventana se cierra sola             verificado
Shift+T dentro de yazi                      ventana nueva con cwd = dir de yazi,  verificado
                                            yazi sigue vivo
Ctrl+T dentro de yazi                       idem                                  verificado
navegar (gh) y pulsar Shift+T               abre en el nuevo cwd                   verificado
correr install.sh dos veces                 karabiner.json idéntico (idempotente) verificado
ventana movida a otro monitor + ⌥⌘E         se maximiza en ESE monitor            sin probar
                                                                                  (1 pantalla)
```

Comandos para chequear sin interfaz gráfica (útiles para una IA):

```sh
# ventanas de iTerm abiertas
osascript -l JavaScript -e 'const a=Application("iTerm"); JSON.stringify(a.windows().map(w=>w.id()))'
# procesos yazi y RAM
ps -Ao rss,comm | awk '/yazi/{s+=$1;n++} END{printf "yazi procs=%d %.0fMB\n", n, s/1024}'
# estado del singleton
cat ~/.cache/yazi-desktop-window
# ¿el keymap se carga?  (debe listar la ruta y el tamaño, sin error)
yazi --debug | grep -i Keymap
# cwd real de la ventana nueva (tty visible en iTerm > Session > ...)
p=$(ps -t ttysNNN -o pid=,comm= | awk '$2 ~ /zsh/ {print $1; exit}'); lsof -a -p $p -d cwd -Fn | tail -1
```

Truco para probar teclas de yazi sin manos (así se verificó `T` y `<C-t>`): escribirle la
tecla a la sesión de iTerm donde corre yazi.

```sh
osascript -l JavaScript -e '
  const a=Application("iTerm");
  const w=a.windows()[0];                       // la ventana donde corre yazi
  w.currentTab.currentSession.write({text:"T", newline:false});'   // Ctrl+T: String.fromCharCode(20)
```

## Troubleshooting

```text
SÍNTOMA                          CAUSA / ARREGLO
───────────────────────────────  ─────────────────────────────────────────────────────
⌥⌘E no hace nada                 (a) falta el permiso de Automatización (paso 5)
                                 (b) Karabiner sin extensión/Input Monitoring habilitado
                                 (c) la regla quedó en un perfil que no es el activo:
                                     revisá con jq '[.profiles[].selected]'
                                 (d) probá el script solo: ~/bin/yazi-desktop.sh
yazi muestra cuadritos           la fuente del perfil de iTerm no es Nerd Font (paso 2)
o signos de pregunta             o está activo "Use a different font for non-ASCII text"
Shift+T no abre nada             (a) pulsaste "t" minúscula (menú de tabs) -> es Shift+T
                                 (b) yazi estaba abierto desde antes de crear el keymap:
                                     salí con q y reabrí (lee el keymap al arrancar)
                                 (c) usaste [manager] en vez de [mgr]
se abren VARIAS ventanas         se borró ~/.cache/yazi-desktop-window, o abriste yazi
de yazi                          por fuera del hotkey; el singleton solo rastrea la suya
la ventana no se maximiza        otra app (Rectangle/Magnet) la está reposicionando;
                                 o el usuario la movió y el bounds se recalculó en la
                                 pantalla equivocada (revisá screenOf())
"Apple Event handler error"      no uses window.frontmost = true; usá window.select()
karabiner.json quedó roto        restaurá desde ~/.config/karabiner/automatic_backups/
                                 (Karabiner también guarda backups propios ahí)
```

## Por qué el singleton (datos medidos, MacBook Air)

```text
proceso yazi                ~20 MB RSS cada uno
overhead de iTerm/ventana   ~12 MB RSS cada una
                            ───────────────────
por ventana olvidada        ~32 MB   -> 10 ventanas ≈ 320 MB
```

No es catastrófico, pero acumula y ensucia el ⌥⇥. Con el singleton no hay ventanas olvidadas.

## Decisiones (por qué así y no de otra forma)

```text
⌥⌘E y no ⌘E         ⌘E está tomado: IntelliJ/PyCharm (Recent Files), VS Code, Sublime,
                    Finder (Eject). Capturarlo global rompe esas apps.
Karabiner y no      Karabiner es 100% scripteable (karabiner.json) y global. El hotkey de
Raycast/skhd        Raycast se asigna a mano por UI; skhd sería una dependencia más.
maximizar por       Rectangle/UI no son scripteables cómodamente; asignar bounds =
bounds              visibleFrame es exacto y no entra en fullscreen de macOS.
zsh -lc + exec      -l carga el .zshrc del usuario (PATH, config de yazi, EDITOR);
                    exec reemplaza el shell -> al salir de yazi la ventana se cierra.
JXA y no AppleScript  se necesita NSScreen (visibleFrame) vía ObjC bridge; en AppleScript
                    puro no hay forma limpia de obtenerlo.
```

## Gotchas encontrados (ahorran horas)

```text
window.frontmost = true       falla en iTerm ("Apple Event handler error"). Usar
                              window.select() para traer al frente.
iTerm.activate() en frío      abre una ventana extra. launch() + reuso de la ventana
                              inactiva evita la ventana fantasma.
refs de ventana muertas       w.id() lanza excepción si la ventana se está cerrando;
                              hay que iterar con try/catch por ventana (findWindow()).
                              iTerm además reporta ventanas ya cerradas por un rato.
coordenadas invertidas        bounds de AppleScript = origen arriba-izquierda de la
                              pantalla principal; NSScreen = abajo-izquierda.
                              y_bounds = alturaPrimaria - (vis.origin.y + vis.size.height)
multi-monitor                 elegir la pantalla por el centro de la ventana
                              (NSPointInRect), no mainScreen a ciegas.
yazi [manager] vs [mgr]       en yazi >= 25 la sección del keymap es [mgr]; con
                              [manager] el binding no aplica.
open -na iTerm                crea otra INSTANCIA de la app. Para "otra ventana"
                              es open -a iTerm <dir> (sin -n).
```

## Extra opcional — `y` en el shell (cd al salir de yazi)

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

## Revertir

```sh
rm -f ~/bin/yazi-desktop.sh ~/bin/yazi-desktop.js ~/bin/iterm-here.sh \
      ~/.cache/yazi-desktop-window ~/.config/yazi/keymap.toml
# restaurar el karabiner.json previo (elegí el backup más viejo/correcto)
ls -t ~/.config/karabiner/automatic_backups/karabiner-pre-yazi-hotkey-*.json | tail -1
cp <ese-archivo> ~/.config/karabiner/karabiner.json
```

## Archivos que toca esta implementación

```text
NUEVOS
~/bin/yazi-desktop.sh                 wrapper + estado (chmod +x)
~/bin/yazi-desktop.js                 lógica JXA
~/bin/iterm-here.sh                   terminal nueva en el cwd (chmod +x)
~/.config/yazi/keymap.toml            teclas T / Ctrl+T -> iterm-here.sh

MODIFICADO
~/.config/karabiner/karabiner.json    regla ⌥⌘E prepuesta (las demás se preservan)
~/Library/Preferences/com.googlecode.iterm2.plist   solo la fuente del perfil (paso 2)

BACKUP
~/.config/karabiner/automatic_backups/karabiner-pre-yazi-hotkey-<timestamp>.json

RUNTIME (se recrea solo, no versionar)
~/.cache/yazi-desktop-window          id de la ventana actual de yazi

NO SE TOCA
.zshrc, LaunchAgents, el resto de las prefs de iTerm, la config de yazi (no hay theme
ni plugins: los iconos son del binario + la fuente)
```

---

# Anexo A — contenido íntegro de los archivos

Espejo de `iterm-yazi/*` al 2026-07-30, para poder aplicar el spec **sin el repo**. Si tenés
el repo, la fuente de verdad son los archivos de `iterm-yazi/`. **Mantenimiento: si cambiás
un script, actualizá también este anexo.**

**`yazi-desktop.sh`**

```zsh
#!/bin/zsh
# Hotkey global (Option+Command+E, via Karabiner-Elements):
# abre yazi en ~/Desktop, en iTerm, maximizado y SIEMPRE en la misma ventana.
# Si esa ventana ya existe, solo la trae al frente en vez de abrir otra.

STATE="$HOME/.cache/yazi-desktop-window"
mkdir -p "${STATE:h}"

known=$(cat "$STATE" 2>/dev/null)
id=$(/usr/bin/osascript -l JavaScript "$HOME/bin/yazi-desktop.js" "$known" 2>/dev/null)

if [[ "$id" == <-> ]]; then
  print -r -- "$id" > "$STATE"
else
  rm -f "$STATE"
  exit 1
fi
```

**`yazi-desktop.js`**

```javascript
// Lanzador de yazi en iTerm: UNA sola ventana (singleton), en ~/Desktop, maximizada.
// Uso: osascript -l JavaScript yazi-desktop.js [id-ventana-conocida]
// Imprime el id de la ventana usada (el wrapper .sh lo guarda como estado).

const CMD = "/bin/zsh -lc 'cd ~/Desktop && exec yazi'";
const SHELLS = ["login", "zsh", "-zsh", "bash", "-bash", "sh", "-sh"];

function run(argv) {
  ObjC.import('AppKit');
  const sh = Application.currentApplication();
  sh.includeStandardAdditions = true;

  const iTerm = Application('iTerm');
  const wanted = parseInt(argv[0], 10);
  const wasRunning = iTerm.running();

  if (!wasRunning) {
    iTerm.launch();                     // launch (no activate) para no forzar ventana extra
    for (let i = 0; i < 40 && iTerm.windows().length === 0; i++) delay(0.25);
  }

  // 1) Singleton: si la ventana de yazi sigue viva, solo traerla al frente.
  //    (todo en try/catch: la ventana puede estar cerrandose justo ahora)
  if (wasRunning && !isNaN(wanted)) {
    try {
      const known = findWindow(iTerm, w => w.id() === wanted);
      if (known) {
        iTerm.activate();
        known.select();
        maximize(known);
        return String(wanted);
      }
    } catch (e) { /* ventana muerta -> se crea una nueva abajo */ }
  }

  // 2) Arranque en frio: reutilizar la ventana que iTerm abre al lanzarse,
  //    pero solo si es un shell inactivo (nunca escribir sobre trabajo ajeno).
  let win = null;
  if (!wasRunning) {
    try {
      win = findWindow(iTerm, w => isIdleShellWindow(w, sh));
      if (win) win.currentTab.currentSession.write({ text: "cd ~/Desktop && exec yazi" });
    } catch (e) { win = null; }
  }

  // 3) Si no habia nada reutilizable, ventana nueva con yazi.
  if (!win) win = iTerm.createWindowWithDefaultProfile({ command: CMD });

  iTerm.activate();
  win.select();
  maximize(win);
  return String(win.id());
}

// Recorre las ventanas tolerando referencias muertas (ventanas cerrandose).
function findWindow(iTerm, pred) {
  let ws;
  try { ws = iTerm.windows(); } catch (e) { return null; }
  for (let i = 0; i < ws.length; i++) {
    try { if (pred(ws[i])) return ws[i]; } catch (e) { /* siguiente */ }
  }
  return null;
}

// Ventana de un solo shell en reposo: 1 tab, 1 sesion y ningun proceso
// aparte del shell/login corriendo en su tty.
function isIdleShellWindow(w, sh) {
  try {
    if (w.tabs().length !== 1) return false;
    const tab = w.tabs()[0];
    if (tab.sessions().length !== 1) return false;
    const tty = tab.sessions()[0].tty().replace("/dev/", "");
    const procs = sh.doShellScript("ps -t " + tty + " -o comm= 2>/dev/null")
      .split("\r").join("\n").split("\n")
      .map(s => s.trim()).filter(s => s.length);
    return procs.length > 0 && procs.every(p => SHELLS.indexOf(basename(p)) !== -1);
  } catch (e) {
    return false;
  }
}

function basename(p) {
  const parts = p.split("/");
  return parts[parts.length - 1];
}

// Maximizado real: ocupa el area visible (sin menu bar ni Dock) de la pantalla
// donde esta la ventana. No es pantalla completa de macOS.
function maximize(win) {
  const primaryHeight = $.NSScreen.screens.objectAtIndex(0).frame.size.height;
  const screen = screenOf(win, primaryHeight);
  const vis = screen.visibleFrame;
  win.bounds = {
    x: vis.origin.x,
    y: primaryHeight - (vis.origin.y + vis.size.height),
    width: vis.size.width,
    height: vis.size.height
  };
}

function screenOf(win, primaryHeight) {
  try {
    const b = win.bounds();
    // bounds de AppleScript: origen arriba-izquierda; NSScreen: abajo-izquierda.
    const center = $.NSMakePoint(b.x + b.width / 2, primaryHeight - (b.y + b.height / 2));
    const screens = $.NSScreen.screens;
    for (let i = 0; i < screens.count; i++) {
      const s = screens.objectAtIndex(i);
      if ($.NSPointInRect(center, s.frame)) return s;
    }
  } catch (e) { /* cae al default */ }
  return $.NSScreen.mainScreen;
}
```

**`iterm-here.sh`**

```zsh
#!/bin/zsh
# Abre una ventana NUEVA de iTerm con el shell en un directorio, sin bloquear
# a quien lo llama. Usado desde yazi (tecla T) para "abrir terminal aqui".
#
# Uso: iterm-here.sh [dir-o-archivo]    (por defecto: $PWD)
# iTerm2 esta registrado como handler de carpetas, asi que `open -a iTerm <dir>`
# abre ventana nueva con cwd en <dir>: no hace falta AppleScript ni permisos.

dir="${1:-$PWD}"
[[ -d "$dir" ]] || dir="${dir:h}"   # si es un archivo, usar su carpeta

exec /usr/bin/open -a iTerm "$dir"
```

**`keymap.toml`**

```toml
# yazi — keymap propio (se suma al preset; prepend gana sobre el default)
# Ver teclas ocupadas por defecto: https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/keymap-default.toml
# OJO: en yazi >= 25 la seccion es [mgr], no [manager] (renombrada).

# OJO 2: la tecla es "T" MAYUSCULA (shift+t). La "t" minuscula es el prefijo de
# tabs del preset (t t = new tab), por eso se agrega <C-t> como alias.

[[mgr.prepend_keymap]]
on   = "T"
run  = 'shell --orphan "$HOME/bin/iterm-here.sh"'
desc = "Abrir iTerm (ventana nueva) en el directorio actual"

[[mgr.prepend_keymap]]
on   = "<C-t>"
run  = 'shell --orphan "$HOME/bin/iterm-here.sh"'
desc = "Abrir iTerm (ventana nueva) en el directorio actual"
```
