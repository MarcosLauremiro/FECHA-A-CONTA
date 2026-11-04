-- 01 caixa_moldura
-- Saída: art/caixa/caixa_moldura.png (+ .aseprite)   Tamanho: 1280x720
-- Cortes:
--   * janela vazada 800x360 em (240,60): alfa = 0 (corte principal)
--   * moldura cinza-bege de 8 px em volta da janela
--   * fenda de cartão 90x14 em (1150,30); boca da impressora 300x20 em (490,20)
--   * 4 áreas de tecla 72x56: (24,150) (24,250) (1184,150) (1184,250)
--   * bancada y 560-720 (opaca), borda de 6 px no topo
--   GUIAS (oculta): retângulos da janela, das teclas, da fenda e da impressora.
-- Camadas: CARCACA, DETALHES, BANCADA, GUIAS (oculta)
local W, H = 1280, 720
local OUT = "art/caixa/caixa_moldura"

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
-- paleta (bege-caixa apagado + cinzas)
local CASE, CASE_HI, CASE_SH, CASE_DEEP = hex("D9CBA3"), hex("E6DCBC"), hex("C7B993"), hex("AE9F78")
local EDGE, EDGE_SOFT = hex("6E6450"), hex("948868")
local BEZ, BEZ_HI, BEZ_SH = hex("B8B0A0"), hex("CFC8B8"), hex("948C7C")
local GRAY, GRAY_HI, GRAY_SH = hex("8A8A8A"), hex("B4B4AE"), hex("666662")
local SLOT, SLOT_IN = hex("2A2826"), hex("141312")
local FORM, FORM_LINE, FORM_EDGE = hex("DDD3BD"), hex("D3C8B0"), hex("BFB394")
local FORM_FRONT, FORM_HI = hex("B1A587"), hex("ECE5D3")

local WX, WY, WW, WH = 240, 60, 800, 360
local KEYS = { { 24, 150 }, { 24, 250 }, { 1184, 150 }, { 1184, 250 } }

-- CARCACA ------------------------------------------------------------
local carc = new_layer("CARCACA")
fill_rect(carc, 0, 0, W, 560, CASE)
fill_rect(carc, 2, 2, W - 4, 6, CASE_HI)                 -- topo iluminado
fill_rect(carc, 2, 8, 8, 548, CASE_HI)                   -- lateral esquerda clara
fill_rect(carc, W - 10, 8, 8, 548, CASE_SH)              -- lateral direita sombreada
fill_rect(carc, 2, 528, W - 4, 32, CASE_SH)              -- base da carcaça
fill_rect(carc, 0, 548, W, 12, CASE_DEEP)                -- lábio sobre a bancada
outline_rect(carc, 0, 0, W, 560, EDGE, 2)
fill_rect(carc, 0, 546, W, 2, EDGE)
-- painel frontal levemente saliente em volta da tela
fill_round_rect(carc, 214, 48, 856, 404, 10, CASE_SH)   -- sombra
fill_round_rect(carc, 210, 44, 856, 402, 10, EDGE_SOFT)
fill_round_rect(carc, 211, 45, 854, 400, 9, CASE_HI)
fill_round_rect(carc, 213, 47, 851, 397, 8, CASE)
-- moldura cinza-bege de 8 px em volta da janela
fill_rect(carc, WX - 9, WY - 9, WW + 18, WH + 18, EDGE)
fill_rect(carc, WX - 8, WY - 8, WW + 16, WH + 16, BEZ)
fill_rect(carc, WX - 8, WY - 8, WW + 16, 2, BEZ_HI)
fill_rect(carc, WX - 8, WY - 8, 2, WH + 16, BEZ_HI)
fill_rect(carc, WX - 2, WY - 2, WW + 4, WH + 4, BEZ_SH) -- sombra interna (2 px)
noise(carc, 0, 0, W, 560, 3, 11)
-- janela vazada (alfa = 0)
fill_rect(carc, WX, WY, WW, WH, CLEAR)

