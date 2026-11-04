-- 16 camelo_fundo
-- Saída: art/camelo/camelo_fundo.png (+ .aseprite)   Tamanho: 1280x720
-- Banca de feira: lona azul (#2F6DB5) com listras brancas e franjas no topo,
-- dois pilares de madeira nas laterais, barra horizontal em y = 200 com 6 ganchos
-- metálicos e área central clara para os itens. Opaco.
-- Cortes: GUIAS (oculta) com os 6 ganchos (cruz no ponto de pendurar) e a linha da barra.
--   Pontos dos ganchos (x, y): 251,224  406,224  562,224  718,224  874,224  1029,224
-- Camadas: FUNDO, LONA, SOMBRA_LONA, PILARES, BARRA, GUIAS (oculta)
local W, H = 1280, 720
local OUT = "art/camelo/camelo_fundo"

------------------------------------------------------------------------
-- Helpers (cópia local: cada script é independente)
-- Desenho só com Image:drawPixel / Image:getPixel e laços.
------------------------------------------------------------------------
local pc = app.pixelColor
local function hex(h, a)
  h = h:gsub("#", "")
  return pc.rgba(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16), a or 255)
end
local CLEAR = pc.rgba(0, 0, 0, 0)
local GUIDE_COL = hex("19C3FF")   -- camada GUIAS (oculta)
local TEXT_COL = hex("FF2BD6")    -- camada TEXTO (oculta)

-- ruído determinístico (mesmo resultado a cada execução)
local function hash(x, y, s)
  local h = (math.floor(x) * 374761393 + math.floor(y) * 668265263 + (s or 0) * 982451653) & 0xffffffff
  h = ((h ~ (h >> 13)) * 1274126177) & 0xffffffff
  return (h ~ (h >> 16)) & 0xffffffff
end
local function rnd(x, y, s) return (hash(x, y, s) % 10000) / 10000 end

local function put(img, x, y, c)
  x, y = math.floor(x), math.floor(y)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end
end
local function get(img, x, y)
  x, y = math.floor(x), math.floor(y)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then return img:getPixel(x, y) end
  return CLEAR
end
local function mix(c1, c2, t)
  local function m(a, b) return math.floor(a + (b - a) * t + 0.5) end
  return pc.rgba(m(pc.rgbaR(c1), pc.rgbaR(c2)), m(pc.rgbaG(c1), pc.rgbaG(c2)),
                 m(pc.rgbaB(c1), pc.rgbaB(c2)), pc.rgbaA(c1))
end
local function with_alpha(c, a) return pc.rgba(pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), a) end
-- pinta c por cima do pixel existente com opacidade a (0..1), mantendo o alfa
local function blend(img, x, y, c, a)
  local d = get(img, x, y)
  if pc.rgbaA(d) == 0 then return end
  put(img, x, y, with_alpha(mix(d, c, a), pc.rgbaA(d)))
end

local function fill_rect(img, x, y, w, h, c)
  for yy = y, y + h - 1 do for xx = x, x + w - 1 do put(img, xx, yy, c) end end
end
local function outline_rect(img, x, y, w, h, c, t)
  t = t or 1
  fill_rect(img, x, y, w, t, c); fill_rect(img, x, y + h - t, w, t, c)
  fill_rect(img, x, y, t, h, c); fill_rect(img, x + w - t, y, t, h, c)
