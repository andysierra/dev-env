# yazi: cambia de directorio al salir (requiere instalar yazi)
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
