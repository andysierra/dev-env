#!/bin/zsh
# Instalador idempotente de "iTerm + yazi con hotkey global" (macOS).
# Toma los archivos de SU PROPIO directorio, asi que se puede correr desde cualquier cwd:
#
#   zsh /ruta/al/repo/macos/iterm-yazi/install.sh [--dry-run]
#
# Hace todo lo scripteable. Lo manual (fuente de iTerm, permisos) lo imprime al final.
# Spec completo: ../spec-iterm-yazi-hotkey.md

set -euo pipefail

HERE=${0:A:h}
DRY=0
[[ ${1:-} == "--dry-run" ]] && DRY=1

RULE_DESC="Option+Command+E -> iTerm con yazi en ~/Desktop"
KB="$HOME/.config/karabiner/karabiner.json"
STAMP=$(date +%Y%m%d-%H%M%S)

info() { print -- "  $*" }
ok()   { print -- "  OK   $*" }
warn() { print -- "  AVISO $*" }
die()  { print -u2 -- "  ERROR $*"; exit 1 }
step() { print -- ""; print -- "== $*" }
do_() { if (( DRY )); then print -- "  DRY  $*"; else eval "$*"; fi }

# ---------------------------------------------------------------- 0. preflight
step "0. Preflight"
(( DRY )) && warn "modo --dry-run: no se escribe nada"

[[ "$(uname -s)" == Darwin ]] || die "esto es solo para macOS"
command -v yazi >/dev/null || die "falta yazi   -> brew install yazi"
command -v jq   >/dev/null || die "falta jq     -> brew install jq"
[[ -d /Applications/iTerm.app || -d "$HOME/Applications/iTerm.app" ]] \
  || die "falta iTerm2 -> brew install --cask iterm2"
[[ -d /Applications/Karabiner-Elements.app ]] \
  || die "falta Karabiner-Elements -> brew install --cask karabiner-elements"
[[ -f "$KB" ]] \
  || die "no existe $KB — abrí Karabiner-Elements una vez (crea el perfil) y repetí"

for f in yazi-desktop.sh yazi-desktop.js iterm-here.sh keymap.toml; do
  [[ -f "$HERE/$f" ]] || die "no encuentro $HERE/$f"
done
ok "yazi $(yazi --version | head -1), iTerm2, Karabiner y jq presentes"

# ------------------------------------------------------------------ 1. scripts
step "1. Scripts en ~/bin"
do_ "mkdir -p '$HOME/bin' '$HOME/.config/yazi'"
do_ "cp '$HERE/yazi-desktop.sh' '$HERE/yazi-desktop.js' '$HERE/iterm-here.sh' '$HOME/bin/'"
do_ "chmod +x '$HOME/bin/yazi-desktop.sh' '$HOME/bin/iterm-here.sh'"
ok "~/bin/yazi-desktop.sh, ~/bin/yazi-desktop.js, ~/bin/iterm-here.sh"

# --------------------------------------------------------------- 2. keymap yazi
step "2. Keymap de yazi (T / Ctrl+T -> terminal nueva en el cwd)"
KM="$HOME/.config/yazi/keymap.toml"
if [[ ! -f "$KM" ]]; then
  do_ "cp '$HERE/keymap.toml' '$KM'"
  ok "keymap.toml creado"
elif grep -q "iterm-here.sh" "$KM"; then
  ok "keymap.toml ya tiene el binding (no se toca)"
else
  # Hay un keymap propio del usuario: NO se sobreescribe, se anexa lo nuestro.
  do_ "cp '$KM' '$KM.bak-$STAMP'"
  do_ "printf '\n' >> '$KM'"
  do_ "grep -v '^#' '$HERE/keymap.toml' >> '$KM'"
  warn "keymap.toml ya existía: backup en keymap.toml.bak-$STAMP y bindings anexados."
  warn "Revisá que no haya colisiones de teclas ni secciones [mgr] duplicadas."
fi

# ------------------------------------------------------------- 3. regla hotkey
step "3. Regla de Karabiner (Option+Command+E)"
IDX=$(jq '[.profiles[].selected] | index(true) // 0' "$KB")
info "perfil activo: indice $IDX ($(jq -r --argjson i "$IDX" '.profiles[$i].name' "$KB"))"
do_ "cp '$KB' '$HOME/.config/karabiner/automatic_backups/karabiner-pre-yazi-hotkey-$STAMP.json'"

TMP=$(mktemp -t karabiner-yazi)
jq --argjson i "$IDX" \
   --arg cmd "$HOME/bin/yazi-desktop.sh" \
   --arg desc "$RULE_DESC" '
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
' "$KB" > "$TMP"

# Validar ANTES de escribir: un karabiner.json roto deja el teclado sin modificaciones.
jq -e --argjson i "$IDX" --arg desc "$RULE_DESC" \
  '.profiles[$i].complex_modifications.rules[0].description == $desc' "$TMP" >/dev/null \
  || die "el JSON generado no valida; no se escribió nada (temporal en $TMP)"

do_ "mv '$TMP' '$KB'"
(( DRY )) && rm -f "$TMP"
ok "regla instalada/actualizada (idempotente: reemplaza la que tenga la misma description)"
info "reglas del perfil ahora:"
(( DRY )) || jq -r --argjson i "$IDX" '.profiles[$i].complex_modifications.rules[].description' "$KB" | sed 's/^/       - /'

# --------------------------------------------------------------- 4. pendientes
step "4. Falta hacer A MANO (no es scripteable)"
FONT=$(/usr/libexec/PlistBuddy -c "Print :'New Bookmarks':0:'Normal Font'" \
        "$HOME/Library/Preferences/com.googlecode.iterm2.plist" 2>/dev/null || true)
if [[ "$FONT" == *NF* || "$FONT" == *Nerd* ]]; then
  ok "fuente del perfil 0 de iTerm: $FONT (Nerd Font -> los iconos de yazi se van a ver)"
else
  warn "fuente del perfil 0 de iTerm: ${FONT:-desconocida}"
  warn "  poné una Nerd Font (iTerm2 > Settings > Profiles > Text > Font),"
  warn "  p.ej. 'CascadiaCodeNF-Regular' tras: brew install --cask font-cascadia-code-nf"
  warn "  y dejá 'Use a different font for non-ASCII text' DESACTIVADO."
fi
info "1) Karabiner-Elements: abrirlo una vez y habilitar su extension + Input Monitoring."
info "2) La PRIMERA pulsacion de Option+Command+E pide permiso de Automatizacion"
info "   (karabiner_console_user_server -> iTerm): hay que Permitir."

step "5. Probar"
info "zsh \$HOME/bin/yazi-desktop.sh     # debe abrir yazi maximizado en ~/Desktop"
info "luego Option+Command+E, y dentro de yazi: Shift+T (o Ctrl+T)"
print -- ""
