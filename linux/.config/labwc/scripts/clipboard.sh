#!/bin/bash
entry=$(cliphist list | bemenu -b)
[ -z "$entry" ] && exit

if echo "$entry" | grep -q "\[\[ binary"; then
    echo "$entry" | cliphist decode | wl-copy
else
    text=$(echo "$entry" | cliphist decode)
    echo -n "$text" | wl-copy
    sleep 0.1
    if [ "$(printf '%s' "$text" | wc -l)" -eq 0 ]; then
        wtype -- "$text"
    else
        mapfile -t lines <<< "$text"
        first=true
        for line in "${lines[@]}"; do
            if $first; then
                first=false
            else
                wtype -M shift -k return -m shift
            fi
            wtype -- "$line"
        done
    fi
fi
