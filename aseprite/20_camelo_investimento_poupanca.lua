-- 20 camelo_investimento_poupanca
-- Saída: art/camelo/investimento_poupanca.png (+ .aseprite)   Tamanho: 120x120
-- Porquinho rosa apagado com uma moeda entrando pela fenda. Traço simples.
-- Cortes: 1 PNG, sem guias. Fundo transparente.
-- Camadas: SOMBRA, PORQUINHO, MOEDA
local W, H = 120, 120
local OUT = "art/camelo/investimento_poupanca"

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
local INK = hex("4A3C3E")
local PINK, PINK_SH, PINK_HI, PINK_DK = hex("D8A4A8"), hex("C08A90"), hex("E8C0C2"), hex("B07A80")
local GOLD, GOLD_SH, GOLD_HI = hex("C9B06A"), hex("A08A4E"), hex("E2D29A")

local som = new_layer("SOMBRA")
fill_ellipse(som, 60, 104, 40, 5, hex("3B3445", 60))

local pig = new_layer("PORQUINHO")
-- pernas
for _, x in ipairs({ 32, 46, 70, 84 }) do
  blob(pig, function(px, py) return px >= x and px < x + 9 and py >= 84 and py <= 101 end,
       x, 84, x + 9, 101, PINK_SH, INK)
end
-- orelha de trás
fill_poly(pig, { { 66, 44 }, { 72, 30 }, { 80, 44 } }, INK)
fill_poly(pig, { { 68, 43 }, { 72, 33 }, { 78, 43 } }, PINK_DK)
-- corpo
blob(pig, function(x, y) return in_ellipse(x, y, 58, 68, 40, 29) end, 17, 38, 99, 98, PINK, INK, PINK_SH)
for y = 46, 54 do for x = 34, 60 do                           -- brilho no lombo
  if in_ellipse(x, y, 46, 50, 12, 3) then put(pig, x, y, PINK_HI) end
end end
-- orelha da frente
fill_poly(pig, { { 74, 46 }, { 82, 30 }, { 90, 48 } }, INK)
fill_poly(pig, { { 77, 45 }, { 82, 34 }, { 87, 46 } }, PINK_HI)
-- focinho
blob(pig, function(x, y) return in_ellipse(x, y, 99, 68, 8, 10) end, 90, 57, 108, 79, PINK_SH, INK)
fill_ellipse(pig, 98, 64, 1, 2, INK); fill_ellipse(pig, 98, 72, 1, 2, INK)
fill_circle(pig, 83, 58, 2, INK)                              -- olho
put(pig, 82, 57, hex("FFFFFF"))
arc(pig, 82, 74, 5, 20, 120, INK, 1)                          -- sorriso
arc(pig, 15, 62, 5, -60, 230, INK, 2)                         -- rabinho enrolado
-- fenda no lombo
fill_rect(pig, 46, 39, 24, 4, INK)
fill_rect(pig, 47, 40, 22, 2, hex("2A2224"))

-- MOEDA (de lado, entrando na fenda)
local moe = new_layer("MOEDA")
blob(moe, function(x, y) return in_ellipse(x, y, 58, 26, 5, 13) and y < 40 end, 52, 12, 64, 40, GOLD, INK, GOLD_SH)
fill_rect(moe, 56, 17, 1, 12, GOLD_HI)
fill_rect(moe, 46, 39, 24, 1, INK)                            -- borda da fenda por cima da moeda
line(moe, 70, 12, 74, 8, GOLD_SH, 1); line(moe, 72, 18, 77, 16, GOLD_SH, 1) -- tracinhos de brilho

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
