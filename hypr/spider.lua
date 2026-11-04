-- ================= SpiderOS =================

-- ---------- Teclado ----------
hl.config({
    input = { kb_layout = "latam" },
})

-- ---------- Ventanas ----------
hl.window_rule({
    name = "todo-flotante",
    match = { class = ".*" },
    float = true,
    size = "monitor_w*0.45 monitor_h*0.70",
    center = true,
})

hl.config({
    general = {
        resize_on_border        = true,
        border_size             = 2,
        ["col.active_border"]   = "rgb(154156)",
        ["col.inactive_border"] = "rgb(154156)",
    },
    decoration = { rounding = 0, shadow = { enabled = false } },
})

-- ---------- Atajos ----------
-- quitar atajos por defecto que no usamos
hl.unbind("SUPER + Q")
hl.unbind("SUPER + S")          -- área oculta "magic"
hl.unbind("SUPER + SHIFT + S")  -- mandar ventana a "magic" (la hacía desaparecer)

hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + N", hl.dsp.exec_cmd("firefox"))

-- tamaño con teclado
hl.bind("SUPER + minus",         hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
hl.bind("SUPER + plus",          hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + minus", hl.dsp.window.resize({ x = -50, y = 0,   relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + plus",  hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }), { repeating = true })

-- capturas
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd([[sh -c 'f=~/Imágenes/Capturas/$(date +%Y-%m-%d_%H-%M-%S).png; grim -g "$(slurp)" "$f" && wl-copy < "$f"']]))
hl.bind("SUPER + ALT + A", hl.dsp.exec_cmd([[sh -c 'f=~/Imágenes/Capturas/$(date +%Y-%m-%d_%H-%M-%S).png; grim "$f" && wl-copy < "$f"']]))

-- ---------- Barra de ventanas (spider-bars) ----------
if hl.plugin and hl.plugin.hyprbars then
    local fondoBarra = "rgb(86B3BF)"
    local azulOscuro = "rgb(1A5073)"
    local azulClaro  = "rgb(3B849F)"

    -- acciones de los botones
    local maximizar = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']]
    local restaurar = os.getenv("HOME") .. "/.config/hypr/scripts/restaurar.sh"
    local cerrar    = [[hyprctl dispatch 'hl.dsp.window.close()']]

    -- iconos por aplicación (clase = icono de Nerd Font)
    local iconos = {
        firefox = utf8.char(0xF0239),
        kitty   = utf8.char(0xE795),
        code    = utf8.char(0xF0A1E),
        thunar  = utf8.char(0xF024B),
    }
    local mapa = {}
    for clase, icono in pairs(iconos) do
        table.insert(mapa, clase .. "=" .. icono)
    end

    hl.config({
        plugin = {
            hyprbars = {
                spider_style               = true,
                outline_size               = 2,
                ["col.outline"]            = "rgb(154156)",
                footer_height              = 18,
                footer_text                = "SC. APP>PATCH.{app}.EXE",
                ["col.footer_text"]        = "rgb(81B6C6)",
                footer_text_size           = 10,
                footer_text_weight         = "bold",
                ["col.footer"]             = "rgb(154156)",
                bar_rounding               = 6,
                bar_part_of_window         = false,
                app_icons                  = table.concat(mapa, ";"),
                bar_color                  = fondoBarra,
                ["col.text"]               = azulOscuro,
                ["col.icon"]               = azulOscuro,
                ["col.buttons_box"]        = azulOscuro,
                ["col.accent_box"]         = azulClaro,
                ["col.button_hover"]       = azulClaro,
                ["col.close_hover"]        = "rgb(C0392B)",
                accent_box_width           = 90,
                bar_height                 = 22,
                bar_precedence_over_border = false,  -- el borde rodea solo la ventana, no la barra
                bar_text_font              = "JetBrainsMono Nerd Font",
                bar_text_align             = "left",
                bar_text_size              = 10,
                bar_padding                = 8,
                bar_button_padding         = 6,
                button_icon_size           = 120,    -- iconos más grandes
                button_icon_weight         = "heavy",
                on_double_click            = maximizar,
            },
        },
    })

    -- de DERECHA a IZQUIERDA:  + − ×
    hl.plugin.hyprbars.add_button({ fg_color = fondoBarra, bg_color = azulOscuro, size = 18, icon = "×", action = cerrar })
    hl.plugin.hyprbars.add_button({ fg_color = fondoBarra, bg_color = azulOscuro, size = 18, icon = "−", action = restaurar })
    hl.plugin.hyprbars.add_button({ fg_color = fondoBarra, bg_color = azulOscuro, size = 18, icon = "+", action = maximizar })
