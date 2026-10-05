#!/bin/bash
# Alt+Shift+4: seleccionar área → al soltar el mouse se guarda en la carpeta de imágenes (~/Imágenes).
# -s (--accept-on-select): sin pasos extra. La ruta sale de xdg-user-dir para no escribir la "á" a mano.
exec flameshot gui -s -p "$(xdg-user-dir PICTURES)"
