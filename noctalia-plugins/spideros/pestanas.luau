-- SpiderOS: pestañas con las ventanas del escritorio actual (Hyprland)
--
--   ╭ ICONO KITTY  × ╮ ╭ ICONO FIREFOX  × ╮ ╭ + ╮
--
-- Clic en una pestaña: enfoca la ventana. Clic en ×: la cierra.
-- Clic en +: abre el lanzador de Noctalia.

-- ---------- Colores ----------
local COLOR = {
  activa_fondo   = "#266A88",
  activa_texto   = "#D6EAF0",
  inactiva_fondo = "#0D2434",
  inactiva_texto = "#5191A2",
  cerrar_hover   = "#E0585C",
  mas_fondo      = "#0D2434",
  mas_texto      = "#7DB3BD",
}

-- ---------- Medidas ----------
local ESPACIO_ARRIBA = 8    -- espacio libre arriba de las pestañas
local ALTO_PESTANA   = 22   -- alto del contenido de cada pestaña
local BORDE          = 2    -- grosor del borde inferior de la barra
local COLOR_BORDE    = "#266A88"
local RADIO          = 4    -- redondeo de las esquinas de arriba
local SEPARACION     = 3    -- espacio entre pestañas
local TAM_BOTON      = 20   -- tamaño de × y +
local FUENTE         = "JetBrainsMono Nerd Font"

-- ---------- Iconos (Nerd Font) por clase de ventana ----------
local ICONOS = {
  firefox  = 0xF0239,
  kitty    = 0xE795,
  code     = 0xF0A1E,
  thunar   = 0xF024B,
  noctalia = 0xF0C7D,
}
local ICONO_POR_DEFECTO = 0xF2D0

-- ---------- Estado ----------
local ventanas = {}
local orden = {}          -- addresses en el orden en que aparecieron
local activa = nil
local hoverCerrar = nil

local function nombreApp(clase)
  local n = clase or ""
  local ultimo = n:match("([^%.]+)$")
  if ultimo and ultimo ~= "" then n = ultimo end
  n = n:gsub("%s+", ""):upper()
  if n == "" then n = "APP" end
  return n
end

local function icono(clase)
  local c = (clase or ""):lower()
  local ultimo = c:match("([^%.]+)$") or c
  return utf8.char(ICONOS[c] or ICONOS[ultimo] or ICONO_POR_DEFECTO)
end

local function dispatch(expr)
  noctalia.runAsync({ "hyprctl", "dispatch", expr })
end

local function enfocar(address)
  activa = address
  dibujar()
  dispatch(string.format('hl.dsp.focus({ window = "address:%s" })', address))
  dispatch("hl.dsp.window.bring_to_top()")
end

local function cerrar(address)
  dispatch(string.format('hl.dsp.window.close({ window = "address:%s" })', address))
end

-- Pestaña con esquinas redondeadas solo arriba:
-- se dibuja RADIO px más alta de lo visible y la barra recorta la parte de abajo.
local function pestana(key, fondo, onClick, tooltip, contenido)
  local relleno = RADIO - BORDE   -- franja que tapa las esquinas de abajo (y el mismo espacio arriba)
  return ui.column({ key = key, gap = 0 }, {
    -- espacio arriba (transparente)
    ui.box({ height = ESPACIO_ARRIBA, fill = "#00000000" }),
    -- pestaña
    ui.column({
      fill = fondo,
      radius = RADIO,
      height = ALTO_PESTANA,
      gap = 0,
      tooltip = tooltip,
      onClick = onClick,
    }, {
      ui.box({ height = relleno, fill = "#00000000" }),                           -- espacio arriba del contenido
      ui.row({ height = ALTO_PESTANA - 2 * relleno - BORDE, paddingH = 10, gap = 8, align = "center" }, contenido),
      ui.box({ height = relleno, fill = fondo }),                                 -- tapa las esquinas redondeadas de abajo
      ui.box({ height = BORDE, fill = COLOR_BORDE }),                             -- borde inferior de la barra
    }),
  })
end