-- DETALHES -----------------------------------------------------------
local det = new_layer("DETALHES")
-- boca da impressora: fresta 300x20 em (490,20), bordas metálicas
fill_rect(det, 480, 12, 320, 36, EDGE)
fill_rect(det, 481, 13, 318, 34, GRAY)
fill_rect(det, 481, 13, 318, 2, GRAY_HI)
fill_rect(det, 481, 45, 318, 2, GRAY_SH)
fill_rect(det, 490, 20, 300, 20, SLOT)
fill_rect(det, 492, 26, 296, 8, SLOT_IN)
fill_rect(det, 490, 39, 300, 1, GRAY_SH)
for _, x in ipairs({ 485, 794 }) do
  fill_circle(det, x, 29, 2, GRAY_SH); put(det, x - 1, 28, GRAY_HI)
end
-- fenda de cartão 90x14 em (1150,30), borda escura
fill_rect(det, 1140, 22, 110, 30, EDGE)
fill_rect(det, 1141, 23, 108, 28, GRAY)
fill_rect(det, 1141, 23, 108, 2, GRAY_HI)
fill_rect(det, 1141, 49, 108, 2, GRAY_SH)
fill_rect(det, 1150, 30, 90, 14, SLOT)
fill_rect(det, 1152, 32, 86, 10, SLOT_IN)
fill_rect(det, 1152, 36, 86, 1, hex("3A3834"))
-- áreas de tecla 72x56 (só suporte e moldura)
for _, k in ipairs(KEYS) do
  local x, y = k[1], k[2]
  fill_round_rect(det, x - 4, y - 4, 80, 64, 6, EDGE_SOFT)
  fill_round_rect(det, x - 3, y - 3, 78, 62, 5, CASE_SH)
  fill_round_rect(det, x, y, 72, 56, 4, EDGE)
  fill_round_rect(det, x + 1, y + 1, 70, 54, 3, BEZ)
  fill_rect(det, x + 4, y + 4, 64, 48, BEZ_SH)            -- cavidade da tecla (64x48)
  fill_rect(det, x + 4, y + 4, 64, 2, GRAY_SH)
  fill_rect(det, x + 4, y + 50, 64, 2, BEZ)
end
-- frisos de ventilação e parafusos
for i = 0, 3 do
  fill_rect(det, 560, 474 + i * 10, 160, 3, CASE_DEEP)
  fill_rect(det, 560, 477 + i * 10, 160, 1, CASE_HI)
end
for _, p in ipairs({ { 24, 90 }, { W - 25, 90 }, { 24, 520 }, { W - 25, 520 } }) do
  fill_circle(det, p[1], p[2], 5, GRAY_SH)
  fill_circle(det, p[1], p[2], 4, GRAY)
  line(det, p[1] - 3, p[2] + 2, p[1] + 3, p[2] - 2, GRAY_SH, 1)
end

-- BANCADA ------------------------------------------------------------
local banc = new_layer("BANCADA")
fill_rect(banc, 0, 560, W, 160, FORM)
for i = 0, 26 do                                         -- veios leves
  local y = 572 + i * 5
  for x = 0, W - 1 do
    local yy = y + math.floor(1.5 * math.sin(x / 140 + i * 1.7) + 0.5)
    if rnd(x // 6, i, 3) > 0.25 and yy < 700 then put(banc, x, yy, FORM_LINE) end
  end
end
fill_rect(banc, 0, 560, W, 6, FORM_EDGE)                 -- borda de 6 px no topo
fill_rect(banc, 0, 560, W, 1, FORM_HI)
fill_rect(banc, 0, 565, W, 1, EDGE_SOFT)
for y = 566, 575 do                                      -- sombra da carcaça
  for x = 0, W - 1 do blend(banc, x, y, hex("6E6450"), 0.22 * (575 - y) / 9) end
end
fill_rect(banc, 0, 702, W, 18, FORM_FRONT)                -- frente da bancada
fill_rect(banc, 0, 702, W, 1, FORM_HI)
noise(banc, 0, 560, W, 160, 2, 13)

-- GUIAS (oculta) -----------------------------------------------------
local gui = new_layer("GUIAS", false)
outline_rect(gui, WX, WY, WW, WH, GUIDE_COL, 1)
for _, k in ipairs(KEYS) do outline_rect(gui, k[1], k[2], 72, 56, GUIDE_COL, 1) end
outline_rect(gui, 1150, 30, 90, 14, GUIDE_COL, 1)
outline_rect(gui, 490, 20, 300, 20, GUIDE_COL, 1)
outline_rect(gui, 0, 560, W, 160, GUIDE_COL, 1)

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
