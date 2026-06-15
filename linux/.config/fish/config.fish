source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# ANDYSIERRA:

# iniciar labwc en el bus IPC
if status is-login; and test -z "$WAYLAND_DISPLAY"; and test "$XDG_VTNR" = 1
	exec dbus-run-session labwc
end
export PATH="$HOME/.local/bin:$PATH"
set -gx EDITOR vim

# aliases
alias c="NO_COLOR=1 TERM=dumb claude"
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

function gcp
    git add .
    git commit -m "$argv[1]"
    git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
    if test $status -ne 0
        set branch (git symbolic-ref --short HEAD)
        echo "No upstream branch detected. Setting upstream to origin/$branch"
        git push --set-upstream origin "$branch"
    else
        git push
    end
end

function gch
    git checkout -b $argv[1]
end

function go
    cd $argv[1] && ls -la
end

function y
    set tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file=$tmp
    if set cwd (cat -- $tmp 2>/dev/null); and test -n "$cwd"; and test "$cwd" != "$PWD"
        cd -- $cwd
    end
    rm -f -- $tmp
end
