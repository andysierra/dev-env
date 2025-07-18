alias helloworld="echo me gusta la pepitoria"
alias tf="terraform"
alias l="ls -lat"
alias gfp="git fetch -a --prune && git pull && git status"
alias gb="git branch -la"
alias gl="git log --oneline"
gcp() {
        git add .
        git commit -m "$1"
        git push
}
gch() {
        git checkout -b "$1"
}