end

-- ---------- Atajos de los botones de la barra ----------
-- Super + Alt + +  -> maximizar / quitar maximizado
hl.bind("SUPER + ALT + plus", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
-- Super + Alt + -  -> regresar a ventana normal (solo si está maximizada)
hl.bind("SUPER + ALT + minus", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/restaurar.sh"))

-- ---------- Alt + Tab ----------
-- Alt + Tab          -> siguiente ventana
-- Alt + Shift + Tab  -> ventana anterior
hl.bind("ALT + TAB", hl.dsp.exec_cmd("noctalia msg window-switcher hold"))   -- selector de ventanas de Noctalia
hl.bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Explorador de archivos
hl.unbind("SUPER + E")
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))

-- ---------- Ventana maximizada al frente al darle foco ----------
-- Al enfocar una ventana maximizada (clic o Alt+Tab), las demás del escritorio pasan atrás
hl.on("window.active", function(w)
    if not w or not w.fullscreen or w.fullscreen == 0 or not w.workspace then
        return
    end
    for _, otra in ipairs(hl.get_windows()) do
        if otra.address ~= w.address and otra.floating
           and otra.workspace and otra.workspace.id == w.workspace.id then
            hl.dispatch(hl.dsp.window.alter_zorder({ mode = "bottom", window = otra }))
        end
    end
end)

-- ---------- Foco al hacer clic (no al pasar el mouse) ----------
-- 2 = el teclado solo cambia de ventana con clic; el scroll sigue funcionando al pasar el mouse
hl.config({
    input = { follow_mouse = 2 },
})

-- ---------- El mouse no se mueve solo al cambiar de ventana ----------
hl.config({
    cursor = { no_warps = true },
})

-- ---------- Super + Shift + V: todo el escritorio a cuadrícula (o de vuelta a flotante) ----------
local modoCuadricula = {}   -- escritorios en modo cuadrícula
hl.bind("SUPER + SHIFT + V", function()
    local activa = hl.get_active_window()
    if not activa or not activa.workspace then return end
    local idEspacio = activa.workspace.id

    -- ventanas de este escritorio
    local delEspacio, hayFlotantes = {}, false
    for _, w in ipairs(hl.get_windows()) do
        if w.workspace and w.workspace.id == idEspacio then
            table.insert(delEspacio, w)
            if w.floating then hayFlotantes = true end
        end
    end

    -- si hay flotantes -> todas a cuadrícula; si no -> todas flotantes
    local accion = hayFlotantes and "unset" or "set"
    modoCuadricula[idEspacio] = (accion == "unset")
    for _, w in ipairs(delEspacio) do
        if w.fullscreen and w.fullscreen > 0 then
            hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset", window = w }))
        end
        hl.dispatch(hl.dsp.window.float({ action = accion, window = w }))
    end
end)

-- ---------- Noctalia vuelve sola al reconectar el monitor ----------
-- Al cambiar el monitor de entrada (HDMI <-> DP) Noctalia se cierra; al volver el monitor se reinicia.
hl.on("monitor.added", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/noctalia-volver.sh")
end)

-- Ventanas nuevas: si su escritorio está en modo cuadrícula, entran en cuadrícula
hl.on("window.open", function(w)
    if w and w.workspace and modoCuadricula[w.workspace.id] then
        hl.dispatch(hl.dsp.window.float({ action = "unset", window = w }))
    end
end)

-- ---------- Super + V respeta el modo cuadrícula del escritorio ----------
hl.unbind("SUPER + V")
hl.bind("SUPER + V", function()
    local w = hl.get_active_window()
    if not w or not w.workspace then return end

    if modoCuadricula[w.workspace.id] and not w.floating then
        hl.exec_cmd("notify-send -a SpiderOS -t 2500 'Modo cuadrícula' 'Este escritorio está en cuadrícula. Usa Super + Shift + V para cambiarlo.'")
        return
    end

    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
end)

-- Super + C ya no cierra ventanas (se cierra con Super + Q)
hl.unbind("SUPER + C")


-- Evita el parpadeo de las barras (bug de hyprbars) al usar el selector de Alt+Tab.
-- 0.99 = las ventanas inactivas al 99% de opacidad; no se nota a simple vista.
hl.config({ decoration = { inactive_opacity = 0.99 } })

-- Super + P: modo de pantallas (solo una / extender / duplicar)
hl.bind("SUPER + P", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/pantallas.sh"))

-- ---------- Posición de monitores (la guarda Super + P, por modelo de monitor) ----------
pcall(dofile, os.getenv("HOME") .. "/.local/state/spideros/monitores.lua")
