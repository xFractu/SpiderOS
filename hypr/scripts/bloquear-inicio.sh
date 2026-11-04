#!/bin/sh
# SpiderOS: bloquear la sesión en cuanto Noctalia esté listo (autologin -> pide contraseña)
for i in $(seq 1 40); do
    noctalia msg session lock >/dev/null 2>&1 && exit 0
    sleep 0.5
done
