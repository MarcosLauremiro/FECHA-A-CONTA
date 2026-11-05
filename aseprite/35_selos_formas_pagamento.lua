-- 35_selos_formas_pagamento.lua
-- Gera 12 artes de "Fecha a Conta" numa só execução (Aseprite, modo batch):
--   Aseprite.exe -b --script aseprite/35_selos_formas_pagamento.lua   (rodar na raiz do projeto)
-- Cada arte: Sprite com o tamanho exato e fundo transparente, desenho só com
-- Image:drawPixel e laços, .aseprite editável + .png exportado com saveCopyAs.
-- Sem arquivos externos, sem aleatoriedade (ruído por hash com semente fixa).
--
-- PARTE 1 – cédulas neutras, 120x180 px, art/notas/neutras/
--   Papel creme #F4EDD9, moldura/números/textos em tinta escura, sem cor de
--   forma de pagamento e sem selo. Fora da cédula (cantos recortados) = transparente.
--   Os bichos usam exatamente o mesmo código de desenho das frentes coloridas
--   (notas_dinheiro.lua / frente_<valor>_dinheiro): não foram redesenhados.
--   nota_1.png    R$ 1   sabiá
--   nota_2.png    R$ 2   tatu
--   nota_5.png    R$ 5   quati
--   nota_10.png   R$ 10  bicho-preguiça
--   nota_20.png   R$ 20  tamanduá
--   nota_50.png   R$ 50  capivara
--   nota_100.png  R$ 100 boto-cor-de-rosa
--   nota_200.png  R$ 200 jacaré
--   Camada: CEDULA. Nota desenhada deitada (180x120) e girada 90° anti-horário.
--
-- PARTE 2 – selos de forma de pagamento, 40x40 px RGBA, art/notas/selos/
--   Disco de 36 px de diâmetro centrado, contorno de 2 px #1E1E1E, borda levemente
--   irregular, sem anti-aliasing. Ícone de 16–20 px em #FFF8E7 com contorno de 1 px
--   #1E1E1E. Sem texto. Camadas: DISCO, ICONE.
--   selo_dinheiro.png   disco #3F8F4E, moeda com cifrão (18x18)
--   selo_relampago.png  disco #E8B923, raio inclinado (15x20)
--   selo_debito.png     disco #2F6FB0, cartão 20x14 com faixa no topo e chip pequeno
--   selo_credito.png    disco #7A4FA3, cartão 20x14 com duas listras horizontais
--
-- Saídas: 12 PNG + 12 .aseprite. Pastas criadas se não existirem.

-- nome fictício no lado do título da cédula (regra: nada de "BANCO CENTRAL" nem banco real)
local TITLE_1, TITLE_2 = "FECHA A", "CONTA"

local NW, NH = 120, 180    -- cédula em pé
local LW, LH = 180, 120    -- cédula deitada (área de desenho)

-- nomes com acento usam marcadores: a = Á, e = É, c = Ç
local NOTES = {
  { value = 1,   word = "UM REAL",         name = "SABIa",    animal = "sabia" },
  { value = 2,   word = "DOIS REAIS",      name = "TATU",     animal = "tatu" },
  { value = 5,   word = "CINCO REAIS",     name = "QUATI",    animal = "quati" },
  { value = 10,  word = "DEZ REAIS",       name = "PREGUIcA", animal = "preguica" },
  { value = 20,  word = "VINTE REAIS",     name = "TAMANDUa", animal = "tamandua" },
  { value = 50,  word = "CINQUENTA REAIS", name = "CAPIVARA", animal = "capivara" },
  { value = 100, word = "CEM REAIS",       name = "BOTO",     animal = "boto" },
  { value = 200, word = "DUZENTOS REAIS",  name = "JACARe",   animal = "jacare" },
}

------------------------------------------------------------------------
-- Cores
------------------------------------------------------------------------
local function hexToRGB(h)
  return { tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16) }
end
local function mix(a, b, t)
  return {
    math.floor(a[1] + (b[1] - a[1]) * t + 0.5),
    math.floor(a[2] + (b[2] - a[2]) * t + 0.5),
    math.floor(a[3] + (b[3] - a[3]) * t + 0.5),
  }
end

local CREAM   = hexToRGB("f4efd6")
local OUTLINE = hexToRGB("3b3445") -- contorno padrão do projeto
local WHITE   = hexToRGB("ffffff")

-- paleta NEUTRA: papel creme #F4EDD9 e tinta escura (sem cor de forma de pagamento)
local function makePalette()
  local p = {}
  p.paper   = hexToRGB("F4EDD9")   -- fundo da cédula
  p.paperLo = hexToRGB("E3D9C0")   -- pintas escuras do papel
  p.paperHi = hexToRGB("FAF6EA")   -- pintas claras do papel
  p.dark    = hexToRGB("1E1E1E")   -- tinta: contornos, textos
  p.mid     = hexToRGB("4A443D")   -- tinta: moldura e série
  p.midLo   = hexToRGB("3E3832")   -- textura da moldura
  p.light   = hexToRGB("D8CDB4")   -- miolo dos números e ovais
  p.lighter = hexToRGB("EAE2CC")   -- interior do medalhão
  return p
end

-- cores naturais dos animais (fixas)
local C = {}
for k, v in pairs({
  out = "3b3445", eye = "2a2430", white = "fffaf0",
  -- sabiá
  sbBack = "9c8460", sbBackS = "7a6448", sbBackH = "b49c74",
  sbBelly = "e08a3c", sbBellyS = "c06a2c", sbBellyH = "f4a85a",
  sbBeak = "d8b048", sbRing = "f0c850", sbThroat = "efe2bc",
  wood = "8a5c3a", woodS = "674230", woodH = "a8764c",
  leaf = "5c9a3c", leafS = "458035", leafH = "7ab048",
  -- tatu
  ttShell = "c8a284", ttShellS = "a2806a", ttShellH = "e2c4a6", ttBand = "8a6a56",
  ttSkin = "e0b8a0", ttSkinS = "c09480", ttEar = "e89a92",
  -- quati
  qtFur = "b06a3a", qtFurS = "8a4e2c", qtFurH = "c88452", qtDark = "5e3a28",
  qtLight = "e0aa74", qtMark = "f2e6d0",
  -- preguiça
  pgFur = "bca88a", pgFurS = "9a8870", pgFurH = "d4c4a6", pgFace = "efe4cc",
  pgMask = "5a4434", pgClaw = "f2e8d4",
  -- tamanduá
  tmFur = "a49a8a", tmFurS = "82796c", tmFurH = "c0b8a8", tmTail = "6e6458", tmTailS = "52493f",
  tmStripe = "2e2a30", tmWhite = "f2eee2", tmLeg = "dcd4c4",
  -- capivara
  cpFur = "9a6a40", cpFurS = "7a5232", cpFurH = "b6844f", cpDark = "5c3c26",
  -- boto
  btPink = "f0a2b2", btPinkS = "d27c90", btPinkH = "ffcad4",
  water = "4a8ca4", waterS = "3a7090", waterH = "7cc4d4", foam = "dff4f6",
  -- jacaré
  jcGreen = "4e8a3a", jcGreenS = "3a6a2c", jcGreenH = "6eaa4c", jcBelly = "d6d49a",
  jcEye = "e8c040", jcTooth = "fbf8ec",
}) do C[k] = hexToRGB(v) end

