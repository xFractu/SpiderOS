#!/bin/sh
# SpiderOS: al reconectar el monitor, volver a levantar Noctalia
sleep 2
pid=$(pgrep -x noctalia | head -1)
if [ -n "$pid" ]; then
    edad=$(ps -o etimes= -p "$pid" | tr -d ' ')
    # recién arrancado (inicio de sesión): no tocarlo
    [ "${edad:-0}" -lt 15 ] && exit 0
    pkill -x noctalia
    sleep 1
fi
noctalia > /tmp/noctalia.log 2>&1 &
