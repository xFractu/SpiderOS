# ================= SpiderOS: comandos cortos =================

# Reiniciar Noctalia
rnoct() {
    pkill -x noctalia
    sleep 1
    noctalia > /tmp/noctalia.log 2>&1 & disown
    echo "Noctalia reiniciado"
}

# Reiniciar Firefox
rfire() {
    pkill firefox
    sleep 2
    firefox > /dev/null 2>&1 & disown
    echo "Firefox reiniciado"
}
