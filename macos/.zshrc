# PATH de ~/.local/bin ahora se define en ~/.zshenv (aplica tambien a shells no interactivos)
export EDITOR=vim

# Aliases
alias ls='ls -G'
alias grep='grep --color=auto'
alias helloworld='echo me gusta la pepitoria'
alias c='NO_COLOR=1 TERM=dumb claude'
alias tf='terraform'
alias l='ls -lat'
alias gfp='git fetch --all --prune && git pull --all && git status'
alias gb='git branch -la'
alias gl='git log --oneline'
alias gup='git switch develop && git fetch --all --prune && git pull --all && git status && git switch release && git fetch --all --prune && git pull --all && git status && git switch stage && git fetch --all --prune && git pull --all && git status && git switch main && git fetch --all --prune && git pull --all && git status'
alias gdiff='git diff release develop && git diff stage release'
alias gdiffm='git diff release develop && git diff stage release && git diff main stage'
alias claudia='claude --dangerously-skip-permissions'
alias s='open -n -a "Sublime Text"'

# Ajuste de jq (en macOS normalmente no es .exe)
alias jq="$HOME/Desktop/DEV/dev-env/git_bash/jq"

# Bracketed paste (en zsh se maneja distinto)
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# Funciones
gcp() {
    git add .
    git commit -m "$1"

    # Detecta si la rama tiene upstream
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

    if [ $? -ne 0 ]; then
        # No tiene upstream, lo configura automáticamente
        branch=$(git symbolic-ref --short HEAD)
        echo "No upstream branch detected. Setting upstream to origin/$branch"
        git push --set-upstream origin "$branch"
    else
        # Ya tiene upstream, hace push normal
        git push
    fi
}

gch() {
    git switch -c "$1"
}

go() {
    if [[ -n "$1" ]]; then
        cd "$1" && ls -la
    else
        ls -la
    fi
}
compctl -/ go

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

# Prompt con rama git
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%n@%m %~%F{yellow}${vcs_info_msg_0_}%f %# '
export JAVA_HOME=$HOME/devtools/java25/Home
export PATH="$JAVA_HOME/bin:$PATH"

# Túneles SSM a Aurora Positiva Core
alias tdev='~/Desktop/tunnel-dev.sh'
alias tqa='~/Desktop/tunnel-qa.sh'
alias tuat='~/Desktop/tunnel-uat.sh'
export PATH="$PATH:/Applications/IntelliJ IDEA.app/Contents/MacOS"

# zoxide (define las funciones z / zi) — debe ir al final
eval "$(zoxide init zsh)"
