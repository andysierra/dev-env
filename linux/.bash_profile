[[ -f ~/.bashrc ]] && source ~/.bashrc

# Launch labwc on TTY1
if [[ -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" == "1" ]]; then
    exec dbus-run-session labwc
fi
