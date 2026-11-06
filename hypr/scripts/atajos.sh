#!/bin/sh
# SpiderOS: lista de atajos (botón "Help" de la barra)
printf '%s\n' \
  "Super + T            Terminal (kitty)" \
  "Super + N            Firefox" \
  "Super + E            Archivos (Thunar)" \
  "Super + C            Visual Studio Code" \
  "Super + B            DBeaver" \
  "Super + D            Lanzador de apps" \
  "Super + Q            Cerrar ventana" \
  "Super + V            Ventana flotante / acomodada" \
  "Super + Shift + V    Modo cuadrícula del escritorio" \
  "Super + 1…0          Ir al escritorio (de esta pantalla)" \
  "Super + Shift + 1…0  Mandar ventana a ese escritorio" \
  "Super + P            Modo y posición de pantallas" \
  "Super + L            Bloquear" \
  "Super + Shift + S    Captura de pantalla" \
  "Alt + Tab            Cambiar de ventana" \
  "Ctrl + N (Neovim)    Panel de archivos" | \
fuzzel --dmenu --prompt "Atajos › " --lines 16 --width 52 \
  --font "JetBrainsMono Nerd Font:size=11" \
  --background 05111Dee --text-color B8E4ECff --match-color 86D0E2ff \
  --selection-color 266A88ff --selection-text-color D6EAF0ff \
  --border-color 2F6E85ff --border-width 2 --border-radius 0 >/dev/null
