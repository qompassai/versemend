-- Presentation effects as data, with the evaluator the game itself
-- uses — so the photosafety gate measures the shipped curves, not a
-- description of them. The law (design §8.3): no sequence may flash
-- at more than three flashes per second, and no transition may use
-- luminance inversion. A "flash" here is counted strictly: a swing
-- of at least FLASH_SWING of full-field luminance, up and back.
local FLASH_SWING = 0.08
local FLASH_PER_SECOND_MAX = 3

local function smoothstep(x)
    if x <= 0 then return 0 end
    if x >= 1 then return 1 end
    return x * x * (3 - 2 * x)
end

-- Each effect: brightness(t_ms) -> delta in [-1, 1] of full-field
-- luminance overlay (positive brightens in lamp-amber, negative
-- dims toward ink). duration_ms is nil for ambient loops.
local Effects = {}

Effects.seal_glow = {
    duration_ms = 2000,
    brightness = function(t)
        if t < 800 then return 0.16 * smoothstep(t / 800) end
        if t < 1200 then return 0.16 end
        if t < 2000 then return 0.16 * (1 - smoothstep((t - 1200) / 800)) end
        return 0
    end,
}

Effects.backlash_dim = {
    duration_ms = 2600,
    brightness = function(t)
        if t < 1100 then return -0.35 * smoothstep(t / 1100) end
        if t < 1500 then return -0.35 end
        if t < 2600 then return -0.35 * (1 - smoothstep((t - 1500) / 1100)) end
        return 0
    end,
}

Effects.page_fade = {
    duration_ms = 250,
    brightness = function(t)
        if t < 125 then return -0.08 * smoothstep(t / 125) end
        if t < 250 then return -0.08 * (1 - smoothstep((t - 125) / 125)) end
        return 0
    end,
}

Effects.lamp_breathe = {
    duration_ms = nil, -- ambient loop
    brightness = function(t)
        return 0.03 * math.sin(t * 2 * math.pi / 2000)
    end,
}

-- Count flashes in an effect over a window: sample the curve, walk
-- its peaks and troughs, and count a flash each time the swing
-- between successive extrema reaches FLASH_SWING.
local function flashes_per_second(effect, window_ms, sample_hz)
    local step = math.floor(1000 / sample_hz)
    local extrema = {}
    local prev = effect.brightness(0)
    local direction = 0
    for t = step, window_ms, step do
        local v = effect.brightness(t)
        local d = v - prev
        if d ~= 0 then
            local dir = d > 0 and 1 or -1
            if direction ~= 0 and dir ~= direction then
                extrema[#extrema + 1] = prev
            end
            direction = dir
        end
        prev = v
    end
    extrema[#extrema + 1] = prev
    local flashes = 0
    for i = 2, #extrema do
        if math.abs(extrema[i] - extrema[i - 1]) >= FLASH_SWING then
            flashes = flashes + 0.5
        end
    end
    return flashes / (window_ms / 1000)
end

local M = {
    effects = Effects,
    flashes_per_second = flashes_per_second,
    FLASH_PER_SECOND_MAX = FLASH_PER_SECOND_MAX,
    smoothstep = smoothstep,
}
return M
