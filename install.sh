#!/usr/bin/env bash
# ================= SpiderOS =================
# Instala SpiderOS en EndeavourOS / Arch ("No Desktop").
#
#   git clone git@github.com:xFractu/SpiderOS.git ~/SpiderOS
#   cd ~/SpiderOS && ./install.sh
#
# Opciones:
#   --solo-enlaces   no instala paquetes ni plugins, solo crea los enlaces

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
RESPALDO="$CONFIG/spideros-respaldo-$(date +%Y%m%d-%H%M%S)"
SOLO_ENLACES=0
[[ "${1:-}" == "--solo-enlaces" ]] && SOLO_ENLACES=1

azul() { printf '\033[38;2;125;179;189m%s\033[0m\n' "$*"; }
rojo() { printf '\033[38;2;224;88;92m%s\033[0m\n' "$*"; }

# ---------- 1. Paquetes ----------
PAQUETES=(
    hyprland hyprpm xdg-desktop-portal-hyprland
    noctalia kitty firefox
    grim slurp wl-clipboard jq libnotify imagemagick
    ttf-jetbrains-mono-nerd
    thunar gvfs tumbler ffmpegthumbnailer adw-gtk-theme
    git cmake meson cpio pkgconf gcc
)
if [[ $SOLO_ENLACES -eq 0 ]]; then
    azul "==> Instalando paquetes"
    sudo pacman -Syu --needed "${PAQUETES[@]}"
fi

# ---------- 2. Enlaces de configuración ----------
ENLACES=(
    "hypr|$CONFIG/hypr"
    "kitty|$CONFIG/kitty"
    "noctalia/spider.toml|$CONFIG/noctalia/spider.toml"
    "noctalia/palettes/SpiderOS.json|$CONFIG/noctalia/palettes/SpiderOS.json"
    "wallpapers|$HOME/Imágenes/Fondos"
)
azul "==> Creando enlaces"
for par in "${ENLACES[@]}"; do
    origen="$REPO/${par%%|*}"; destino="${par##*|}"
    [[ -e "$origen" ]] || { rojo "   falta en el repo: ${par%%|*}"; continue; }
    if [[ -L "$destino" && "$(readlink -f "$destino")" == "$(readlink -f "$origen")" ]]; then
        echo "   ok   $destino"; continue
    fi
    if [[ -e "$destino" || -L "$destino" ]]; then
        mkdir -p "$RESPALDO"; mv "$destino" "$RESPALDO/"
        echo "   respaldo de $destino -> $RESPALDO/"
    fi
    mkdir -p "$(dirname "$destino")"; ln -s "$origen" "$destino"
    echo "   enlace $destino -> $origen"
done
chmod +x "$REPO"/hypr/scripts/*.sh 2>/dev/null || true
mkdir -p "$HOME/Imágenes/Capturas"

# ---------- 3. Tema GTK (Thunar) ----------
azul "==> Tema GTK"
mkdir -p "$CONFIG/gtk-3.0"
grep -qs "spideros.css" "$CONFIG/gtk-3.0/gtk.css" || \
    echo "@import url(\"file://$REPO/gtk/spideros.css\");" >> "$CONFIG/gtk-3.0/gtk.css"

# ---------- 4. Arranque: autologin en TTY1 + Hyprland ----------
if [[ $SOLO_ENLACES -eq 0 ]]; then
    azul "==> Inicio de sesión automático"
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
    printf '[Service]\nExecStart=\nExecStart=-/sbin/agetty -o %s --noclear --autologin %s %%I $TERM\n' \
        "'-p -f -- \\\\u'" "$USER" | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null
fi
grep -qs "start-hyprland" "$HOME/.bash_profile" || cat >> "$HOME/.bash_profile" << 'PERFIL'

# SpiderOS: abrir Hyprland al iniciar sesión en la TTY1
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec start-hyprland
fi
PERFIL

# ---------- 5. Plugins ----------
if [[ $SOLO_ENLACES -eq 0 ]]; then
    azul "==> Plugin spider-bars (Hyprland)"
    hyprpm update -f || true
    hyprpm list 2>/dev/null | grep -q "spider-bars" || yes | hyprpm add https://github.com/xFractu/spider-bars
    hyprpm enable hyprbars || true

    azul "==> Plugin SpiderOS (Noctalia)"
    if pgrep -x noctalia > /dev/null; then
        noctalia msg plugins source add spideros path "$REPO/noctalia-plugins" || true
        noctalia msg plugins enable fractu/spideros || true
    else
        rojo "   Noctalia no está corriendo. Dentro de Hyprland corre:"
        echo "   noctalia msg plugins source add spideros path $REPO/noctalia-plugins"
        echo "   noctalia msg plugins enable fractu/spideros"
    fi
fi

azul ""
azul "==> SpiderOS instalado. Reinicia con: reboot"
echo "    Después de actualizar Hyprland (pacman -Syu) corre: hyprpm update -f"
[[ -d "$RESPALDO" ]] && echo "    Tus archivos anteriores quedaron en: $RESPALDO"
exit 0
