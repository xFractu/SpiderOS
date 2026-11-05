#!/bin/sh
# SpiderOS: al reconectar el monitor, volver a levantar Noctalia
sleep 2
# Recién prendida la PC (primer minuto) los monitores se conectan solos: no reiniciar
# Noctalia, porque está mostrando el bloqueo de inicio y matarlo deja la pantalla trabada.
hpid=$(pgrep -x Hyprland | head -1)
hedad=$(ps -o etimes= -p "$hpid" 2>/dev/null | tr -d ' ')
[ "${hedad:-0}" -lt 60 ] && exit 0
pid=$(pgrep -x noctalia | head -1)
if [ -n "$pid" ]; then
    edad=$(ps -o etimes= -p "$pid" | tr -d ' ')
    # recién arrancado (inicio de sesión): no tocarlo
    [ "${edad:-0}" -lt 15 ] && exit 0
    pkill -x noctalia
    sleep 1
fi
noctalia > /tmp/noctalia.log 2>&1 &
