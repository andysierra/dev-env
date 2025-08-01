alias helloworld="echo me gusta la pepitoria"
alias tf="terraform"
alias l="ls -lat"
alias gfp="git fetch -a --prune && git pull && git status"
alias gb="git branch -la"
alias gl="git log --oneline"
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
        git checkout -b "$1"
}