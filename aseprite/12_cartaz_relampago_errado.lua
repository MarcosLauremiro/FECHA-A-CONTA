-- 12 cartaz_relampago_errado
-- Saída: art/esquemas/cartaz_relampago_errado.png (+ .aseprite)   Tamanho: 200x280
-- Lambe-lambe xerox, fundo 2BB3A3. Desenho tosco: raio.
-- Texto (digitar à mão, fonte Anton ou Bebas Neue): "FIZ UM RELÂMPAGO ERRADO, DEVOLVE PFV"
-- Cortes:
--   * TEXTO (oculta): caixa do título em (14,14) 172x76
--   * telefone rasgado: 10 tiras destacáveis com "0000-0000" (2 já arrancadas)
--   * linha pontilhada em y = 212 separando as tiras; tiras com recorte de 1 px entre elas
--   * borda rasgada irregular e 2 pedaços de fita adesiva translúcida nos cantos de cima
-- Camadas: CARTAZ, DESENHO, NUMEROS, FITA, TEXTO (oculta)
--   NUMEROS: telefone fictício "0000-0000" nas tiras desenhados em fonte pixel 3x5 (números decorativos).
--   É a única exceção à regra "sem texto por código"; oculte a camada se preferir digitar.
local W, H = 200, 280
local OUT = "art/esquemas/cartaz_relampago_errado"

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
local BG = hex("2BB3A3")
local INK = hex("1E1E1E")
local BG_DARK = mix(BG, INK, 0.13)
local BG_LIGHT = mix(BG, hex("FFFFFF"), 0.20)
local TAB_Y, NTABS, TAB_W, TAB_X = 212, 10, 19, 5
local TORN = { [3] = true, [7] = true }            -- tiras já arrancadas (índices 0..9)

-- dígitos 3x5 (só números e hífen)
local DIG = {
  ["0"] = { "###", "#.#", "#.#", "#.#", "###" }, ["1"] = { ".#.", "##.", ".#.", ".#.", "###" },
  ["2"] = { "##.", "..#", ".#.", "#..", "###" }, ["3"] = { "##.", "..#", ".#.", "..#", "##." },
  ["4"] = { "#.#", "#.#", "###", "..#", "..#" }, ["5"] = { "###", "#..", "##.", "..#", "##." },
  ["6"] = { ".##", "#..", "###", "#.#", "###" }, ["7"] = { "###", "..#", ".#.", ".#.", ".#." },
  ["8"] = { "###", "#.#", "###", "#.#", "###" }, ["9"] = { "###", "#.#", "###", "..#", "##." },
  ["-"] = { "...", "...", "###", "...", "..." },
}
local function digits(img, s, x, y, c, vertical)
  for i = 1, #s do
    local g = DIG[s:sub(i, i)]
    for gy = 1, 5 do
      for gx = 1, 3 do
        if g[gy]:sub(gx, gx) == "#" then
          if vertical then put(img, x + (5 - gy), y + (i - 1) * 4 + gx - 1, c)  -- girado 90° horário
          else put(img, x + (i - 1) * 4 + gx - 1, y + gy - 1, c) end
        end
      end
    end
  end
end

-- formato do papel: borda rasgada + tiras destacáveis
local function bite(a, s) return hash(a // 3, s, 5) % 3 end
local function inside(x, y)
  if x < bite(y, 1) or x > W - 1 - bite(y, 2) or y < bite(x, 3) then return false end
  if y < TAB_Y then return true end
  if x < TAB_X or x >= TAB_X + NTABS * TAB_W then return false end
  local i = (x - TAB_X) // TAB_W
  local lx = (x - TAB_X) % TAB_W
  if lx == TAB_W - 1 then return false end                   -- corte entre tiras
  if TORN[i] then return y < TAB_Y + 2 + hash(x, i, 9) % 4 end -- toco rasgado
  return y <= H - 1 - hash(x // 2, i, 4) % 3
end

-- CARTAZ -------------------------------------------------------------
local cart = new_layer("CARTAZ")
for y = 0, H - 1 do
  for x = 0, W - 1 do
    if inside(x, y) then
      local c = BG
      local edge = math.min(x, W - 1 - x, y, (y < TAB_Y) and 99 or (H - 1 - y))
      if edge < 5 and rnd(x, y, 2) < 0.6 then c = BG_DARK end        -- toner nas bordas
      if x >= 148 and x <= 150 and y < TAB_Y then c = BG_LIGHT end    -- risco claro da xerox
      if y % 37 == 0 and rnd(x // 4, y, 6) < 0.7 then c = mix(c, INK, 0.06) end
      if y < TAB_Y and rnd(x, y, 8) < 0.006 then c = INK end          -- pintas de toner (fora das tiras)
      put(cart, x, y, c)
    end
  end
end
noise(cart, 0, 0, W, H, 4, 17)
for x = TAB_X, TAB_X + NTABS * TAB_W - 1, 3 do                       -- linha pontilhada
  if inside(x, TAB_Y) then put(cart, x, TAB_Y, INK) end
end
for i = 0, NTABS - 1 do                                              -- marcas de corte
  local xc = TAB_X + (i + 1) * TAB_W - 2
  if not TORN[i] then
    for y = TAB_Y + 2, H - 4, 4 do if inside(xc, y) then put(cart, xc, y, BG_DARK) end end
  end
end

-- DESENHO ------------------------------------------------------------
local D = new_layer("DESENHO")
-- raio
local bolt = { { 112, 100 }, { 76, 154 }, { 98, 154 }, { 84, 200 }, { 128, 138 }, { 105, 138 }, { 124, 100 } }
fill_poly(D, bolt, INK)
poly_line(D, { { 110, 108 }, { 86, 146 } }, BG_LIGHT, 1, false)

-- NUMEROS ------------------------------------------------------------
local num = new_layer("NUMEROS")
for i = 0, NTABS - 1 do
  if not TORN[i] then
    local tx = TAB_X + i * TAB_W
    digits(num, "0000-0000", tx + 6, TAB_Y + 10, INK, true)
  end
end

-- FITA ---------------------------------------------------------------
local fita = new_layer("FITA")
local TAPE = hex("EEE8D8")
for _, t in ipairs({ { 16, 8, -35 }, { 184, 8, 35 } }) do
  draw_rotated(fita, t[1], t[2], t[3], 42, 13, function(lx, ly)
    if (lx < 2 or lx > 39) and rnd(lx, ly, t[3]) < 0.5 then return nil end
    return with_alpha(TAPE, (ly == 0 or ly == 12) and 170 or 140)
  end)
end

-- TEXTO (oculta) -----------------------------------------------------
local txt = new_layer("TEXTO", false)
text_box(txt, 14, 14, 172, 76)

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