------------------------------------------------------------------------
-- Ruído determinístico
------------------------------------------------------------------------
local function hash(x, y, s)
  local h = (x * 374761393 + y * 668265263 + s * 982451653) & 0xffffffff
  h = ((h ~ (h >> 13)) * 1274126177) & 0xffffffff
  return (h ~ (h >> 16)) & 0xffffffff
end

------------------------------------------------------------------------
-- Fonte pixel 5 px (largura variável). a=Á e=É c=Ç
------------------------------------------------------------------------
local FONT = {
  A = { ".#.", "#.#", "###", "#.#", "#.#" },
  B = { "##.", "#.#", "##.", "#.#", "##." },
  C = { ".##", "#..", "#..", "#..", ".##" },
  D = { "##.", "#.#", "#.#", "#.#", "##." },
  E = { "###", "#..", "##.", "#..", "###" },
  G = { ".##", "#..", "#.#", "#.#", ".##" },
  I = { "###", ".#.", ".#.", ".#.", "###" },
  J = { "..#", "..#", "..#", "#.#", ".#." },
  L = { "#..", "#..", "#..", "#..", "###" },
  M = { "#...#", "##.##", "#.#.#", "#...#", "#...#" },
  N = { "#..#", "##.#", "#.##", "#..#", "#..#" },
  O = { ".#.", "#.#", "#.#", "#.#", ".#." },
  P = { "##.", "#.#", "##.", "#..", "#.." },
  Q = { ".#.", "#.#", "#.#", "#.#", ".##" },
  R = { "##.", "#.#", "##.", "#.#", "#.#" },
  S = { ".##", "#..", ".#.", "..#", "##." },
  T = { "###", ".#.", ".#.", ".#.", ".#." },
  U = { "#.#", "#.#", "#.#", "#.#", "###" },
  V = { "#.#", "#.#", "#.#", "#.#", ".#." },
  Z = { "###", "..#", ".#.", "#..", "###" },
  F = { "###", "#..", "##.", "#..", "#.." },
  H = { "#.#", "#.#", "###", "#.#", "#.#" },
  ["0"] = { "###", "#.#", "#.#", "#.#", "###" },
  ["1"] = { ".#.", "##.", ".#.", ".#.", "###" },
  ["2"] = { "##.", "..#", ".#.", "#..", "###" },
  ["3"] = { "##.", "..#", ".#.", "..#", "##." },
  ["4"] = { "#.#", "#.#", "###", "..#", "..#" },
  ["5"] = { "###", "#..", "##.", "..#", "##." },
  ["6"] = { ".##", "#..", "###", "#.#", "###" },
  ["7"] = { "###", "..#", ".#.", ".#.", ".#." },
  ["8"] = { "###", "#.#", "###", "#.#", "###" },
  ["9"] = { "###", "#.#", "###", "..#", "##." },
  [" "] = { "..", "..", "..", "..", ".." },
}
-- acentos: base + pixels extras (x, y relativos; y<0 acima, y>4 abaixo)
local ACCENT = {
  a = { base = "A", px = { { 2, -1 } } },
  e = { base = "E", px = { { 2, -1 } } },
  c = { base = "C", px = { { 1, 5 }, { 0, 6 } } },
}
local function glyph(ch)
  if ACCENT[ch] then return FONT[ACCENT[ch].base], ACCENT[ch].px end
  return FONT[ch], nil
end
local function textWidth(s)
  local w = 0
  for i = 1, #s do w = w + #glyph(s:sub(i, i))[1] + 1 end
  return w - 1
end

------------------------------------------------------------------------
-- Algarismos serifados grossos (cantos h13 e grande h18)
------------------------------------------------------------------------
local DIGITS_SMALL = {
  ["1"] = { "..####..", ".#####..", "######..", "#.####..", "..####..", "..####..", "..####..",
            "..####..", "..####..", "..####..", "..####..", ".######.", "########" },
  ["0"] = { "..#####..", ".#######.", "####.####", "###...###", "###...###", "###...###", "###...###",
            "###...###", "###...###", "###...###", "####.####", ".#######.", "..#####.." },
  ["2"] = { "..#####..", ".#######.", "####.####", "###...###", "......###", ".....####", "...#####.",
            "..#####..", ".####....", "####.....", "###....##", "#########", "#########" },
  ["5"] = { "#########", "#########", "###......", "###......", "#######..", "########.", "......###",
            "......###", "......###", "###...###", "####.####", ".#######.", "..#####.." },
}
local DIGITS_BIG = {
  ["1"] = { "...#####..", "..######..", ".#######..", "########..", "#..#####..", "...#####..",
            "...#####..", "...#####..", "...#####..", "...#####..", "...#####..", "...#####..",
            "...#####..", "...#####..", "...#####..", "..#######.", "##########", "##########" },
  ["0"] = { "...#####...", ".#########.", ".#########.", "####...####", "####...####", "###.....###",
            "###.....###", "###.....###", "###.....###", "###.....###", "###.....###", "###.....###",
            "###.....###", "####...####", "####...####", ".#########.", ".#########.", "...#####..." },
  ["2"] = { "..#######..", ".#########.", "####...####", "###.....###", "###.....###", "........###",
            ".......####", "......####.", ".....####..", "....####...", "...####....", "..####.....",
            ".####......", "####.......", "###........", "###########", "###########", "###########" },
  ["5"] = { "###########", "###########", "###........", "###........", "###........", "#########..",
            "##########.", ".......####", "........###", "........###", "........###", "........###",
            "###.....###", "###.....###", "####...####", ".#########.", ".#########.", "...#####..." },
}
-- monta máscara de um número inteiro (dígitos separados por 1 px)
local function numberMask(str, font)
  local m, x = {}, 0
  local h = #font["0"]
  for i = 1, #str do
    local g = font[str:sub(i, i)]
    for y = 1, h do
      for gx = 1, #g[y] do
        if g[y]:sub(gx, gx) == "#" then m[(y - 1) * 1000 + x + gx - 1] = true end
      end
    end
    x = x + #g[1] + 1
  end
  return m, x - 1, h
