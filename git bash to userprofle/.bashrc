alias helloworld="echo me gusta la pepitoria"
alias c="NO_COLOR=1 TERM=dumb claude"
alias tf="terraform"
alias l="ls -lat"
alias gfp="git fetch -a --prune && git pull --all && git status"
alias gb="git branch -la"
alias gl="git log --oneline"
alias gup="git switch develop && git fetch -a --prune && git pull --all && git status && git switch release && git fetch -a --prune && git pull --all && git status && git switch stage && git fetch -a --prune && git pull --all && git status && git switch main && git fetch -a --prune && git pull --all && git status"
alias gdiff="git diff release develop && git diff stage release"
alias gdiffm="git diff release develop && git diff stage release && git diff main stage"
set enable-bracketed-paste on

gcp() {
        git add .
        git commit -m "$1"
        # Detecta si la rama tiene upstream
        upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

        if [ $? -ne 0 ]; then
            # No tiene upstream, lo configura autom├â┬íticamente
            branch=$(git symbolic-ref --short HEAD)
            echo "No upstream branch detected. Setting upstream to origin/$branch"
            git push --set-upstream origin "$branch"
        else
            # Ya tiene upstream, hace push normal
            git push
        fi
}
gch() {
        git checkout -b "$1"
}
