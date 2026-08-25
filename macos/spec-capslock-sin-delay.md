# macOS — Caps Lock sin delay

En macOS, Caps Lock **no** se activa con un toque normal: hay que mantenerlo pulsado unos
milisegundos. No es un teclado defectuoso ni desgaste mecánico — es un retardo deliberado
del sistema para evitar activaciones accidentales, y viene igual en todos los Mac.

Este spec lo deja en **cero**, y persistente entre reinicios.

## Para el humano

```text
ANTES          Caps Lock hay que presionarlo "duro y sostenido" para que prenda
DESPUÉS        prende con un toque normal, como en Windows / Linux
ALCANCE        todo el sistema, todos los teclados HID (interno y externos)
PERSISTENCIA   se re-aplica sola en cada login (LaunchAgent)
REVERSIBLE     sí, un script; no toca nada del sistema ni requiere sudo
```

### Instalar / revertir

```text
INSTALAR    macos/capslock-nodelay/install.sh      (idempotente)
REVERTIR    macos/capslock-nodelay/uninstall.sh
VERIFICAR   hidutil property --get CapsLockDelayOverride   ->  0
```

### Para replicar en un mac nuevo
Compartí este archivo con Claude Code (o cualquier IA con acceso a shell) y pedile:
*"implementá la sección **Para la IA** de este spec en este mac"*. Es todo scripteable:
no hay ni un paso manual ni permisos de accesibilidad que conceder.

---

# Para la IA — leé esto antes de tocar nada

Este spec es autocontenido: **no necesitás nada de la conversación en la que se creó.**

## Qué vas a dejar instalado

```text
1. hidutil property --set {"CapsLockDelayOverride":0}   aplicado en la sesión actual
2. ~/Library/LaunchAgents/local.capslock.nodelay.plist  RunAtLoad -> lo re-aplica al login
```

Nada más. No hay binarios, ni daemons corriendo, ni Karabiner de por medio.

## Entorno donde se construyó y verificó

```text
fecha       2026-08-25
macOS       26.5.1 (build 25F80) — Darwin 25.5.0, Apple Silicon arm64
hidutil     /usr/bin/hidutil (viene con macOS, no se instala nada)
shell       /bin/zsh
sudo        NO se necesita
```

## Cómo funciona

`hidutil` es la utilidad de Apple para hablarle a la capa HID (IOKit). La propiedad
`CapsLockDelayOverride` fija, en milisegundos, cuánto hay que sostener la tecla antes de
que el sistema la acepte. El default de macOS ronda los ~75–100 ms; ponerla en `0` la
vuelve instantánea.

```text
hidutil property --set '{"CapsLockDelayOverride":0}'    escribe (JSON entre comillas)
hidutil property --get  CapsLockDelayOverride           lee    (SIN llaves ni comillas)
```

⚠️ **Trampa de sintaxis:** el `--get` NO usa la forma `'{"Clave"}'`. Si la usás devuelve
`(null)` y parece que el cambio no se aplicó, cuando en realidad sí. La forma correcta del
`--get` es la clave pelada.

### Por qué hace falta el LaunchAgent

El `--set` es **volátil**: vive en la sesión de IOKit y se pierde al reiniciar o cerrar
sesión. El LaunchAgent con `RunAtLoad=true` simplemente vuelve a correr el mismo comando
en cada login del usuario. Es un agente *one-shot*: corre, aplica, termina.

Por eso `launchctl print` mostrará `state = running` justo después del `bootstrap` y
después el trabajo queda como completado — no es un servicio que deba quedarse vivo.

## Pasos exactos

```text
1. cp macos/capslock-nodelay/local.capslock.nodelay.plist  ~/Library/LaunchAgents/
2. plutil -lint ~/Library/LaunchAgents/local.capslock.nodelay.plist        -> OK
3. launchctl bootout   gui/$(id -u)/local.capslock.nodelay   (por si ya existía; ignorar error)
4. launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.capslock.nodelay.plist
5. hidutil property --get CapsLockDelayOverride                            -> 0
```

Los pasos 1–5 son exactamente lo que hace `install.sh`. Usá el script.

Usá `bootout` / `bootstrap` (launchd moderno), **no** `launchctl load/unload`: están
deprecados en macOS moderno y fallan en silencio con agentes de usuario.

## Verificación

```text
hidutil property --get CapsLockDelayOverride            debe imprimir  0
launchctl print gui/$(id -u)/local.capslock.nodelay     debe existir (no "Could not find")
```

Y la prueba real: dar **un toque seco** a Caps Lock y ver que el LED / indicador prende.

## Limitaciones conocidas

```text
- Verificado en 1 sola máquina (Apple Silicon, macOS 26.5.1). No probado en Intel.
- No verificado si el ajuste sobrevive a suspensión o a conectar un teclado externo
  NUEVO estando la sesión abierta. hidutil aplica sobre los dispositivos HID presentes,
  así que es plausible que un teclado recién enchufado arranque con el delay default.
  Si eso pasa: correr install.sh de nuevo (es idempotente), o agregarle al plist un
  StartInterval, o un disparador de wake con sleepwatcher.
- No confundir con Ajustes > Teclado > Teclas modificadoras: ahí se puede REMAPEAR
  Caps Lock, pero no existe ninguna opción de UI para el delay. Solo hidutil.
```