end

------------------------------------------------------------------------
-- Animais (desenhados em coordenadas locais; centro do medalhão = 24,24)
------------------------------------------------------------------------
local function drawAnimal(id, P)
  local px = {}                      -- px[key] = cor
  local function key(x, y) return (y + 100) * 1000 + (x + 100) end
  local function set(x, y, c) px[key(x, y)] = c end

  -- forma genérica: pred(x,y) -> bool; contorno 1 px; sombra/brilho de borda
  local function shape(pred, box, col, o)
    o = o or {}
    local S = {}
    for y = box[2], box[4] do
      for x = box[1], box[3] do
        if pred(x, y) and (not o.clip or o.clip(x, y)) then S[key(x, y)] = true end
      end
    end
    local function inS(x, y) return S[key(x, y)] end
    if o.outline ~= false then
      for y = box[2] - 1, box[4] + 1 do
        for x = box[1] - 1, box[3] + 1 do
          if not inS(x, y) and (inS(x - 1, y) or inS(x + 1, y) or inS(x, y - 1) or inS(x, y + 1)) then
            set(x, y, o.outlineCol or C.out)
          end
        end
      end
    end
    for y = box[2], box[4] do
      for x = box[1], box[3] do
        if inS(x, y) then
          local c = o.colFn and o.colFn(x, y) or col
          if o.shade and (not inS(x, y + 1) or not inS(x, y + 2) or not inS(x + 1, y)) then
            c = o.shade
          elseif o.hi and (not inS(x, y - 1)) and inS(x, y + 2) then
            c = o.hi
          end
          set(x, y, c)
        end
      end
    end
    return inS
  end
  local function E(cx, cy, rx, ry)
    return function(x, y)
      local dx, dy = (x - cx) / (rx + 0.35), (y - cy) / (ry + 0.35)
      return dx * dx + dy * dy <= 1
    end, { math.floor(cx - rx - 1), math.floor(cy - ry - 1), math.ceil(cx + rx + 1), math.ceil(cy + ry + 1) }
  end
  local function ell(cx, cy, rx, ry, col, o)
    local p, b = E(cx, cy, rx, ry)
    return shape(p, b, col, o)
  end
  local function polyPred(pts)
    return function(x, y)
      local inside = false
      local px0, py0 = x + 0.5, y + 0.5
      local j = #pts
      for i = 1, #pts do
        local xi, yi = pts[i][1], pts[i][2]
        local xj, yj = pts[j][1], pts[j][2]
        if ((yi > py0) ~= (yj > py0)) and (px0 < (xj - xi) * (py0 - yi) / (yj - yi) + xi) then
          inside = not inside
        end
        j = i
      end
      return inside
    end
  end
  local function poly(pts, col, o)
    local x0, y0, x1, y1 = 999, 999, -999, -999
    for _, p in ipairs(pts) do
      x0 = math.min(x0, p[1]); y0 = math.min(y0, p[2]); x1 = math.max(x1, p[1]); y1 = math.max(y1, p[2])
    end
    return shape(polyPred(pts), { math.floor(x0) - 1, math.floor(y0) - 1, math.ceil(x1) + 1, math.ceil(y1) + 1 }, col, o)
  end
  local function union(...)
    local preds = { ... }
    return function(x, y)
      for _, p in ipairs(preds) do if p(x, y) then return true end end
      return false
    end
  end
  local function hline(x0, x1, y, c) for x = x0, x1 do set(x, y, c) end end
  local function eye(x, y)          -- olho 2x2 com brilho
    set(x, y, C.eye); set(x + 1, y, C.eye); set(x, y + 1, C.eye); set(x + 1, y + 1, C.eye)
    set(x, y, C.white)
  end
  local function shadow(cx, cy, rx)  -- sombra no chão na cor da nota
    for x = cx - rx, cx + rx do
      local t = (x - cx) / rx
      set(x, cy, P.light)
      if math.abs(t) < 0.75 then set(x, cy + 1, P.light) end
    end
  end
  local function water(y0, phase)    -- água até o fundo do medalhão
    for y = y0 - 1, 50 do
      for x = -2, 50 do
        local top = y0 + ((math.floor((x + phase) / 4) % 2 == 0) and 0 or 1)
        if y == top then set(x, y, C.waterH)
        elseif y > top then
          local c = C.water
          if (y - top) % 5 == 3 and (x + y) % 7 < 3 then c = C.waterH end
          if y > top + 8 then c = C.waterS end
          set(x, y, c)
        end
      end
    end
  end

  local A = {}

  -- R$ 1 – sabiá-laranjeira empoleirado
  A.sabia = function()
    poly({ { -2, 37 }, { 50, 35 }, { 50, 39 }, { -2, 41 } }, C.wood, { shade = C.woodS, hi = C.woodH })
    ell(41, 31, 4, 2, C.leaf, { shade = C.leafS, hi = C.leafH })
    ell(6, 34, 3, 2, C.leaf, { shade = C.leafS, hi = C.leafH })
    poly({ { 12, 26 }, { 3, 40 }, { 8, 43 }, { 18, 31 } }, C.sbBackS, { shade = C.wood })
    local body = ell(22, 27, 12, 11, C.sbBack, { shade = C.sbBackS, hi = C.sbBackH })
    ell(28, 31, 8, 7, C.sbBelly, { outline = false, clip = body, shade = C.sbBellyS, hi = C.sbBellyH })
    ell(29, 17, 8, 7, C.sbBack, { shade = C.sbBackS, hi = C.sbBackH })
    poly({ { 9, 22 }, { 22, 21 }, { 22, 27 }, { 14, 31 }, { 7, 30 } }, C.sbBackS, { shade = C.wood })
    hline(11, 19, 24, C.sbBack); hline(10, 16, 27, C.sbBack)
    poly({ { 36, 14.5 }, { 43, 17 }, { 36, 19.5 } }, C.sbBeak)
    for _, p in ipairs({ { 33, 21 }, { 34, 22 }, { 32, 22 }, { 33, 23 } }) do set(p[1], p[2], C.sbThroat) end
    set(34, 21, C.sbBackS); set(33, 22, C.sbBackS)
    for _, p in ipairs({ { 31, 14 }, { 32, 14 }, { 30, 15 }, { 33, 15 }, { 30, 16 }, { 33, 16 }, { 31, 17 }, { 32, 17 } }) do
      set(p[1], p[2], C.sbRing)
    end
    eye(31, 15)
    for _, x in ipairs({ 19, 24 }) do
      set(x, 37, C.sbBeak); set(x, 38, C.sbBeak)
      set(x - 1, 38, C.sbBeak); set(x + 1, 38, C.sbBeak)
    end
  end

  -- R$ 2 – tatu andando
  A.tatu = function()
    shadow(23, 39, 16)
    poly({ { 9, 27 }, { 1, 36 }, { 3, 37 }, { 11, 31 } }, C.ttShell, { shade = C.ttShellS })
    ell(13, 35, 3, 3, C.ttSkinS)
    ell(29, 35, 3, 3, C.ttSkinS)
    local shellP, shellB = E(22, 28, 14, 11)
    local shell = shape(function(x, y) return shellP(x, y) and y <= 33 end, shellB, C.ttShell,
      { shade = C.ttShellS, hi = C.ttShellH,
        colFn = function(x, y)
          if (x == 16 or x == 20 or x == 24 or x == 28) and y >= 19 and y <= 32 then return C.ttBand end
          if y >= 21 and (x + y * 3) % 4 == 0 and y % 2 == 0 then return C.ttShellS end
          return C.ttShell
        end })
    local headP = union(polyPred({ { 33, 23 }, { 46, 29 }, { 45, 32 }, { 33, 33 } }), (E(35, 28, 5, 5)))
    shape(headP, { 28, 21, 48, 35 }, C.ttSkin, { shade = C.ttSkinS })
    ell(34, 21, 2, 3, C.ttEar, { shade = C.ttSkinS })
    eye(38, 26)
    set(46, 30, C.eye); set(45, 30, C.eye)
  end

  -- R$ 5 – quati sentado com cauda listrada
  A.quati = function()
    shadow(24, 41, 13)
    -- cauda em anéis
    local tailPts = {}
    for i = 0, 10 do
      local t = i / 10
      tailPts[#tailPts + 1] = { 13 - 7 * math.sin(t * 1.4), 36 - 30 * t, 3.2 - 0.6 * t }
    end
    local tailPred = function(x, y)
      for _, c in ipairs(tailPts) do
        if (x - c[1]) ^ 2 + (y - c[2]) ^ 2 <= c[3] ^ 2 + 0.6 then return true end
      end
      return false
    end
    shape(tailPred, { 0, 0, 20, 42 }, C.qtFur, {
      colFn = function(x, y) return (math.floor((y + 1) / 4) % 2 == 0) and C.qtDark or C.qtLight end })
    local body = ell(23, 31, 10, 10, C.qtFur, { shade = C.qtFurS, hi = C.qtFurH })
    ell(26, 33, 5, 6, C.qtLight, { outline = false, clip = body })
    ell(23, 11, 2.5, 2.5, C.qtFur, { shade = C.qtFurS })
    ell(31, 10, 2.5, 2.5, C.qtFur, { shade = C.qtFurS })
    set(23, 11, C.qtMark); set(31, 10, C.qtMark)
    local headP = union((E(28, 18, 8, 7)), polyPred({ { 32, 15 }, { 45, 20 }, { 45, 24 }, { 32, 24 } }))
    shape(headP, { 18, 9, 47, 27 }, C.qtFur, { shade = C.qtFurS, hi = C.qtFurH })
    for x = 37, 44 do set(x, 20, C.qtDark) end
    hline(42, 45, 21, C.qtDark); hline(43, 45, 22, C.qtDark)
    set(45, 21, C.eye); set(45, 22, C.eye)
    hline(29, 32, 14, C.qtMark); hline(30, 33, 21, C.qtMark); hline(31, 34, 22, C.qtMark)
    eye(30, 16)
    ell(19, 40, 3, 2, C.qtDark)
    ell(28, 40, 3, 2, C.qtDark)
  end

  -- R$ 10 – bicho-preguiça pendurado
  A.preguica = function()
    poly({ { -2, 7 }, { 50, 9 }, { 50, 13 }, { -2, 11 } }, C.wood, { shade = C.woodS, hi = C.woodH })
    ell(40, 15, 4, 2, C.leaf, { shade = C.leafS, hi = C.leafH })
    ell(7, 14, 3, 2, C.leaf, { shade = C.leafS, hi = C.leafH })
    ell(18, 41, 3, 3, C.pgFur, { shade = C.pgFurS })
    ell(30, 41, 3, 3, C.pgFur, { shade = C.pgFurS })
    ell(24, 32, 11, 10, C.pgFur, { shade = C.pgFurS, hi = C.pgFurH })
    poly({ { 12, 10 }, { 16, 10 }, { 19, 26 }, { 14, 27 } }, C.pgFur, { shade = C.pgFurS })
    poly({ { 32, 10 }, { 36, 10 }, { 34, 27 }, { 29, 26 } }, C.pgFur, { shade = C.pgFurS })
    for _, x in ipairs({ 12, 14, 16, 32, 34, 36 }) do set(x, 8, C.pgClaw); set(x, 9, C.pgClaw) end
    local head = ell(24, 23, 9, 8, C.pgFur, { shade = C.pgFurS, hi = C.pgFurH })
    ell(24, 25, 7, 5, C.pgFace, { outline = false, clip = head })
    -- máscaras escuras inclinadas
    for _, m in ipairs({ { 19, 24, -1 }, { 29, 24, 1 } }) do
      local x, y, s = m[1], m[2], m[3]
      hline(x - 2, x + 1, y, C.pgMask); hline(x - 2, x + 2, y + 1, C.pgMask)
      set(x + 2 * s, y - 1, C.pgMask); set(x - 2 * s, y + 2, C.pgMask)
    end
    eye(18, 24); eye(29, 24)
    set(23, 27, C.eye); set(24, 27, C.eye); set(25, 27, C.eye); set(24, 28, C.eye)
    set(21, 29, C.pgMask); hline(22, 26, 30, C.pgMask); set(27, 29, C.pgMask)
  end

  -- R$ 20 – tamanduá-bandeira
  A.tamandua = function()
    shadow(25, 41, 18)
    poly({ { 15, 22 }, { 4, 13 }, { 0, 17 }, { 0, 27 }, { 5, 35 }, { 14, 36 }, { 17, 31 } }, C.tmTail,
      { shade = C.tmTailS, colFn = function(x, y) return ((x - y) % 4 == 0) and C.tmTailS or C.tmTail end })
    ell(15, 37, 2, 3, C.tmTail, { shade = C.tmTailS })
    local body = ell(23, 29, 12, 9, C.tmFur, { shade = C.tmFurS, hi = C.tmFurH })
    -- faixa diagonal preta com bordas brancas
    for y = 18, 40 do
      for x = 10, 36 do
        if body(x, y) then
          local d = math.abs((x - 31) + (y - 20) * 0.7) / 1.22
          if d < 1.6 then set(x, y, C.tmStripe) elseif d < 2.6 then set(x, y, C.tmWhite) end
        end
      end
    end
    poly({ { 28, 33 }, { 33, 33 }, { 33, 41 }, { 28, 41 } }, C.tmLeg, {
      colFn = function(x, y) return (y == 37 or y == 38) and C.tmStripe or C.tmLeg end })
    local headP = union(polyPred({ { 32, 19 }, { 47, 27 }, { 47, 29 }, { 32, 29 } }), (E(33, 24, 4, 5)))
    shape(headP, { 27, 17, 49, 31 }, C.tmFur, { shade = C.tmFurS, hi = C.tmFurH })
    ell(31, 19, 1.5, 1.5, C.tmFurS)
    eye(35, 23)
    set(47, 28, C.eye)
  end

  -- R$ 50 – capivara
  A.capivara = function()
    shadow(23, 41, 17)
    ell(11, 36, 3, 4, C.cpFurS, { shade = C.cpDark })
    ell(27, 36, 3, 4, C.cpFurS, { shade = C.cpDark })
    ell(20, 29, 14, 10, C.cpFur, { shade = C.cpFurS, hi = C.cpFurH,
      colFn = function(x, y) return (hash(x, y, 5) % 9 == 0) and C.cpFurS or C.cpFur end })
    ell(15, 38, 3, 3, C.cpFur, { shade = C.cpFurS })
    ell(31, 38, 3, 3, C.cpFur, { shade = C.cpFurS })
    local headP = union((E(32, 21, 8, 7)), polyPred({ { 34, 15 }, { 43, 17 }, { 45, 21 }, { 45, 27 }, { 34, 28 } }))
    shape(headP, { 22, 12, 47, 30 }, C.cpFur, { shade = C.cpFurS, hi = C.cpFurH })
    ell(27, 14, 2, 2, C.cpDark)
    eye(34, 18)
    hline(43, 44, 21, C.eye); set(44, 22, C.eye)
    hline(41, 44, 25, C.cpDark)
  end

  -- R$ 100 – boto-cor-de-rosa saltando
  A.boto = function()
    water(36, 0)
    local arc = {}
    for i = 0, 14 do
      local t = i / 14
      local a = math.pi * (0.95 - 0.75 * t)
      arc[#arc + 1] = { 22 + 16 * math.cos(a), 34 - 20 * math.sin(a), 3 + 4.5 * math.sin(t * math.pi * 0.9) }
    end
    local bodyPred = function(x, y)
      for _, c in ipairs(arc) do
        if (x - c[1]) ^ 2 + (y - c[2]) ^ 2 <= c[3] ^ 2 + 0.5 then return true end
      end
      return false
    end
    poly({ { 7, 33 }, { 0, 36 }, { 4, 38 }, { 9, 35 } }, C.btPinkS)
    shape(union(bodyPred, (E(34, 18, 6, 6)), polyPred({ { 37, 17 }, { 47, 22 }, { 46, 24 }, { 36, 22 } })),
      { 2, 8, 49, 40 }, C.btPink, { shade = C.btPinkS, hi = C.btPinkH, clip = function(x, y) return y < 37 end })
    poly({ { 18, 12 }, { 22, 9 }, { 24, 13 } }, C.btPinkS)
    ell(27, 24, 3, 2, C.btPinkS)
    eye(35, 17)
    hline(38, 44, 22, C.btPinkS)
    for _, p in ipairs({ { 8, 31 }, { 5, 33 }, { 11, 33 }, { 40, 34 }, { 43, 32 }, { 37, 35 } }) do
      set(p[1], p[2], C.foam)
    end
    hline(2, 12, 36, C.foam); hline(32, 42, 36, C.foam)
  end

  -- R$ 200 – jacaré na água
  A.jacare = function()
    local body = ell(17, 33, 15, 7, C.jcGreen, { shade = C.jcGreenS, hi = C.jcGreenH })
    for x = 5, 23, 4 do ell(x, 26, 1.5, 1.5, C.jcGreenS) end
    local headP = union((E(27, 26, 7, 6)), polyPred({ { 28, 21 }, { 46, 25 }, { 47, 30 }, { 28, 31 } }))
    shape(headP, { 19, 18, 49, 33 }, C.jcGreen, { shade = C.jcGreenS, hi = C.jcGreenH })
    hline(30, 46, 31, C.jcBelly)
    hline(30, 46, 30, C.out)
    for _, x in ipairs({ 32, 35, 38, 41, 44 }) do set(x, 29, C.jcTooth); set(x, 31, C.jcTooth) end
    ell(29, 20, 3, 3, C.jcGreen, { shade = C.jcGreenS, hi = C.jcGreenH })
    set(28, 19, C.jcEye); set(29, 19, C.jcEye); set(28, 20, C.jcEye); set(30, 20, C.jcEye)
    set(29, 20, C.eye); set(29, 21, C.eye)
    ell(44, 24, 1.5, 1.5, C.jcGreen, { shade = C.jcGreenS })
    set(44, 24, C.eye)
    water(35, 2)
    for _, p in ipairs({ { 20, 35 }, { 24, 36 }, { 47, 34 } }) do set(p[1], p[2], C.foam) end
  end

  A[id]()
  return px, key
end

------------------------------------------------------------------------
-- Desenho de uma nota (deitada 180x120)
------------------------------------------------------------------------
local function drawNote(color, note)
  local P = makePalette()
  local buf, isPaper, isFrame = {}, {}, {}

  local function put(x, y, c, paper)
    if x < 0 or y < 0 or x >= LW or y >= LH then return end
    local i = y * LW + x
    buf[i] = c
    isPaper[i] = paper or false
    isFrame[i] = false
  end
  local function rect(x0, y0, x1, y1, c, paper)
    for y = y0, y1 do for x = x0, x1 do put(x, y, c, paper) end end
  end
  local function inRound(x, y, x0, y0, x1, y1, r)
    if x < x0 or x > x1 or y < y0 or y > y1 then return false end
    local cx = (x < x0 + r) and (x0 + r) or ((x > x1 - r) and (x1 - r) or x)
    local cy = (y < y0 + r) and (y0 + r) or ((y > y1 - r) and (y1 - r) or y)
    local dx, dy = x - cx, y - cy
    return dx * dx + dy * dy <= r * r + r * 0.8
  end
  local function roundShape(x0, y0, x1, y1, r, fill, outline, paper, frame)
    for y = y0, y1 do
      for x = x0, x1 do
        if inRound(x, y, x0, y0, x1, y1, r) then
          local edge = not inRound(x - 1, y, x0, y0, x1, y1, r) or not inRound(x + 1, y, x0, y0, x1, y1, r)
                    or not inRound(x, y - 1, x0, y0, x1, y1, r) or not inRound(x, y + 1, x0, y0, x1, y1, r)
          if edge then put(x, y, outline)
          else
            put(x, y, fill, paper)
            if frame then isFrame[y * LW + x] = true end
          end
        end
      end
    end
  end
  local function disc(cx, cy, rings)
    local R = rings[1][1]
    for y = cy - R - 1, cy + R + 1 do
      for x = cx - R - 1, cx + R + 1 do
        local d = math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2)
        local c = nil
        for _, rg in ipairs(rings) do
          if d <= rg[1] + 0.5 then c = rg[2] end
        end
        if c then put(x, y, c) end
      end
    end
  end
  -- máscara (chave y*1000+x) com contorno, brilho à esquerda, sombra à direita
  local function stamp(mask, mw, mh, ox, oy, fill, hi, shade, outline)
    local function m(x, y) return x >= 0 and y >= 0 and mask[y * 1000 + x] end
    for y = -1, mh do
      for x = -1, mw do
        if m(x, y) then
          local c = fill
          if hi and not m(x - 1, y) then c = hi end
          if shade and not m(x + 1, y) then c = shade end
          put(ox + x, oy + y, c)
        elseif m(x - 1, y) or m(x + 1, y) or m(x, y - 1) or m(x, y + 1) then
          put(ox + x, oy + y, outline)
        end
      end
    end
  end
  local function text(s, x, y, c)
    for i = 1, #s do
      local g, extra = glyph(s:sub(i, i))
      for gy = 1, 5 do
        for gx = 1, #g[1] do
          if g[gy]:sub(gx, gx) == "#" then put(x + gx - 1, y + gy - 1, c) end
        end
      end
      if extra then for _, e in ipairs(extra) do put(x + e[1], y + e[2], c) end end
      x = x + #g[1] + 1
    end
  end
  local function textCentered(s, cx, y, c) text(s, cx - math.floor(textWidth(s) / 2), y, c) end
  local function line(x0, y0, x1, y1, c)
    local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
    local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
    local err = dx + dy
    while true do
      put(x0, y0, c)
      if x0 == x1 and y0 == y1 then break end
      local e2 = 2 * err
      if e2 >= dy then err = err + dy; x0 = x0 + sx end
      if e2 <= dx then err = err + dx; y0 = y0 + sy end
    end
  end
  local function polyline(pts, ox, oy, c)
    for i = 1, #pts - 1 do
      line(ox + pts[i][1], oy + pts[i][2], ox + pts[i + 1][1], oy + pts[i + 1][2], c)
    end
  end

  local valueStr = tostring(note.value)

  -- 1) Papel + margem externa
  rect(0, 0, LW - 1, LH - 1, P.paper, true)
  for x = 3, LW - 4 do put(x, 3, P.mid); put(x, LH - 4, P.mid) end
  for y = 3, LH - 4 do put(3, y, P.mid); put(LW - 4, y, P.mid) end

  -- 2) Moldura e painel interno
  roundShape(6, 6, LW - 7, LH - 7, 3, P.mid, P.dark, false, true)
  roundShape(13, 23, LW - 14, LH - 24, 6, P.paper, P.dark, true)
  for y = 26, LH - 27 do put(9, y, P.light); put(LW - 10, y, P.light) end

  -- 3) Valor nos quatro cantos
  local sm, sw, sh = numberMask(valueStr, DIGITS_SMALL)
  local leftX, rightX = 18, LW - 18 - sw
  for _, y in ipairs({ 8, LH - 21 }) do
    stamp(sm, sw, sh, leftX, y, P.light, P.lighter, nil, P.dark)
    stamp(sm, sw, sh, rightX, y, P.light, P.lighter, nil, P.dark)
  end

  -- 4) Ovais decorativos entre os números (faixa de cima e de baixo)
  local OVAL = { ".######.", "########", "########", "########", "########", ".######." }
  local function oval(x, y)
    for oy = 0, 5 do
      for ox = 0, 7 do
        if OVAL[oy + 1]:sub(ox + 1, ox + 1) == "#" then
          if oy == 0 or oy == 5 or ox == 0 or ox == 7 or ((oy == 1 or oy == 4) and (ox == 1 or ox == 6)) then
            put(x + ox, y + oy, P.dark)
          else
            put(x + ox, y + oy, (oy == 1 or ox == 1) and P.lighter or P.light)
          end
        end
      end
    end
  end
  local function ovalRow(x0, x1, y)          -- centraliza ovais em [x0, x1]
    local n = math.floor((x1 - x0 + 2) / 10)
    if n <= 0 then return end
    local start = x0 + math.floor(((x1 - x0 + 1) - (n * 10 - 2)) / 2)
    for i = 0, n - 1 do oval(start + i * 10, y) end
  end
  local numL, numR = leftX + sw + 4, rightX - 5
  ovalRow(numL, numR, 12)
  -- faixa de baixo: placa com o valor por extenso + ovais dos lados
  local tw = textWidth(note.word)
  local plX0, plX1 = 90 - math.floor(tw / 2) - 4, 90 - math.floor(tw / 2) + tw + 3
  local plY0, plY1 = LH - 20, LH - 11
  roundShape(plX0, plY0, plX1, plY1, 1, P.paper, P.dark, true)
  text(note.word, 90 - math.floor(tw / 2), plY0 + 2, P.dark)
  ovalRow(numL, plX0 - 3, LH - 18)
  ovalRow(plX1 + 3, numR, LH - 18)

  -- 5) Medalhão com o animal
  local mx, my = 90, 58
  disc(mx, my, { { 29, P.dark }, { 28, P.mid }, { 25, P.dark }, { 24, P.lighter } })
  for y = my - 24, my + 24 do
    for x = mx - 24, mx + 24 do
      local d = math.sqrt((x - mx) ^ 2 + (y - my) ^ 2)
      if d > 22.5 and d <= 23.5 and x - mx + y - my < -10 then put(x, y, P.paperHi) end
    end
  end
  local apx = drawAnimal(note.animal, P)
  for k, c in pairs(apx) do
    local ly = k // 1000 - 100
    local lx = k % 1000 - 100
    local x, y = mx - 24 + lx, my - 24 + ly
    if (x - mx) ^ 2 + (y - my) ^ 2 <= 24.5 ^ 2 then put(x, y, c) end
  end

  -- 6) Fita com o nome do animal
  local nw = textWidth(note.name)
  local bx0, bx1 = 90 - math.floor(nw / 2) - 5, 90 - math.floor(nw / 2) + nw + 4
  local function tail(x0, dir)
    for i = 0, 7 do
      local x = x0 + dir * i
      local e = 7 - i
      for y = 85, 93 do
        local k = 3 - math.abs(y - 89)
        if k > 0 and e < k then
          put(x, y, P.paper, true)
        elseif y == 85 or y == 93 or i == 0 or e == math.max(k, 0) then
          put(x, y, P.dark)
        else
          put(x, y, P.mid)
        end
      end
    end
  end
  tail(bx0 - 1, -1)
  tail(bx1 + 1, 1)
  for x = bx0, bx1 do
    put(x, 81, P.dark); put(x, 91, P.dark)
    for y = 82, 90 do put(x, y, P.paper, true) end
  end
  for y = 81, 91 do put(bx0, y, P.dark); put(bx1, y, P.dark) end
  for x = bx0 + 1, bx1 - 1 do put(x, 90, P.paperLo) end
  text(note.name, 90 - math.floor(nw / 2), 84, P.dark)

  -- 7) Lado do título: nome fictício (TITLE_1/TITLE_2), valor grande, série, assinatura
  local serial = string.format("%s %06d", color.letter, note.value)
  local rx = 143
  textCentered(TITLE_1, rx, 29, P.dark)
  textCentered(TITLE_2, rx, 36, P.dark)
  disc(rx, 59, { { 14, P.dark }, { 13, P.mid }, { 11, P.light } })
  local bm, bw, bh = numberMask(valueStr, DIGITS_BIG)
  stamp(bm, bw, bh, rx - math.floor(bw / 2), 50, P.lighter, P.paperHi, P.light, P.dark)
  textCentered(serial, rx, 77, P.mid)
  polyline({ { 0, 5 }, { 2, 1 }, { 4, 5 }, { 6, 2 }, { 8, 5 }, { 10, 3 }, { 13, 4 }, { 16, 1 }, { 18, 5 }, { 22, 3 } },
           rx - 11, 83, P.dark)
  for x = rx - 13, rx + 13 do put(x, 90, P.mid) end

  -- 8) Lado do selo: série, selo com prédio, assinatura
  local lx = 37
  textCentered(serial, lx, 29, P.mid)
  disc(lx, 57, { { 15, P.dark }, { 14, P.lighter }, { 12, P.dark }, { 11, P.mid }, { 10, P.lighter } })
  local function bxl(x0, x1, y, c) for x = x0, x1 do put(lx + x, 57 + y, c) end end
  bxl(-1, 1, -7, P.dark); bxl(-3, 3, -6, P.dark); bxl(-5, 5, -5, P.dark)
  bxl(-1, 1, -6, P.light); bxl(-6, 6, -4, P.dark)
  for _, cx in ipairs({ -5, -2, 2, 5 }) do
    for y = -3, 3 do put(lx + cx, 57 + y, P.dark) end
  end
  bxl(-6, 6, 4, P.dark); bxl(-7, 7, 5, P.dark)
  polyline({ { 0, 4 }, { 3, 0 }, { 4, 5 }, { 7, 1 }, { 9, 4 }, { 12, 2 }, { 15, 5 }, { 19, 1 }, { 22, 3 } },
           lx - 11, 80, P.dark)
  for x = lx - 13, lx + 13 do put(x, 87, P.mid) end

  -- 9) Textura do papel e da moldura
  for y = 0, LH - 1 do
    for x = 0, LW - 1 do
      local i = y * LW + x
      local r = hash(x, y, 11) % 100
      if isPaper[i] then
        if r < 4 then buf[i] = P.paperLo elseif r < 7 then buf[i] = P.paperHi end
      elseif isFrame[i] then
        if r < 4 then buf[i] = P.midLo end
      end
    end
  end
  for f = 0, 24 do
    local fx = 2 + hash(f, 1, 23 + note.value) % (LW - 4)
    local fy = 2 + hash(f, 2, 23 + note.value) % (LH - 4)
    local dir = hash(f, 3, 23) % 4
    local ddx = ({ 1, 0, 1, 1 })[dir + 1]
    local ddy = ({ 0, 1, 1, -1 })[dir + 1]
    local col = (hash(f, 5, 23) % 2 == 0) and P.light or P.paperLo
    for s = 0, 2 do
      local px, py = fx + ddx * s, fy + ddy * s
      local i = py * LW + px
      if px >= 0 and px < LW and py >= 0 and py < LH and isPaper[i] then buf[i] = col end
    end
  end

  -- 10) Contorno externo com cantos recortados
  for x = 0, LW - 1 do put(x, 0, P.dark); put(x, LH - 1, P.dark) end
  for y = 0, LH - 1 do put(0, y, P.dark); put(LW - 1, y, P.dark) end
  for _, c in ipairs({ { 0, 0, 1, 1 }, { LW - 1, 0, -1, 1 }, { 0, LH - 1, 1, -1 }, { LW - 1, LH - 1, -1, -1 } }) do
    local x, y, sx, sy = c[1], c[2], c[3], c[4]
    buf[y * LW + x] = nil
    put(x + sx, y + sy, P.dark)
  end

  return buf
