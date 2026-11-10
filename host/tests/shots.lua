-- Screenshot driver for the host's --screenshot mode: walks the
-- same path as the selftest playthrough and calls the host's
-- HOST_SHOT(name) global at named visual beats, after a render.
-- The Owner's eye is the gate; these frames are the evidence.
local Shots = {}

function Shots.run(factory)
    local App = require("app")
    local F = require("fixtures")
    local platform = factory.new()
    local app = App.new(platform)

    local function beat(name)
        app:render()
        HOST_SHOT(name) -- luacheck: ignore (host-provided global)
    end
    local function click(x, y)
        app:event({ type = "click", x = x, y = y })
        app:render()
        app:update(16)
    end
    local function set_buffer(idx, source)
        local buf = app.editor.buffers[idx]
        buf.lines = {}
        for line in (source .. "\n"):gmatch("(.-)\n") do
            buf.lines[#buf.lines + 1] = line
        end
        if #buf.lines == 0 then buf.lines[1] = "" end
        buf.row, buf.col, buf.scroll = 1, 0, 0
    end

    beat("01-motion")
    click(500, 493) -- full motion
    beat("02-title")
    click(640, 694) -- begin
    beat("03-arrival")
    for _ = 1, 4 do click(1080, 717) end
    beat("04-hub")
    click(700, 171) -- Level 1 commission
    beat("05-commission")
    click(1080, 717) -- the brief
    beat("06-demo")
    for _ = 1, 3 do click(640, 604) end
    beat("07-editor-starter")
    set_buffer(1, require("fixtures").d1l1.solution)
    beat("08-editor-solution")
    click(1045, 82) -- run the gate
    beat("09-gate-pass")
    click(640, 714) -- to the hall
    -- Seal levels 2 and 3 silently, then show a backlash and the boss.
    local Levels = require("levels")
    local Boss = require("boss")
    local function seal(level, board_y, demo_cards, srcs)
        click(700, board_y)
        click(1080, 717)
        for _ = 1, demo_cards do click(640, 604) end
        for i, s in ipairs(srcs) do set_buffer(i, s) end
        click(1045, 82)
        click(640, 714)
    end
    seal(Levels[2], 247, 2, { F.d1l2.solution })
    seal(Levels[3], 323, 2, { F.d1l3.solution })
    -- Backlash: practice Level 1 with the wrong program.
    click(700, 171)
    click(1080, 717)
    for _ = 1, 3 do click(640, 604) end
    set_buffer(1, F.d1l1.wrong)
    click(1045, 82)
    beat("10-gate-fail")
    click(430, 714) -- hear the Keeper
    beat("11-backlash")
    click(430, 646) -- back to the writing surface
    set_buffer(1, F.d1l1.solution)
    click(1045, 82)
    click(640, 714)
    -- The boss, both acts on the surface.
    click(700, 399)
    click(1080, 717)
    click(640, 604)
    set_buffer(1, F.boss_act1.solution)
    click(727, 84) -- Act II tab
    set_buffer(2, F.boss_act2.solution)
    beat("12-editor-boss")
    click(1045, 82)
    beat("13-gate-boss-pass")
    click(640, 714) -- see the seal
    beat("14-completion")
    click(480, 664) -- the chronicle
    beat("15-chronicle")
    click(640, 602) -- back
    app:event({ type = "key", key = "escape" })
    click(530, 543) -- the codex
    beat("16-codex")
    click(640, 602) -- back to the hall
    click(1098, 543) -- the guest book, kept by the player's own ledger
    beat("17-guestbook")
    click(936, 493) -- the absent name, received at the door
    beat("18-guestbook-absence")
    return true
end

return Shots
