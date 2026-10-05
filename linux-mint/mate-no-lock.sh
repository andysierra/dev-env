#!/bin/bash
# MATE: nunca bloquear la sesión (sin pedir contraseña por inactividad, al suspender ni al apagar pantalla).
# Idempotente. Por defecto Mint activa el salvapantallas a los 5 min (org.mate.session idle-delay)
# y como lock-enabled=true, al volver pide contraseña.

S=org.mate.screensaver
P=org.mate.power-manager

gsettings set $S idle-activation-enabled false   # no activar salvapantallas por inactividad
gsettings set $S lock-enabled            false   # y si se activa (a mano), no bloquear

gsettings set $P lock-suspend        false       # al volver de suspender
gsettings set $P lock-hibernate      false       # al volver de hibernar
gsettings set $P lock-blank-screen   false       # cuando el ahorro de energía apaga la pantalla

for k in "$S idle-activation-enabled" "$S lock-enabled" "$P lock-suspend" "$P lock-hibernate" "$P lock-blank-screen"; do
    echo "$k = $(gsettings get $k)"
done
