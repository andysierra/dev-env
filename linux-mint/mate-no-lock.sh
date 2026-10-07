#!/bin/bash
# MATE: nunca bloquear la sesión ni atenuar el brillo solo (sin pedir contraseña por inactividad, al suspender ni al apagar pantalla).
# Idempotente. Por defecto Mint activa el salvapantallas a los 5 min (org.mate.session idle-delay)
# y como lock-enabled=true, al volver pide contraseña.

S=org.mate.screensaver
P=org.mate.power-manager

gsettings set $S idle-activation-enabled false   # no activar salvapantallas por inactividad
gsettings set $S lock-enabled            false   # y si se activa (a mano), no bloquear

gsettings set $P lock-suspend        false       # al volver de suspender
gsettings set $P lock-hibernate      false       # al volver de hibernar
gsettings set $P lock-blank-screen   false       # cuando el ahorro de energía apaga la pantalla

# Brillo: que no baje solo (con batería MATE lo atenúa al 30 % tras 10 s sin uso y un 50 % al desenchufar)
gsettings set $P idle-dim-battery         false
gsettings set $P idle-dim-ac              false
gsettings set $P backlight-battery-reduce false

for k in "$P idle-dim-battery" "$P backlight-battery-reduce" "$S idle-activation-enabled" "$S lock-enabled" "$P lock-suspend" "$P lock-hibernate" "$P lock-blank-screen"; do
    echo "$k = $(gsettings get $k)"
done
