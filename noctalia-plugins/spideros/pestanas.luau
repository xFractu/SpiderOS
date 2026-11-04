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

local function refrescar()
  noctalia.runAsync(
    "hyprctl -j clients; echo '" .. SEPARADOR .. "'; hyprctl -j monitors; echo '" .. SEPARADOR .. "'; hyprctl -j activewindow",
    function(r)
      if r.exitCode ~= 0 or r.stdout == nil then return end
      local partes = {}
      for parte in (r.stdout .. SEPARADOR):gmatch("(.-)" .. SEPARADOR) do
        table.insert(partes, parte)
      end

      local clientes = noctalia.json.decode(partes[1] or "")
      local espacio  = noctalia.json.decode(partes[2] or "")
      local ventana  = noctalia.json.decode(partes[3] or "")
      if type(clientes) ~= "table" then return end

      local idEspacio = nil
      if type(espacio) == "table" then
        for _, m in ipairs(espacio) do
          if (SALIDA and m.name == SALIDA) or (not SALIDA and m.focused) then
            idEspacio = m.activeWorkspace and m.activeWorkspace.id or nil
          end
        end
      end
      local nuevas = {}
      for _, c in ipairs(clientes) do
        local enEspacio = (idEspacio == nil) or (c.workspace and c.workspace.id == idEspacio)
        if c.mapped ~= false and c.hidden ~= true and enEspacio then
          local clase = c.initialClass or c.class or ""
          table.insert(nuevas, {
            address = c.address,
            clase = clase,
            nombre = nombreApp(clase),
            titulo = c.title or "",
          })
        end
      end

      -- conservar el orden: las que ya estaban mantienen su lugar, las nuevas van al final
      local porAddr = {}
      for _, v in ipairs(nuevas) do porAddr[v.address] = v end
      local ordenNuevo, ordenadas = {}, {}
      for _, addr in ipairs(orden) do
        if porAddr[addr] then
          table.insert(ordenNuevo, addr)
          table.insert(ordenadas, porAddr[addr])
          porAddr[addr] = nil
        end
      end
      for _, v in ipairs(nuevas) do
        if porAddr[v.address] then
          table.insert(ordenNuevo, v.address)
          table.insert(ordenadas, v)
        end
      end
      orden = ordenNuevo
      ventanas = ordenadas
      activa = (type(ventana) == "table") and ventana.address or nil
      dibujar()
    end
  )
end

function update()
  local okS, n = pcall(function() return barWidget.outputName() end)
  if okS and n and n ~= "" then SALIDA = n end
  noctalia.setUpdateInterval(400)
  refrescar()
end

dibujar()
