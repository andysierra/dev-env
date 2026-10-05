#!/bin/bash
# Alt+N: escribe "~" (en el layout latam es AltGr+4 o AltGr+ñ, incómodo).
# sleep: mientras la tecla del atajo sigue apretada, MATE mantiene el teclado capturado
#   (passive grab) y lo que escriba xdotool no llega a la ventana; se libera al soltar la N.
# --clearmodifiers: suelta el Alt si todavía está apretado y lo restaura después.
sleep 0.25
exec xdotool type --clearmodifiers '~'