-- ---------- Dibujo ----------
function dibujar()
  local hijos = {}

  for _, v in ipairs(ventanas) do
    local esActiva = (v.address == activa)
    local fondo = esActiva and COLOR.activa_fondo or COLOR.inactiva_fondo
    local texto = esActiva and COLOR.activa_texto or COLOR.inactiva_texto
    local addr = v.address

    table.insert(hijos, pestana("tab-" .. addr, fondo, function() enfocar(addr) end, v.titulo, {
      ui.label({ text = icono(v.clase), fontFamily = FUENTE, color = texto }),
      ui.label({ text = v.nombre, fontWeight = "bold", color = texto }),
      ui.row({
        key = "x-" .. addr,
        paddingH = 2,
        align = "center",
        onClick = function() cerrar(addr) end,
        onHover = function(estado)
          hoverCerrar = (estado == "true") and addr or nil
          dibujar()
        end,
      }, {
        ui.label({
          text = "×",
          fontSize = TAM_BOTON,
          fontWeight = "bold",
          color = (hoverCerrar == addr) and COLOR.cerrar_hover or texto,
        }),
      }),
    }))
  end

  -- botón +
  table.insert(hijos, pestana("mas", COLOR.mas_fondo, function()
    noctalia.runAsync({ "noctalia", "msg", "panel-toggle", "launcher" })
  end, "Abrir aplicación", {
    ui.label({ text = "+", fontSize = TAM_BOTON, fontWeight = "bold", color = COLOR.mas_texto }),
  }))

  barWidget.render(ui.row({ gap = SEPARACION, align = "start" }, hijos))
end

-- ---------- Datos de Hyprland ----------
local SEPARADOR = "@@SPIDEROS@@"

local SALIDA = nil   -- pantalla de esta barra (ej. HDMI-A-1)

local ordenFijo, siguienteFijo = {}, 0   -- orden fijo: en el que aparecieron las ventanas
local ocupado, esperando = false, 0   -- evita amontonar consultas a Hyprland

-- El filtrado pesado lo hace jq; el plugin solo recibe líneas cortas:
--   A|<dirección ventana activa>
--   W|<dirección>|<clase>|<título>     (solo las del escritorio visible en ESTA pantalla)
local function refrescar()
  if ocupado then
    esperando += 1
    if esperando < 10 then return end   -- si se atoró ~6 s, se da por perdida
  end
  ocupado, esperando = true, 0

  local cmd = [[
ws=$(hyprctl -j monitors | jq -r --arg m "]] .. (SALIDA or "") .. [[" '((.[] | select(.name == $m) | .activeWorkspace.id) // ([.[] | select(.focused)][0].activeWorkspace.id)) // empty' | head -1)
echo "A|$(hyprctl -j activewindow | jq -r '.address // ""')"
[ -n "$ws" ] && hyprctl -j clients | jq -r --argjson ws "$ws" '.[] | select(.workspace.id == $ws and .mapped != false and .hidden != true) | "W|\(.address)|\(.initialClass // .class // "")|\((.title // "") | gsub("\\|"; "/") | gsub("\n"; " "))"'
exit 0
]]

  noctalia.runAsync(cmd, function(r)
    ocupado = false
    if r.exitCode ~= 0 or r.stdout == nil then return end
    local nuevas, act = {}, nil
    for linea in r.stdout:gmatch("[^\n]+") do
      local tipo = linea:sub(1, 1)
      if tipo == "A" then
        act = linea:sub(3)
      elseif tipo == "W" then
        local addr, clase, titulo = linea:match("^W|([^|]*)|([^|]*)|(.*)$")
        if addr then
          table.insert(nuevas, { address = addr, clase = clase, nombre = nombreApp(clase), titulo = titulo })
        end
      end
    end
    for _, v in ipairs(nuevas) do
      if not ordenFijo[v.address] then siguienteFijo += 1; ordenFijo[v.address] = siguienteFijo end
    end
    table.sort(nuevas, function(a, b) return ordenFijo[a.address] < ordenFijo[b.address] end)
    ventanas = nuevas
    activa = (act ~= nil and act ~= "") and act or nil
    dibujar()
  end)
end

function update()
  local okS, n = pcall(function() return barWidget.outputName() end)
  if okS and n and n ~= "" then SALIDA = n end
  noctalia.setUpdateInterval(600)
  refrescar()
end

dibujar()
