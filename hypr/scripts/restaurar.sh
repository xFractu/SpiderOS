#!/bin/sh
# SpiderOS: si la ventana está maximizada, regresarla a su tamaño y lugar anteriores
if hyprctl activewindow -j | grep -q '"fullscreen": [1-9]'; then
    hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" })'
fi
