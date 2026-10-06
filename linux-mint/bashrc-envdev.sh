# ===================== env-dev (andysierra) =====================
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=vim

# git-aware prompt (muestra la rama actual)
source /usr/lib/git-core/git-sh-prompt
GIT_PS1_SHOWDIRTYSTATE=1
PS1='\[\e[32m\]\w\[\e[33m\]$(__git_ps1 " (%s)")\[\e[0m\] \$ '

# aliases
alias c="NO_COLOR=1 TERM=dumb claude"
alias claudia="claude --dangerously-skip-permissions"
alias tf="terraform"
alias l="ls -lat"
alias helloworld="echo 'me gusta la pepitoria'"

# git aliases
alias gfp="git fetch -a --prune && git pull --all && git status"
alias gb="git branch -la"
alias gl="git log --oneline"
alias gdiff="git diff release develop && git diff stage release"
alias gdiffm="git diff release develop && git diff stage release && git diff main stage"
alias gup="git switch develop && git fetch -a --prune && git pull --all && git status && git switch release && git fetch -a --prune && git pull --all && git status && git switch stage && git fetch -a --prune && git pull --all && git status && git switch main && git fetch -a --prune && git pull --all && git status"

gcp() {
    git add .
    git commit -m "$1"
    git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
    if [ $? -ne 0 ]; then
        branch=$(git symbolic-ref --short HEAD)
        echo "No upstream branch detected. Setting upstream to origin/$branch"
        git push --set-upstream origin "$branch"
    else
        git push
    fi
}

gch() {
    git checkout -b "$1"
}

go() {
    if [[ -n "$1" ]]; then
        cd "$1" && ls -la
    else
        ls -la
    fi
}

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

complete -d go
# =================== fin env-dev (andysierra) ===================