end
local function dashed_rect(img, x, y, w, h, c, dash)
  dash = dash or 4
  for i = 0, w - 1 do
    if (i // dash) % 2 == 0 then put(img, x + i, y, c); put(img, x + i, y + h - 1, c) end
  end
  for i = 0, h - 1 do
    if (i // dash) % 2 == 0 then put(img, x, y + i, c); put(img, x + w - 1, y + i, c) end
  end
end
-- caixa de texto (camada TEXTO): retângulo tracejado + marca no canto
local function text_box(img, x, y, w, h)
  dashed_rect(img, x, y, w, h, TEXT_COL, 4)
  fill_rect(img, x, y, 3, 3, TEXT_COL)
end
local function in_round_rect(px, py, x, y, w, h, r)
  if px < x or py < y or px >= x + w or py >= y + h then return false end
  local cx = math.max(x + r, math.min(px + 0.5, x + w - r))
  local cy = math.max(y + r, math.min(py + 0.5, y + h - r))
  return (px + 0.5 - cx) ^ 2 + (py + 0.5 - cy) ^ 2 <= r * r
end
local function fill_round_rect(img, x, y, w, h, r, c)
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do
      if in_round_rect(xx, yy, x, y, w, h, r) then put(img, xx, yy, c) end
    end
  end
end
local function fill_circle(img, cx, cy, r, c)
  for y = math.floor(cy - r - 1), math.ceil(cy + r + 1) do
    for x = math.floor(cx - r - 1), math.ceil(cx + r + 1) do
      if (x - cx) ^ 2 + (y - cy) ^ 2 <= r * r + r * 0.5 then put(img, x, y, c) end
    end
  end
end
local function ring(img, cx, cy, r, t, c)
  local ri = r - t
  for y = math.floor(cy - r - 1), math.ceil(cy + r + 1) do
    for x = math.floor(cx - r - 1), math.ceil(cx + r + 1) do
      local d2 = (x - cx) ^ 2 + (y - cy) ^ 2
      if d2 <= r * r + r * 0.5 and d2 > ri * ri + ri * 0.5 then put(img, x, y, c) end
    end
  end
end
local function in_ellipse(x, y, cx, cy, rx, ry)
  return ((x - cx) / (rx + 0.5)) ^ 2 + ((y - cy) / (ry + 0.5)) ^ 2 <= 1
end
local function fill_ellipse(img, cx, cy, rx, ry, c)
  for y = math.floor(cy - ry - 1), math.ceil(cy + ry + 1) do
    for x = math.floor(cx - rx - 1), math.ceil(cx + rx + 1) do
      if in_ellipse(x, y, cx, cy, rx, ry) then put(img, x, y, c) end
    end
  end
end
local function ring_ellipse(img, cx, cy, rx, ry, t, c)
  for y = math.floor(cy - ry - 1), math.ceil(cy + ry + 1) do
    for x = math.floor(cx - rx - 1), math.ceil(cx + rx + 1) do
      if in_ellipse(x, y, cx, cy, rx, ry) and not in_ellipse(x, y, cx, cy, rx - t, ry - t) then
        put(img, x, y, c)
      end
    end
  end
end
-- linha de Bresenham com pincel quadrado de espessura t
local function line(img, x0, y0, x1, y1, c, t)
  t = t or 1
  x0, y0 = math.floor(x0 + 0.5), math.floor(y0 + 0.5)
  x1, y1 = math.floor(x1 + 0.5), math.floor(y1 + 0.5)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  local o = (t - 1) // 2
  while true do
    if t == 1 then put(img, x0, y0, c) else fill_rect(img, x0 - o, y0 - o, t, t, c) end
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end
-- linha "à mão": pequenos desvios no meio do traço
local function wobble_line(img, x0, y0, x1, y1, c, t, seed)
  local len = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
  local n = math.max(2, math.floor(len / 14))
  local nx, ny = -(y1 - y0) / math.max(len, 1), (x1 - x0) / math.max(len, 1)
  local lx, ly = x0, y0
  for i = 1, n do
    local f = i / n
    local j = (i < n) and (rnd(i, math.floor(len), seed or 1) - 0.5) * 2.4 or 0
    local x, y = x0 + (x1 - x0) * f + nx * j, y0 + (y1 - y0) * f + ny * j
    line(img, lx, ly, x, y, c, t)
    lx, ly = x, y
  end
end
-- arco em graus (0 = direita, 90 = baixo), de a0 até a1
local function arc(img, cx, cy, r, a0, a1, c, t)
  local steps = math.max(8, math.floor(math.abs(a1 - a0) / 360 * 2 * math.pi * r / 2))
  local lx, ly
  for i = 0, steps do
    local a = math.rad(a0 + (a1 - a0) * i / steps)
    local x, y = cx + r * math.cos(a), cy + r * math.sin(a)
    if lx then line(img, lx, ly, x, y, c, t) end
    lx, ly = x, y
  end
end
local function in_poly(pts, x, y)
  local inside, j = false, #pts
  local px, py = x + 0.5, y + 0.5
  for i = 1, #pts do
    local xi, yi, xj, yj = pts[i][1], pts[i][2], pts[j][1], pts[j][2]
    if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then inside = not inside end
    j = i
  end
  return inside
end
local function fill_poly(img, pts, c)
  local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
  for _, p in ipairs(pts) do
    x0 = math.min(x0, p[1]); y0 = math.min(y0, p[2]); x1 = math.max(x1, p[1]); y1 = math.max(y1, p[2])
  end
  for y = math.floor(y0), math.ceil(y1) do
    for x = math.floor(x0), math.ceil(x1) do
      if in_poly(pts, x, y) then put(img, x, y, c) end
    end
  end
end
local function poly_line(img, pts, c, t, closed, seed)
  for i = 1, #pts - 1 do
    if seed then wobble_line(img, pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2], c, t, seed + i)
    else line(img, pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2], c, t) end
  end
  if closed then
    local a, b = pts[#pts], pts[1]
    if seed then wobble_line(img, a[1], a[2], b[1], b[2], c, t, seed) else line(img, a[1], a[2], b[1], b[2], c, t) end
  end
end
-- forma por predicado com contorno de 1 px e sombra na borda de baixo/direita
local function blob(img, pred, x0, y0, x1, y1, fill, outline, shade)
  for y = y0 - 1, y1 + 1 do
    for x = x0 - 1, x1 + 1 do
      if pred(x, y) then
        local c = fill
        if shade and (not pred(x, y + 1) or not pred(x, y + 2) or not pred(x + 1, y)) then c = shade end
        put(img, x, y, c)
      elseif outline and (pred(x - 1, y) or pred(x + 1, y) or pred(x, y - 1) or pred(x, y + 1)) then
        put(img, x, y, outline)
      end
    end
  end
end
-- desenha um retângulo local w x h girado 'deg' graus em torno de (cx, cy);
-- fn(lx, ly) devolve a cor do pixel local ou nil (amostragem por pixel, sem suavização)
local function draw_rotated(img, cx, cy, deg, w, h, fn)
  local a = math.rad(deg)
  local ca, sa = math.cos(a), math.sin(a)
  local R = math.ceil(math.sqrt(w * w + h * h) / 2) + 1
  for y = math.floor(cy - R), math.ceil(cy + R) do
    for x = math.floor(cx - R), math.ceil(cx + R) do
      local dx, dy = x + 0.5 - cx, y + 0.5 - cy
      local lx = dx * ca + dy * sa + w / 2
      local ly = -dx * sa + dy * ca + h / 2
      if lx >= 0 and ly >= 0 and lx < w and ly < h then
        local c = fn(math.floor(lx), math.floor(ly))
        if c then put(img, x, y, c) end
      end
    end
  end
end
-- grão de papel: varia levemente o RGB dos pixels opacos da região
local function noise(img, x, y, w, h, amp, seed)
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do
      local c = get(img, xx, yy)
      if pc.rgbaA(c) > 0 then
        local n = math.floor((rnd(xx, yy, seed or 7) - 0.5) * 2 * amp + 0.5)
        local function cl(v) return math.max(0, math.min(255, v + n)) end
        put(img, xx, yy, pc.rgba(cl(pc.rgbaR(c)), cl(pc.rgbaG(c)), cl(pc.rgbaB(c)), pc.rgbaA(c)))
      end
    end
  end
end

------------------------------------------------------------------------
-- Sprite e camadas
------------------------------------------------------------------------
local spr = Sprite(W, H, ColorMode.RGB)
if spr.layers[1].isBackground then app.command.LayerFromBackground() end
local LAYERS = {}
-- cria camada nomeada (de baixo para cima) e devolve a imagem onde desenhar
local function new_layer(name, visible)
  local l = (#LAYERS == 0) and spr.layers[1] or spr:newLayer()
  l.name = name
  l.isVisible = (visible ~= false)
  local img = Image(W, H, ColorMode.RGB)
  LAYERS[#LAYERS + 1] = { layer = l, img = img }
  return img
end
local WALL, WALL_SH = hex("CFC6B2"), hex("BDB39D")
local PANEL, PANEL_EDGE = hex("ECE4D0"), hex("D2C8B0")
local BLUE, BLUE_SH, WHITE, WHITE_SH = hex("2F6DB5"), hex("285E9C"), hex("E9ECEE"), hex("CDD3D8")
local WOOD, WOOD_HI, WOOD_SH, WOOD_LINE = hex("8A6A48"), hex("A6845C"), hex("6E5238"), hex("4A3A2A")
local CRATE, CRATE_SH = hex("B39368"), hex("94764E")
local METAL, METAL_HI, METAL_SH = hex("8A8A8A"), hex("BDBDB8"), hex("5E5E5C")
local BAR_Y = 200
local HOOKS = {}
for i = 1, 6 do HOOKS[i] = math.floor(95 + 1090 * i / 7 + 0.5) end

-- FUNDO --------------------------------------------------------------
local fun = new_layer("FUNDO")
fill_rect(fun, 0, 0, W, H, WALL)
for x = 0, W - 1, 64 do fill_rect(fun, x, 0, 1, H, WALL_SH) end   -- tábuas da parede
fill_rect(fun, 130, 214, 1020, 412, PANEL_EDGE)                   -- área central clara
fill_rect(fun, 134, 218, 1012, 404, PANEL)
-- caixotes de feira como bancada
fill_rect(fun, 0, 628, W, 92, CRATE)
for y = 628, 719, 23 do fill_rect(fun, 0, y, W, 2, CRATE_SH) end
for x = 0, W - 1, 160 do fill_rect(fun, x, 628, 3, 92, CRATE_SH) end
fill_rect(fun, 0, 626, W, 2, WOOD_LINE)
noise(fun, 0, 0, W, H, 3, 81)

-- LONA ---------------------------------------------------------------
local lona = new_layer("LONA")
local function sag(x) return 140 + math.floor(10 * math.abs(math.sin(math.pi * x / 213)) + 0.5) end
for x = 0, W - 1 do
  local stripe = ((x // 64) % 2 == 0)
  local base, sh = stripe and BLUE or WHITE, stripe and BLUE_SH or WHITE_SH
  local bottom = sag(x)
  for y = 0, bottom do
    local c = base
    if y > bottom - 12 or y < 6 then c = sh end
    put(lona, x, y, c)
  end
  -- franjas: triângulos de 20 px
  local fx = x % 20
  local fh = 16 - math.abs(fx - 10) * 16 // 10
  for y = bottom + 1, bottom + fh do put(lona, x, y, ((x // 20) % 2 == 0) and BLUE_SH or WHITE_SH) end
  put(lona, x, bottom + 1, hex("1F3F66"))
end
noise(lona, 0, 0, W, 170, 3, 82)
local sombra = new_layer("SOMBRA_LONA")
for x = 0, W - 1 do
  local b = sag(x) + 1
  for y = b, b + 24 do put(sombra, x, y, hex("1E1E1E", math.floor(60 * (1 - (y - b) / 24)))) end
end

-- PILARES ------------------------------------------------------------
local pil = new_layer("PILARES")
for _, x0 in ipairs({ 40, 1185 }) do
  fill_rect(pil, x0, 0, 56, H, WOOD_LINE)
  fill_rect(pil, x0 + 2, 0, 52, H, WOOD)
  fill_rect(pil, x0 + 2, 0, 6, H, WOOD_HI)
  fill_rect(pil, x0 + 46, 0, 8, H, WOOD_SH)
  for k = 0, 9 do                                             -- veios
    local gx = x0 + 12 + (k * 7) % 32
    local gy = (k * 97) % 600
    fill_rect(pil, gx, gy, 1, 60 + (k * 13) % 50, WOOD_SH)
  end
  fill_circle(pil, x0 + 28, 120, 3, WOOD_SH)                 -- nó da madeira
end
noise(pil, 0, 0, W, H, 3, 83)

-- BARRA E GANCHOS ----------------------------------------------------
local bar = new_layer("BARRA")
fill_rect(bar, 96, BAR_Y - 5, 1089, 11, METAL_SH)
fill_rect(bar, 96, BAR_Y - 4, 1089, 8, METAL)
fill_rect(bar, 96, BAR_Y - 4, 1089, 2, METAL_HI)
for _, x0 in ipairs({ 86, 1177 }) do                          -- abraçadeiras nos pilares
  fill_rect(bar, x0, BAR_Y - 9, 18, 19, METAL_SH)
  fill_rect(bar, x0 + 2, BAR_Y - 7, 14, 15, METAL)
  fill_circle(bar, x0 + 9, BAR_Y, 2, METAL_SH)
end
for _, hx in ipairs(HOOKS) do
  arc(bar, hx, BAR_Y - 1, 6, 180, 360, METAL_SH, 2)          -- volta sobre a barra
  line(bar, hx + 6, BAR_Y - 1, hx + 6, BAR_Y + 18, METAL_SH, 2)
  arc(bar, hx, BAR_Y + 18, 6, 0, 160, METAL_SH, 2)            -- curva do gancho
  put(bar, hx - 5, BAR_Y + 14, METAL_HI)
  put(bar, hx + 6, BAR_Y + 4, METAL_HI)
end

-- GUIAS (oculta) -----------------------------------------------------
local gui = new_layer("GUIAS", false)
fill_rect(gui, 96, BAR_Y, 1089, 1, GUIDE_COL)
for _, hx in ipairs(HOOKS) do
  local hy = BAR_Y + 24
  line(gui, hx - 4, hy, hx + 4, hy, GUIDE_COL, 1)
  line(gui, hx, hy - 4, hx, hy + 4, GUIDE_COL, 1)
end
outline_rect(gui, 134, 218, 1012, 404, GUIDE_COL, 1)

------------------------------------------------------------------------
-- Montagem e exportação
------------------------------------------------------------------------
for _, L in ipairs(LAYERS) do spr:newCel(L.layer, 1, L.img, Point(0, 0)) end
local base = app.fs.joinPath(app.fs.currentPath, OUT)
local dir = app.fs.filePath(base)
if not app.fs.isDirectory(dir) then app.fs.makeAllDirectories(dir) end
spr:saveAs(base .. ".aseprite")   -- fonte editável (GUIAS/TEXTO ficam ocultas)
spr:saveCopyAs(base .. ".png")    -- PNG achatado: só camadas visíveis
print("ok: " .. base .. ".png")
