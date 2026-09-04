# macOS — abrir `.drawio` con la PWA de draw.io (yazi + Finder)

Los archivos `.drawio` se abren en la **PWA de draw.io** (`app.diagrams.net` instalada como
app), tanto desde **yazi** (`Enter`) como desde **Finder** (doble clic). Mismo criterio que
`*.md` → Readdown: el visor bueno gana sobre el editor de texto.

## Para el humano

```text
EN YAZI      Enter sobre un *.drawio  -> PWA draw.io
             O (open interactivo)      -> menu: draw.io / editor / reveal
             *.drawio.png y *.drawio.svg tambien van a draw.io desde yazi
EN FINDER    doble clic en *.drawio    -> PWA draw.io
             (los .drawio.png / .drawio.svg NO se tocan: su UTI es png/svg y
              cambiarlo secuestraria TODOS los PNG/SVG del sistema)
REVERTIR     Finder > Obtener informacion de un .drawio > Abrir con > otra app
             > Cambiar todos
```

**Ojo con el navegador:** las PWAs de este mac (draw.io, ChatGPT, mermaid, PUML…) viven en
`~/Applications/Chromium Apps.localized/` y son shims de **Chromium**
(`~/devtools/chrome-mac/Chromium.app`), no de Edge — Edge no esta instalado y
`~/Applications/Edge Apps.localized/` esta vacio. Las de Google Chrome estan aparte, en
`~/Applications/Chrome Apps.localized/`.

### Para replicar en un mac nuevo
Compartí este archivo con Claude Code y pedile: *"implementá la sección **Para la IA** de
este spec en este mac"*.

---

# Para la IA — leé esto antes de tocar nada

Spec autocontenido: **no necesitás nada de la conversación en la que se creó.**

## Qué vas a dejar instalado

```text
1. ~/.config/yazi/yazi.toml   opener "drawio" + prepend_rules para *.drawio(.png|.svg)
2. LaunchServices             la PWA draw.io como default del UTI dinamico de .drawio
                              (via macos/drawio-default-app/set-drawio-default.swift)
```

## Entorno donde se construyó y verificó

```text
fecha        2026-09-04
macOS        Darwin 25.5.0 (Apple Silicon, arm64)
yazi         26.5.6 (Homebrew)
PWA draw.io  ~/Applications/Chromium Apps.localized/draw.io.app
             shim de Chromium 150.0.7840 en ~/devtools/chrome-mac/Chromium.app
             perfil "Profile 2", app-id ilmgmogedobmcfegdjcibiiaodmdenpf
             URL de la PWA: https://app.diagrams.net/index.html
swift        6.3.3 (viene con Xcode; solo se usa para el registro en LaunchServices)
```

## Paso 1 — opener de yazi

Editá `~/.config/yazi/yazi.toml` (el espejo completo y vigente está en
`macos/.config/yazi/`; si el mac está limpio, copiá ese directorio tal cual):

```toml
[opener]
drawio = [
  { run = 'open -a "draw.io" "$@"', desc = "draw.io (PWA)", orphan = true, for = "macos" },
]

[open]
prepend_rules = [
  { url = "*.drawio",     use = ["drawio", "edit", "reveal"] },
  { url = "*.drawio.png", use = ["drawio", "open", "reveal"] },
  { url = "*.drawio.svg", use = ["drawio", "open", "reveal"] },
]
```

Notas que ahorran tiempo:

- **`open -a "draw.io" <archivo>` alcanza** (por nombre: LaunchServices resuelve el shim;
  la ruta completa `~/Applications/Chromium Apps.localized/draw.io.app` tambien sirve). No hace falta invocar Chromium con
  `--app-id=… --profile-directory=…`: el `Info.plist` del shim declara
  `CFBundleDocumentTypes` con la extension `drawio` y el MIME
  `application/vnd.jgraph.mxfile`, y Chromium reenvia el archivo al *File Handling API*
  de la PWA. Ambas vias fueron probadas; la de `open -a` es la que no depende del nombre
  del perfil.
- `orphan = true` es obligatorio: la PWA sobrevive a que yazi se cierre.
- `*.drawio` **no** matchea `algo.drawio.png`, asi que el orden de las tres reglas es
  indistinto.
- `prepend_rules` gana sobre el preset de yazi; `use` lista fallbacks para el menu de `O`.

Verificá que el TOML parsea con `yazi --debug | head -20` (la seccion `Config` no debe
reportar error en `yazi.toml`).

## Paso 2 — app por defecto en Finder

```sh
swift macos/drawio-default-app/set-drawio-default.swift
# o, si el shim esta en otra ruta:
swift macos/drawio-default-app/set-drawio-default.swift "/ruta/a/draw.io.app"
```

Por que un script y no `duti`: `duti` no esta instalado y `.drawio` **no tiene UTI
declarado** por ninguna app, asi que LaunchServices le asigna uno dinamico —
`dyn.ah62d4rv4ge80k6xbs7y08` en este mac. `UTType(filenameExtension: "drawio")` lo
resuelve y `NSWorkspace.setDefaultApplication(at:toOpen:)` (macOS 12+) hace la
asociacion sin editar plists de LaunchServices a mano. El script es idempotente e imprime
el UTI y la app resultante.

## Cómo verificar (sin GUI)

```sh
printf '%s\n' '<mxfile><diagram name="p" id="p1"><mxGraphModel><root>' \
  '<mxCell id="0"/><mxCell id="1" parent="0"/>' \
  '</root></mxGraphModel></diagram></mxfile>' > /tmp/prueba.drawio

open /tmp/prueba.drawio     # ruta Finder (default de LaunchServices)
sleep 6
osascript -e 'tell application "Chromium" to get title of every tab of every window' \
  | tr ',' '\n' | grep -i prueba     # -> " prueba.drawio - draw.io"
```

Si el titulo de la ventana queda en `draw.io` a secas y aparece el dialogo
**"Error al cargar el archivo — buffer error"**, el archivo *si* llego a la PWA: ese error
es de XML invalido (un `.drawio` de prueba mal armado), no del cableado. Si en cambio la
ventana abre en **"Diagrama sin titulo"**, el archivo **no** se paso.
