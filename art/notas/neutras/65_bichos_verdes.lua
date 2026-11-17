-- 65_bichos_verdes.lua
-- Deixa os bichos das cédulas monocromáticos em verde (tons vizinhos aos da cédula).
-- Mexe SOMENTE na camada "BICHO". Fundo, medalhão e textos ficam intactos.
-- Uso: abra no Aseprite as notas (pode abrir as 10 de uma vez) e rode este script.
-- Ele processa todos os sprites abertos que tenham a camada BICHO e salva cada um.

local pc = app.pixelColor

-- rampa do escuro (contorno) ao claro
local RAMP = {
  {0x0e,0x26,0x17}, {0x18,0x3c,0x25}, {0x25,0x55,0x33},
  {0x35,0x6d,0x43}, {0x4a,0x85,0x56}, {0x67,0x9e,0x6d},
  {0x8a,0xb7,0x8a}, {0xb0,0xcf,0xa9}, {0xd4,0xe6,0xcb},
}
local N = #RAMP

local function lum(v)
  return (299*pc.rgbaR(v) + 587*pc.rgbaG(v) + 114*pc.rgbaB(v)) // 1000
end

local function recolorImage(img)
  -- 1ª passada: menor e maior luminosidade do bicho
  local lo, hi = 255, 0
  for it in img:pixels() do
    local v = it()
    if pc.rgbaA(v) > 0 then
      local L = lum(v)
      if L < lo then lo = L end
      if L > hi then hi = L end
    end
  end
  local span = math.max(1, hi - lo)
  -- 2ª passada: troca cada pixel pelo verde equivalente, mantendo o alfa
  for it in img:pixels() do
    local v = it()
    local a = pc.rgbaA(v)
    if a > 0 then
      local k = ((lum(v) - lo) * (N - 1) * 2 + span) // (2 * span)
      local c = RAMP[k + 1]
      it(pc.rgba(c[1], c[2], c[3], a))
    end
  end
end

local feitos = 0
for _, spr in ipairs(app.sprites) do
  if spr.colorMode == ColorMode.RGB then
    for _, layer in ipairs(spr.layers) do
      if layer.name == "BICHO" then
        app.transaction("Bicho verde", function()
          for _, cel in ipairs(layer.cels) do
            local img = cel.image:clone()
            recolorImage(img)
            cel.image = img
          end
        end)
        if spr.filename ~= "" then
          spr:saveAs(spr.filename)
          local png = spr.filename:gsub("%.aseprite$", ".png")
          spr:saveCopyAs(png)
        end
        feitos = feitos + 1
      end
    end
  end
end

app.alert("Bichos recoloridos em verde: " .. feitos .. " nota(s).")
