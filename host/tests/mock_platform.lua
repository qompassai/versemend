-- A platform with no window: fixed text metrics, an in-memory save
-- slot, recorded sound cues, counted draw calls. The C host's
-- --selftest mode implements the same interface with the same
-- metrics, so a scripted playthrough produces a byte-identical
-- transcript on both — the engine-independence proof.
local METRICS = {
    title = { char_w = 30, line_h = 64 },
    display = { char_w = 16, line_h = 38 },
    body = { char_w = 10, line_h = 26 },
    body_bold = { char_w = 10, line_h = 26 },
    code = { char_w = 11, line_h = 24 },
    code_small = { char_w = 9, line_h = 20 },
    small = { char_w = 8, line_h = 20 },
}

local function new()
    local p = { save_data = nil, sounds = {}, draws = 0, text_input = false }
    function p.draw_rect(x, y, w, h, color, alpha) p.draws = p.draws + 1 end
    function p.draw_image(name, x, y, w, h, alpha) p.draws = p.draws + 1 end
    function p.draw_text(x, y, text, kind, color) p.draws = p.draws + 1 end
    function p.measure(text, kind)
        local m = METRICS[kind] or METRICS.body
        return #text * m.char_w, m.line_h
    end
    function p.sound(name) p.sounds[#p.sounds + 1] = name end
    function p.read_save() return p.save_data end
    function p.write_save(s) p.save_data = s end
    function p.set_text_input(on) p.text_input = on end
    return p
end

return { new = new, METRICS = METRICS }
