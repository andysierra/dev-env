#!/bin/bash

USER=andysierra
USER_ID=1000
WAYLAND_DISPLAY=wayland-0
XDG_RUNTIME_DIR=/run/user/$USER_ID

LID_STATE=$(cat /proc/acpi/button/lid/LID0/state 2>/dev/null || cat /proc/acpi/button/lid/LID/state)

if echo "$LID_STATE" | grep -q "closed"; then
    runuser -l $USER -c "WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR wlr-randr --output eDP-1 --off"
else
    runuser -l $USER -c "WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR wlr-randr --output eDP-1 --on --pos 277,1080 --mode 1366x768"
fi
