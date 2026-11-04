#!/bin/sh
# SpiderOS: modo y posición de pantallas (como Win+P) -> Super + P
#
# "Esta pantalla" = la pantalla donde abriste el menú (donde está el mouse / foco).
# Lo que eliges (principal y posiciones) se guarda por MODELO de monitor en
#   ~/.local/state/spideros/monitores.conf   (datos)
#   ~/.local/state/spideros/monitores.lua    (lo carga spider.lua al iniciar)
# Funciona con 2, 3 o más monitores y en cualquier computadora.

DIR="$HOME/.local/state/spideros"
CONF="$DIR/monitores.conf"
LUA="$DIR/monitores.lua"
mkdir -p "$DIR"; touch "$CONF"

MONS=$(hyprctl -j monitors all)
N=$(echo "$MONS" | jq 'length')
if [ "$N" -lt 2 ]; then
    notify-send "SpiderOS" "Solo hay una pantalla conectada"
    exit 0
fi

# ---------- datos de los monitores ----------
desc_de()   { echo "$MONS" | jq -r --arg n "$1" '.[] | select(.name == $n) | .description'; }
nombre_de() { echo "$MONS" | jq -r --arg d "$1" '.[] | select(.description == $d) | .name'; }
# tamaño lógico (respeta escala y rotación)
ancho_de()  { echo "$MONS" | jq -r --arg n "$1" '.[] | select(.name == $n) | (if (.transform % 2) == 1 then .height else .width end) / .scale | floor'; }
alto_de()   { echo "$MONS" | jq -r --arg n "$1" '.[] | select(.name == $n) | (if (.transform % 2) == 1 then .width else .height end) / .scale | floor'; }

# esta pantalla = la enfocada
ESTA=$(hyprctl -j monitors | jq -r '([.[] | select(.focused)][0].name) // .[0].name')
D_ESTA=$(desc_de "$ESTA")

# principal: la guardada (si está conectada), si no la de la laptop (eDP), si no la primera
D_PRIN=$(sed -n 's/^principal=//p' "$CONF" | head -1)
PRIN=""
[ -n "$D_PRIN" ] && PRIN=$(nombre_de "$D_PRIN")
if [ -z "$PRIN" ]; then
    PRIN=$(echo "$MONS" | jq -r '([.[] | select(.name | test("^eDP"))][0].name) // .[0].name')
    D_PRIN=$(desc_de "$PRIN")
fi

TODAS=$(echo "$MONS" | jq -r '.[].name')

# ---------- guardar / aplicar ----------
generar_lua() {
    {
        echo "-- generado por pantallas.sh (Super + P); se cambia desde ese menú"
        echo "hl.monitor({ output = \"desc:$D_PRIN\", position = \"0x0\" })"
        grep '^pos=' "$CONF" | while IFS='|' read -r d x y; do
            d=${d#pos=}
            [ "$d" = "$D_PRIN" ] && continue
            echo "hl.monitor({ output = \"desc:$d\", position = \"${x}x${y}\" })"
        done
        # conectadas sin posición guardada: que Hyprland las acomode solo
        echo "$MONS" | jq -r '.[].description' | while read -r d; do
            [ "$d" = "$D_PRIN" ] && continue
            grep -qF "pos=$d|" "$CONF" && continue
            echo "hl.monitor({ output = \"desc:$d\", position = \"auto\" })"
        done
    } > "$LUA"
}

aplicar() {   # activa todas, sin espejo, con las posiciones guardadas
    generar_lua
    CMD=""
    for m in $TODAS; do CMD="$CMD hl.monitor({ output = '$m', disabled = false, mirror = '' })"; done
    hyprctl eval "$CMD $(grep -v '^--' "$LUA")"
}

guardar_pos() {  # $1 = descripción, $2 = x, $3 = y
    grep -v "^pos=$1|" "$CONF" > "$CONF.tmp"; mv "$CONF.tmp" "$CONF"
    echo "pos=$1|$2|$3" >> "$CONF"
}

mover_esta() {   # $1 = left | right | up | down
    if [ "$ESTA" = "$PRIN" ]; then
        notify-send "SpiderOS" "Esta es la pantalla principal. Abre Super + P desde la otra pantalla para acomodarla."
        return
    fi
    PW=$(ancho_de "$PRIN"); PH=$(alto_de "$PRIN")
    SW=$(ancho_de "$ESTA"); SH=$(alto_de "$ESTA")
    case "$1" in
        left)  X=$((-SW)); Y=0 ;;
        right) X=$PW;      Y=0 ;;
        up)    X=0;        Y=$((-SH)) ;;
        down)  X=0;        Y=$PH ;;
    esac
    guardar_pos "$D_ESTA" "$X" "$Y"
    aplicar
    notify-send "SpiderOS" "$ESTA guardada: $2 de la principal ($PRIN)"
}

# ---------- menú ----------
ES_PRIN=""; [ "$ESTA" = "$PRIN" ] && ES_PRIN=" ★"
OP=$(printf '%s\n' \
    "󰍹  Solo esta pantalla ($ESTA)" \
    "󰍺  Extender (todas)" \
    "󰍾  Duplicar esta pantalla en las demás" \
    "★  Hacer principal esta pantalla ($ESTA)$ES_PRIN" \
    "󰁍  Esta pantalla a la izquierda de la principal" \
    "󰁔  Esta pantalla a la derecha de la principal" \
    "󰁝  Esta pantalla arriba de la principal" \
    "󰁅  Esta pantalla abajo de la principal" | \
    fuzzel --dmenu --prompt "Pantallas › " --lines 8 --width 46 \
      --font "JetBrainsMono Nerd Font:size=11" \
      --background 05111Dee --text-color B8E4ECff --match-color 86D0E2ff \
      --selection-color 266A88ff --selection-text-color D6EAF0ff \
      --border-color 2F6E85ff --border-width 2 --border-radius 0)

case "$OP" in
    *"Solo esta pantalla"*)
        CMD="hl.monitor({ output = '$ESTA', disabled = false, mirror = '' })"
        for m in $TODAS; do [ "$m" != "$ESTA" ] && CMD="$CMD hl.monitor({ output = '$m', disabled = true })"; done
        hyprctl eval "$CMD" ;;
    *Extender*)
        aplicar ;;
    *Duplicar*)
        CMD="hl.monitor({ output = '$ESTA', disabled = false, mirror = '' })"
        for m in $TODAS; do [ "$m" != "$ESTA" ] && CMD="$CMD hl.monitor({ output = '$m', disabled = false, mirror = '$ESTA' })"; done
        hyprctl eval "$CMD" ;;
    *"Hacer principal"*)
        grep -v '^principal=' "$CONF" | grep -v "^pos=$D_ESTA|" > "$CONF.tmp"; mv "$CONF.tmp" "$CONF"
        echo "principal=$D_ESTA" >> "$CONF"
        D_PRIN="$D_ESTA"; PRIN="$ESTA"
        aplicar
        notify-send "SpiderOS" "$ESTA es ahora la pantalla principal. Acomoda las demás desde Super + P." ;;
    *izquierda*) mover_esta left  "a la izquierda" ;;
    *derecha*)   mover_esta right "a la derecha" ;;
    *arriba*)    mover_esta up    "arriba" ;;
    *abajo*)     mover_esta down  "abajo" ;;
esac
