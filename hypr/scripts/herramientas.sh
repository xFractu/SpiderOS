#!/bin/sh
# SpiderOS: menú de herramientas (botón "TOOLS" de la barra)
DIR="$HOME/Imágenes/Capturas"
mkdir -p "$DIR"
ARCH="$DIR/captura-$(date +%Y-%m-%d_%H-%M-%S).png"

OP=$(printf '%s\n' \
    "󰹑  Captura de una zona" \
    "󰍹  Captura de pantalla completa" \
    "󰈊  Selector de color (copia el código #RRGGBB)" \
    "󰍺  Pantallas (Super + P)" | \
    fuzzel --dmenu --prompt "Tools › " --lines 4 --width 48 \
      --font "JetBrainsMono Nerd Font:size=11" \
      --background 05111Dee --text-color B8E4ECff --match-color 86D0E2ff \
      --selection-color 266A88ff --selection-text-color D6EAF0ff \
      --border-color 2F6E85ff --border-width 2 --border-radius 0)

sleep 0.2   # que se cierre el menú antes de capturar

case "$OP" in
    *"una zona"*)
        ZONA=$(slurp) || exit 0
        grim -g "$ZONA" "$ARCH" && wl-copy < "$ARCH" && \
            notify-send -i "$ARCH" "Captura guardada" "Copiada al portapapeles · $ARCH" ;;
    *"pantalla completa"*)
        MON=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
        grim -o "$MON" "$ARCH" && wl-copy < "$ARCH" && \
            notify-send -i "$ARCH" "Captura guardada" "Copiada al portapapeles · $ARCH" ;;
    *"Selector de color"*)
        COLOR=$(hyprpicker -a -f hex) && [ -n "$COLOR" ] && \
            notify-send "Color copiado" "$COLOR" ;;
    *Pantallas*)
        exec "$HOME/.config/hypr/scripts/pantallas.sh" ;;
esac
