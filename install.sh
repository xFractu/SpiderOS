#!/usr/bin/env bash
# ================= SpiderOS =================
# Instala SpiderOS en una instalación de EndeavourOS / Arch ("No Desktop").
#
#   git clone git@github.com:xFractu/SpiderOS.git ~/SpiderOS
#   cd ~/SpiderOS && ./install.sh
#
# Opciones:
#   --solo-enlaces   no instala paquetes ni el plugin, solo crea los enlaces
#
# Los archivos que ya existan en ~/.config se respaldan en ~/.config/spideros-respaldo-FECHA

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
RESPALDO="$CONFIG/spideros-respaldo-$(date +%Y%m%d-%H%M%S)"
SOLO_ENLACES=0
[[ "${1:-}" == "--solo-enlaces" ]] && SOLO_ENLACES=1

azul()  { printf '\033[38;2;125;179;189m%s\033[0m\n' "$*"; }
rojo()  { printf '\033[38;2;224;88;92m%s\033[0m\n' "$*"; }

# ---------- 1. Paquetes ----------
PAQUETES=(
    # base de Hyprland
    hyprland hyprpm xdg-desktop-portal-hyprland
    # shell, terminal, navegador
    noctalia kitty firefox
    # capturas, portapapeles, utilidades de los scripts
    grim slurp wl-clipboard jq
    # fuente con iconos (barra de ventanas)
    ttf-jetbrains-mono-nerd
    # explorador de archivos
    thunar gvfs tumbler ffmpegthumbnailer
    # para compilar el plugin spider-bars
    git cmake meson cpio pkgconf gcc
)

if [[ $SOLO_ENLACES -eq 0 ]]; then
    azul "==> Instalando paquetes"
    sudo pacman -Syu --needed "${PAQUETES[@]}"
fi

# ---------- 2. Enlaces de configuración ----------
# formato: "ruta dentro del repo|ruta en el sistema"
ENLACES=(
    "hypr|$CONFIG/hypr"
    "kitty|$CONFIG/kitty"
    "noctalia/spider.toml|$CONFIG/noctalia/spider.toml"
    "noctalia/palettes/SpiderOS.json|$CONFIG/noctalia/palettes/SpiderOS.json"
    "wallpapers|$HOME/Imágenes/Fondos"
)

azul "==> Creando enlaces"
for par in "${ENLACES[@]}"; do
    origen="$REPO/${par%%|*}"
    destino="${par##*|}"

    if [[ ! -e "$origen" ]]; then
        rojo "   falta en el repo: ${par%%|*} (se omite)"
        continue
    fi

    # ya apunta al repo -> nada que hacer
    if [[ -L "$destino" && "$(readlink -f "$destino")" == "$(readlink -f "$origen")" ]]; then
        echo "   ok   $destino"
        continue
    fi

    # respaldar lo que hubiera
    if [[ -e "$destino" || -L "$destino" ]]; then
        mkdir -p "$RESPALDO"
        mv "$destino" "$RESPALDO/"
        echo "   respaldo de $destino -> $RESPALDO/"
    fi

    mkdir -p "$(dirname "$destino")"
    ln -s "$origen" "$destino"
    echo "   enlace $destino -> $origen"
done

chmod +x "$REPO"/hypr/scripts/*.sh 2>/dev/null || true
mkdir -p "$HOME/Imágenes/Capturas"

# ---------- 3. Plugin spider-bars ----------
if [[ $SOLO_ENLACES -eq 0 ]]; then
    azul "==> Instalando el plugin spider-bars"
    hyprpm update -f || true
    if ! hyprpm list 2>/dev/null | grep -q "spider-bars"; then
        yes | hyprpm add https://github.com/xFractu/spider-bars
    fi
    hyprpm enable hyprbars || true
fi

azul ""
azul "==> SpiderOS instalado"
echo "    Entra a Hyprland con:  start-hyprland"
echo "    Después de actualizar Hyprland (pacman -Syu) corre:  hyprpm update -f"
[[ -d "$RESPALDO" ]] && echo "    Tus archivos anteriores quedaron en: $RESPALDO"
exit 0