end


------------------------------------------------------------------------
-- Infra: pastas, sprite transparente, salvar
------------------------------------------------------------------------
local GENERATED = {}
local function ensureDir(path)
  local dir = app.fs.filePath(path)
  if not app.fs.isDirectory(dir) then app.fs.makeAllDirectories(dir) end
end
local function newSprite(w, h)
  local spr = Sprite(w, h, ColorMode.RGB)
  if spr.layers[1].isBackground then app.command.LayerFromBackground() end
  return spr
end
local function saveSprite(spr, rel)
  local base = app.fs.joinPath(app.fs.currentPath, rel)
  ensureDir(base)
  spr:saveAs(base .. ".aseprite")
  spr:saveCopyAs(base .. ".png")
  GENERATED[#GENERATED + 1] = rel .. ".png"
  GENERATED[#GENERATED + 1] = rel .. ".aseprite"
  spr:close()
end
local function rgba(c) return app.pixelColor.rgba(c[1], c[2], c[3], 255) end

------------------------------------------------------------------------
-- PARTE 1: cédulas neutras
------------------------------------------------------------------------
local NEUTRAL = { letter = "A" }
for _, note in ipairs(NOTES) do
  local spr = newSprite(NW, NH)
  local layer = spr.layers[1]
  layer.name = "CEDULA"
  local img = Image(NW, NH, ColorMode.RGB)
  local buf = drawNote(NEUTRAL, note)
  for ly = 0, LH - 1 do
    for lx = 0, LW - 1 do
      local c = buf[ly * LW + lx]
      if c then img:drawPixel(ly, LW - 1 - lx, rgba(c)) end   -- deitado -> em pé
    end
  end
  spr:newCel(layer, 1, img, Point(0, 0))
  saveSprite(spr, "art/notas/neutras/nota_" .. note.value)
end

------------------------------------------------------------------------
-- PARTE 2: selos 40x40
------------------------------------------------------------------------
local SW = 40
local INK = hexToRGB("1E1E1E")
local CREAM_ICON = hexToRGB("FFF8E7")
local CREAM_SH = hexToRGB("E2D7BE")

-- disco: raio 18 (36 px), contorno 2 px, borda levemente irregular por setor
local function drawDisc(img, discHex, seed)
  local D = hexToRGB(discHex)
  local DHI = mix(D, hexToRGB("FFFFFF"), 0.22)
  local DSH = mix(D, INK, 0.22)
  local cx, cy = SW / 2, SW / 2
  for y = 0, SW - 1 do
    for x = 0, SW - 1 do
      local dx, dy = x + 0.5 - cx, y + 0.5 - cy
      local d = math.sqrt(dx * dx + dy * dy)
      local sector = math.floor((math.atan(dy, dx) + math.pi) / (2 * math.pi) * 28) % 28
      local R = 18 - ((hash(sector, 0, seed) % 3 == 0) and 0.7 or 0)
      if d <= R then
        local c = D
        if d > R - 2 then c = INK                                -- contorno 2 px
        elseif d > R - 3.5 and dx + dy < -9 then c = DHI           -- luz no alto à esquerda
        elseif d > R - 3.5 and dx + dy > 9 then c = DSH end        -- sombra embaixo à direita
        img:drawPixel(x, y, rgba(c))
      end
    end
  end
end

-- ícone: máscara (função) preenchida em creme com contorno de 1 px
local function drawIcon(img, inside, detail)
  local mask = {}
  for y = 0, SW - 1 do for x = 0, SW - 1 do mask[y * SW + x] = inside(x, y) end end
  local function m(x, y) return x >= 0 and y >= 0 and x < SW and y < SW and mask[y * SW + x] end
  for y = 0, SW - 1 do
    for x = 0, SW - 1 do
      if m(x, y) then
        img:drawPixel(x, y, rgba(CREAM_ICON))
      elseif m(x - 1, y) or m(x + 1, y) or m(x, y - 1) or m(x, y + 1) then
        img:drawPixel(x, y, rgba(INK))
      end
    end
  end
  if detail then detail(function(x, y, c) img:drawPixel(x, y, rgba(c)) end) end
end

local function pointInPoly(pts, x, y)
  local inside, j = false, #pts
  local px, py = x + 0.5, y + 0.5
  for i = 1, #pts do
    local xi, yi, xj, yj = pts[i][1], pts[i][2], pts[j][1], pts[j][2]
    if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then inside = not inside end
    j = i
  end
  return inside
end
local function cardShape(x, y)                 -- cartão 20x14 em (10,13), cantos chanfrados
  if x < 10 or x > 29 or y < 13 or y > 26 then return false end
  if (x == 10 or x == 29) and (y == 13 or y == 26) then return false end
  return true
end

local DOLLAR = { "..#..", ".####", "#.#..", "#.#..", ".###.", "..#.#", "..#.#", "####.", "..#.." }

local SEALS = {
  { file = "selo_dinheiro", disc = "3F8F4E", seed = 351,
    inside = function(x, y) return (x + 0.5 - 20) ^ 2 + (y + 0.5 - 20) ^ 2 <= 9 * 9 end,
    detail = function(p)
      for y = 0, SW - 1 do for x = 0, SW - 1 do                -- aro interno da moeda
        local d = math.sqrt((x + 0.5 - 20) ^ 2 + (y + 0.5 - 20) ^ 2)
        if d <= 7.5 and d > 6.5 then p(x, y, CREAM_SH) end
      end end
      for r = 1, #DOLLAR do                                      -- cifrão 5x9
        for c = 1, 5 do
          if DOLLAR[r]:sub(c, c) == "#" then p(17 + c - 1, 15 + r - 1, INK) end
        end
      end
    end },
  { file = "selo_relampago", disc = "E8B923", seed = 352,
    inside = function(x, y)
      return pointInPoly({ { 25, 10 }, { 13, 22 }, { 19, 22 }, { 15, 30 }, { 28, 17 }, { 22, 17 }, { 28, 10 } }, x, y)
    end,
    detail = function(p) p(24, 12, CREAM_SH); p(23, 13, CREAM_SH) end },
  { file = "selo_debito", disc = "2F6FB0", seed = 353,
    inside = cardShape,
    detail = function(p)
      for x = 10, 29 do for y = 15, 17 do p(x, y, INK) end end  -- faixa no topo
      for x = 13, 17 do for y = 20, 23 do                        -- chip pequeno 5x4
        local edge = x == 13 or x == 17 or y == 20 or y == 23
        p(x, y, edge and INK or hexToRGB("C9B87A"))
      end end
    end },
  { file = "selo_credito", disc = "7A4FA3", seed = 354,
    inside = cardShape,
    detail = function(p)
      for x = 12, 27 do p(x, 18, INK); p(x, 22, INK) end         -- duas listras horizontais
    end },
}

for _, s in ipairs(SEALS) do
  local spr = newSprite(SW, SW)
  local lDisc = spr.layers[1]
  lDisc.name = "DISCO"
  local lIcon = spr:newLayer()
  lIcon.name = "ICONE"
  local imgDisc = Image(SW, SW, ColorMode.RGB)
  local imgIcon = Image(SW, SW, ColorMode.RGB)
  drawDisc(imgDisc, s.disc, s.seed)
  drawIcon(imgIcon, s.inside, s.detail)
  spr:newCel(lDisc, 1, imgDisc, Point(0, 0))
  spr:newCel(lIcon, 1, imgIcon, Point(0, 0))
  saveSprite(spr, "art/notas/selos/" .. s.file)
end

for _, f in ipairs(GENERATED) do print("gerado: " .. f) end
