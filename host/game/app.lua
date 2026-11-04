-- Versemend — the playable slice: Domain 1 of the Old Tongue.
-- The whole game flow lives here, in plain Lua, against a small
-- platform interface (draw primitives, events, sound cues, one save
-- file). Any host that implements the interface runs the same game:
-- the SDL host in host/, the mock platform in tests/, and whichever
-- engine the spike's verdict names. Game logic never reads a clock;
-- time enters only through update(dt_ms) and touches only motion.
package.path = package.path .. ";./game/?.lua"
local Content = require("content")
local Levels = require("levels")
local Boss = require("boss")
local Gate = require("gate")
local Save = require("save")
local Effects = require("effects")

local W, H = 1280, 800

local App = {}
App.__index = App

local function level_by_id(id)
    for _, l in ipairs(Levels) do
        if l.id == id then return l end
    end
    if Boss.id == id then return Boss end
    return nil
end

function App.new(platform)
    local self = setmetatable({}, App)
    self.p = platform
    self.transcript = {}
    self.buttons = {}
    local saved = nil
    local raw = platform.read_save()
    if raw then saved = Save.parse(raw) end
    self.state = saved or Save.fresh()
    self.corrupt_save = (raw ~= nil and saved == nil)
    self.screen = self.state.motion_chosen and "title" or "motion"
    self.dialogue = nil
    self.editor = nil
    self.gate_view = nil
    self.effect = nil
    self.time_ms = 0
    self.scroll = 0
    self:log("screen " .. self.screen)
    return self
end

function App:log(line)
    self.transcript[#self.transcript + 1] = line
end

function App:persist()
    local bytes = Save.serialize(self.state)
    self.p.write_save(bytes)
    self:log("save " .. Gate.checksum(bytes))
end

function App:go(screen)
    self.screen = screen
    self.scroll = 0
    self:log("screen " .. screen)
    self.p.set_text_input(screen == "editor")
    if screen ~= "editor" then self.editor_focus = false end
end

-- ---------- shared drawing helpers ----------

function App:wrap(text, kind, max_w)
    local lines = {}
    for _, para in ipairs(type(text) == "table" and text or { text }) do
        local cur = ""
        for word in para:gmatch("%S+") do
            local trial = (cur == "") and word or (cur .. " " .. word)
            local w = self.p.measure(trial, kind)
            if w > max_w and cur ~= "" then
                lines[#lines + 1] = cur
                cur = word
            else
                cur = trial
            end
        end
        lines[#lines + 1] = cur
    end
    return lines
end

function App:text_block(x, y, text, kind, color, max_w, leading)
    local lines = self:wrap(text, kind, max_w)
    local _, lh = self.p.measure("Ag", kind)
    leading = leading or math.floor(lh * 1.35)
    for i, line in ipairs(lines) do
        self.p.draw_text(x, y + (i - 1) * leading, line, kind, color)
    end
    return y + #lines * leading
end

function App:button(x, y, w, h, id, label, kind)
    kind = kind or "body"
    self.buttons[#self.buttons + 1] =
        { x = x, y = y, w = w, h = h, id = id }
    self.p.draw_rect(x, y, w, h, "ink_blue", 235)
    self.p.draw_rect(x, y, w, 2, "amber", 255)
    local tw = self.p.measure(label, kind)
    local _, th = self.p.measure("Ag", kind)
    self.p.draw_text(x + math.floor((w - tw) / 2),
        y + math.floor((h - th) / 2), label, kind, "parchment")
end

function App:plate(x, y, w, h)
    self.p.draw_rect(x, y, w, h, "parchment", 245)
    self.p.draw_rect(x, y, w, 3, "amber", 255)
    self.p.draw_rect(x, y + h - 3, w, 3, "amber", 255)
end

-- ---------- dialogue ----------

function App:start_dialogue(pages, after)
    self.dialogue = { pages = pages, index = 1, after = after }
end

function App:render_dialogue()
    local d = self.dialogue
    local page = d.pages[d.index]
    local x, y, w, h = 90, 560, 1100, 190
    self.p.draw_image("frame", x - 14, y - 14, w + 28, h + 28, 255)
    self:plate(x, y, w, h)
    if page.speaker then
        self.p.draw_text(x + 28, y + 16, page.speaker, "body_bold", "ink_blue")
    end
    self:text_block(x + 28, y + 52, page.lines, "body", "ink", w - 56)
    self:button(x + w - 190, y + h - 52, 160, 38, "dlg_next",
        d.index < #d.pages and "Continue" or "Begin", "body")
end

function App:advance_dialogue()
    local d = self.dialogue
    self.p.sound("page")
    if d.index < #d.pages then
        d.index = d.index + 1
    else
        local after = d.after
        self.dialogue = nil
        if after then after(self) end
    end
end

-- ---------- events ----------

function App:event(ev)
    if ev.type == "click" then
        for i = #self.buttons, 1, -1 do
            local b = self.buttons[i]
            if ev.x >= b.x and ev.x < b.x + b.w
                and ev.y >= b.y and ev.y < b.y + b.h then
                self:on_button(b.id)
                return
            end
        end
        if self.screen == "editor" then self:editor_click(ev.x, ev.y) end
    elseif ev.type == "text" then
        if self.screen == "editor" then self:editor_text(ev.text) end
    elseif ev.type == "key" then
        self:on_key(ev.key)
    end
end

function App:on_key(key)
    if self.dialogue then
        if key == "return" or key == "space" then self:advance_dialogue() end
        return
    end
    if self.screen == "editor" then
        self:editor_key(key)
    elseif self.screen == "gate" and key == "pagedown" then
        self.scroll = self.scroll + 10
    elseif self.screen == "gate" and key == "pageup" then
        self.scroll = math.max(0, self.scroll - 10)
    elseif self.screen == "demo" and key == "return" then
        self:demo_advance()
    elseif key == "return" then
        if self.screen == "motion" then self:choose_motion("full")
        elseif self.screen == "title" then self:title_begin()
        elseif self.screen == "gate" then self:go("hub")
        elseif self.screen == "backlash" then self:backlash_to_editor()
        elseif self.screen == "completion" then self:go("title")
        end
    elseif key == "escape" then
        if self.screen == "codex" or self.screen == "chronicle" then
            self:go("hub")
        elseif self.screen == "gate" then
            self:go("hub")
        end
    end
end

-- ---------- update / effects ----------

function App:start_effect(name)
    if self.state.settings.motion == "reduced" then return end
    self.effect = { name = name, t = 0 }
end

function App:update(dt_ms)
    self.time_ms = self.time_ms + dt_ms
    if self.effect then
        local def = Effects.effects[self.effect.name]
        self.effect.t = self.effect.t + dt_ms
        if def.duration_ms and self.effect.t >= def.duration_ms then
            local done = self.effect.on_done
            self.effect = nil
            if done then done(self) end
        end
    end
end

function App:render_effects()
    if self.state.settings.motion ~= "full" then return end
    local b = 0
    if self.screen == "hub" then
        b = Effects.effects.lamp_breathe.brightness(self.time_ms)
    end
    if self.effect then
        b = Effects.effects[self.effect.name].brightness(self.effect.t)
    end
    if b > 0.004 then
        self.p.draw_rect(0, 0, W, H, "amber", math.floor(b * 255))
    elseif b < -0.004 then
        self.p.draw_rect(0, 0, W, H, "ink", math.floor(-b * 255))
    end
end

-- ---------- screens: motion & title ----------

function App:choose_motion(mode)
    self.state.settings.motion = mode
    self.state.motion_chosen = true
    self:persist()
    self:go("title")
end

function App:title_begin()
    if not self.state.seen_arrival then
        self.state.seen_arrival = true
        self:persist()
        self:go("arrival")
        self:start_dialogue(Content.arrival, function(app) app:go("hub") end)
    else
        self:go("hub")
    end
end

function App:render_motion()
    self.p.draw_image("town", 0, 0, W, H, 255)
    self.p.draw_rect(0, 0, W, H, "ink", 120)
    self:plate(340, 250, 600, 300)
    local m = Content.motion_prompt
    local tw = self.p.measure(m.title, "display")
    self.p.draw_text(math.floor((W - tw) / 2), 286, m.title, "display", "ink_blue")
    self:text_block(380, 340, m.lines, "body", "ink", 520)
    self:button(390, 470, 220, 46, "motion_full", m.full)
    self:button(670, 470, 220, 46, "motion_reduced", m.reduced)
end

function App:render_title()
    self.p.draw_image("town", 0, 0, W, H, 255)
    self.p.draw_rect(0, 470, W, 330, "ink", 150)
    local tw = self.p.measure(Content.game_title, "title")
    self.p.draw_text(math.floor((W - tw) / 2), 486, Content.game_title,
        "title", "amber")
    local sw = self.p.measure(Content.game_subtitle, "display")
    self.p.draw_text(math.floor((W - sw) / 2), 566, Content.game_subtitle,
        "display", "parchment")
    local nw = self.p.measure(Content.course_name, "body")
    self.p.draw_text(math.floor((W - nw) / 2), 622, Content.course_name,
        "body", "parchment")
    local begin_label = self.state.seen_arrival
        and Content.title.continue_journey or Content.title.begin
    self:button(440, 668, 400, 52, "title_begin", begin_label, "display")
    local motion_label = self.state.settings.motion == "full"
        and Content.title.motion_full or Content.title.motion_reduced
    self:button(990, 668, 240, 52, "title_motion", motion_label, "body")
    if self.corrupt_save then
        self.p.draw_text(40, 756,
            "An old chronicle could not be verified and was set aside.",
            "small", "parchment")
    end
end

-- ---------- screens: hub ----------

function App:board_entries()
    local entries = {}
    for _, l in ipairs(Levels) do
        entries[#entries + 1] = { level = l, boss = false }
    end
    entries[#entries + 1] = { level = Boss, boss = true }
    return entries
end

function App:boss_unlocked()
    for _, l in ipairs(Levels) do
        if not self.state.sealed[l.id] then return false end
    end
    return true
end

function App:render_hub()
    self.p.draw_image("town", 0, 0, W, H, 255)
    self.p.draw_rect(0, 0, W, H, "ink", 90)
    -- The Keeper, at the left of the hall.
    self:plate(36, 36, 300, 560)
    self.p.draw_image("keeper", 52, 52, 268, 335, 255)
    self:text_block(52, 404, Content.hub.keeper_idle, "body", "ink", 268)
    -- The commission board.
    local bx, by, bw = 372, 36, 872
    self:plate(bx, by, bw, 560)
    self.p.draw_text(bx + 28, by + 18, Content.hub.board_title,
        "display", "ink_blue")
    self.p.draw_text(bx + 28, by + 64, Content.hub.board_note,
        "small", "ink")
    local y = by + 104
    for _, e in ipairs(self:board_entries()) do
        local l = e.level
        local label, status
        if e.boss then
            if self.state.boss_done then
                label = l.title .. " — fallen"
                status = Content.hub.practice_mark
            elseif self:boss_unlocked() then
                label = Content.hub.boss_open
                status = ""
            else
                label = Content.hub.boss_locked
                status = "locked"
            end
        else
            label = ("Level %d — %s (%s)"):format(l.number, l.title, l.mechanism)
            status = self.state.sealed[l.id]
                and Content.hub.practice_mark or ""
        end
        local locked = e.boss and not self:boss_unlocked()
            and not self.state.boss_done
        self:button(bx + 28, y, bw - 56, 62,
            "board_" .. l.id, label, "body")
        if status ~= "" then
            self.p.draw_text(bx + 44, y + 40, status, "small",
                locked and "amber" or "leaf")
        end
        y = y + 76
    end
    self:button(bx + 28, 520, 260, 46, "hub_codex", Content.hub.codex_button)
    self:button(bx + 312, 520, 260, 46, "hub_chronicle",
        Content.hub.chronicle_button)
    -- The standing-gates board, at the door.
    self:plate(36, 640, 1208, 120)
    self:text_block(60, 664, {
        "The standing gates: every commission is proved in running code —",
        "execution, the full suite (half validation, half adversarial),",
        "the leak audit, and the determinism of the record.",
    }, "body", "ink", 1160)
end

function App:start_commission(level)
    self.p.sound("lamp")
    self.current = level
    self.practice = (level.id == Boss.id and self.state.boss_done)
        or (level.id ~= Boss.id and self.state.sealed[level.id]) or false
    local pages = { { speaker = "The Keeper of Lamps", lines = level.brief } }
    self:go("commission")
    self:start_dialogue(pages, function(app)
        app.demo_index = 1
        app:go("demo")
    end)
end

-- ---------- screens: demo ----------

function App:render_demo()
    local level = self.current
    local card = level.demo[self.demo_index]
    self.p.draw_image("town", 0, 0, W, H, 255)
    self.p.draw_rect(0, 0, W, H, "ink", 160)
    self:plate(140, 90, 1000, 560)
    self.p.draw_text(180, 122, Content.demo_intro, "small", "ink_blue")
    self.p.draw_text(180, 152, card.title, "display", "ink_blue")
    local y = self:text_block(180, 210, card.lines, "body", "ink", 920)
    local bw = 200
    local total = #card.boxes * bw + (#card.boxes - 1) * 24
    local x = math.floor((W - total) / 2)
    for _, box in ipairs(card.boxes) do
        self.p.draw_rect(x, 430, bw, 110, "ink_blue", 255)
        local tw = self.p.measure(box.text, "display")
        self.p.draw_text(x + math.floor((bw - tw) / 2), 452, box.text,
            "display", "parchment")
        local sw = self.p.measure(box.sub, "body_bold")
        self.p.draw_text(x + math.floor((bw - sw) / 2), 500, box.sub,
            "body_bold", "amber")
        x = x + bw + 24
    end
    local last = self.demo_index >= #level.demo
    self:button(490, 580, 300, 48, "demo_next",
        last and Content.demo_to_editor or Content.demo_next, "body")
    local _ = y
end

function App:demo_advance()
    local level = self.current
    if self.demo_index < #level.demo then
        self.demo_index = self.demo_index + 1
        self.p.sound("page")
    else
        self:open_editor(level)
    end
end

-- ---------- the writing surface ----------

local TOKENS = {
    "local ", "function ", "end", "if ", "then ", "else ", "return ",
    "== ", "~= ", ".. ", "type(", "pairs(", "ipairs(", "table.sort(",
    "nil", "false", "true",
}

local function split_lines(source)
    local lines = {}
    for line in (source .. "\n"):gmatch("(.-)\n") do
        lines[#lines + 1] = line
    end
    if #lines == 0 then lines[1] = "" end
    return lines
end

local function join_lines(lines)
    return table.concat(lines, "\n") .. "\n"
end

function App:open_editor(level)
    local acts = level.acts or { level }
    local buffers = {}
    for i, act in ipairs(acts) do
        local draft = self.state.drafts[act.id]
        buffers[i] = {
            lines = split_lines(draft or act.starter),
            row = 1, col = 0, scroll = 0,
        }
    end
    self.editor = {
        level = level, act = 1, buffers = buffers,
        show_contract = false,
    }
    self:go("editor")
end

function App:ed_buf()
    return self.editor.buffers[self.editor.act]
end

function App:ed_act()
    local level = self.editor.level
    if level.acts then return level.acts[self.editor.act] end
    return level
end

function App:ed_persist_drafts()
    local level = self.editor.level
    local acts = level.acts or { level }
    for i, act in ipairs(acts) do
        self.state.drafts[act.id] =
            join_lines(self.editor.buffers[i].lines)
    end
    self:persist()
end

function App:editor_text(text)
    local buf = self:ed_buf()
    for i = 1, #text do
        local ch = text:sub(i, i)
        if ch == "\n" then
            self:editor_key("return")
        elseif ch >= " " then
            local line = buf.lines[buf.row]
            buf.lines[buf.row] = line:sub(1, buf.col) .. ch
                .. line:sub(buf.col + 1)
            buf.col = buf.col + 1
        end
    end
end

function App:editor_key(key)
    local buf = self:ed_buf()
    local line = buf.lines[buf.row]
    if key == "backspace" then
        if buf.col > 0 then
            buf.lines[buf.row] = line:sub(1, buf.col - 1)
                .. line:sub(buf.col + 1)
            buf.col = buf.col - 1
        elseif buf.row > 1 then
            local prev = buf.lines[buf.row - 1]
            buf.col = #prev
            buf.lines[buf.row - 1] = prev .. line
            table.remove(buf.lines, buf.row)
            buf.row = buf.row - 1
        end
    elseif key == "delete" then
        if buf.col < #line then
            buf.lines[buf.row] = line:sub(1, buf.col)
                .. line:sub(buf.col + 2)
        elseif buf.row < #buf.lines then
            buf.lines[buf.row] = line .. buf.lines[buf.row + 1]
            table.remove(buf.lines, buf.row + 1)
        end
    elseif key == "return" then
        buf.lines[buf.row] = line:sub(1, buf.col)
        table.insert(buf.lines, buf.row + 1, line:sub(buf.col + 1))
        buf.row = buf.row + 1
        buf.col = 0
    elseif key == "tab" then
        self:editor_text("    ")
    elseif key == "left" then
        if buf.col > 0 then buf.col = buf.col - 1
        elseif buf.row > 1 then
            buf.row = buf.row - 1
            buf.col = #buf.lines[buf.row]
        end
    elseif key == "right" then
        if buf.col < #line then buf.col = buf.col + 1
        elseif buf.row < #buf.lines then
            buf.row = buf.row + 1
            buf.col = 0
        end
    elseif key == "up" then
        if buf.row > 1 then
            buf.row = buf.row - 1
            buf.col = math.min(buf.col, #buf.lines[buf.row])
        end
    elseif key == "down" then
        if buf.row < #buf.lines then
            buf.row = buf.row + 1
            buf.col = math.min(buf.col, #buf.lines[buf.row])
        end
    elseif key == "home" then
        buf.col = 0
    elseif key == "end" then
        buf.col = #line
    elseif key == "pageup" then
        buf.row = math.max(1, buf.row - 15)
        buf.col = math.min(buf.col, #buf.lines[buf.row])
    elseif key == "pagedown" then
        buf.row = math.min(#buf.lines, buf.row + 15)
        buf.col = math.min(buf.col, #buf.lines[buf.row])
    elseif key == "f5" then
        self:run_gate()
    elseif key == "escape" then
        self:ed_persist_drafts()
        self:go("hub")
    end
end

local ED_X, ED_Y, ED_W, ED_H = 70, 118, 1140, 520
local ED_GUTTER = 64
local ED_LINE_H = 24

function App:editor_click(x, y)
    local buf = self:ed_buf()
    if x < ED_X + ED_GUTTER or x >= ED_X + ED_W
        or y < ED_Y or y >= ED_Y + ED_H then
        return
    end
    local row = buf.scroll + math.floor((y - ED_Y) / ED_LINE_H) + 1
    row = math.max(1, math.min(#buf.lines, row))
    buf.row = row
    local line = buf.lines[row]
    local char_w = self.p.measure("M", "code")
    local col = math.floor((x - ED_X - ED_GUTTER) / char_w + 0.5)
    buf.col = math.max(0, math.min(#line, col))
end

function App:render_editor()
    local ed = self.editor
    local level = ed.level
    local act = self:ed_act()
    local buf = self:ed_buf()
    self.p.draw_image("frame", 0, 0, W, H, 255)
    self.p.draw_rect(0, 0, W, H, "ink", 90)
    self.p.draw_text(70, 26, level.title .. Content.editor.title_suffix,
        "display", "parchment")
    if level.acts then
        for i, a in ipairs(level.acts) do
            self:button(340 + (i - 1) * 262, 66, 250, 36,
                "ed_tab" .. i, ("Act %d — %s"):format(i, a.title), "small")
        end
    end
    -- The ink-blue plate.
    self.p.draw_rect(ED_X, ED_Y, ED_W, ED_H, "ink_blue", 255)
    self.p.draw_rect(ED_X, ED_Y, ED_GUTTER, ED_H, "ink", 60)
    -- Keep the caret in view.
    if buf.row - buf.scroll < 1 then buf.scroll = buf.row - 1 end
    if buf.row - buf.scroll > 21 then buf.scroll = buf.row - 21 end
    local _, lh = self.p.measure("Ag", "code")
    local first = buf.scroll + 1
    local last = math.min(#buf.lines, buf.scroll + 21)
    for row = first, last do
        local y = ED_Y + (row - buf.scroll - 1) * ED_LINE_H + 3
        self.p.draw_text(ED_X + 12, y, tostring(row), "code_small", "amber")
        self.p.draw_text(ED_X + ED_GUTTER + 8, y, buf.lines[row],
            "code", "parchment")
    end
    -- The caret (a drawn bar; blinking is motion, logic never reads it).
    if (self.time_ms % 1000) < 600
        or self.state.settings.motion == "reduced" then
        local char_w = self.p.measure("M", "code")
        local cx = ED_X + ED_GUTTER + 8 + buf.col * char_w
        local cy = ED_Y + (buf.row - buf.scroll - 1) * ED_LINE_H + 3
        self.p.draw_rect(cx, cy, 2, lh, "amber", 255)
    end
    -- Token keys: entry assistance, never answers.
    local tx = 70
    for i, tok in ipairs(TOKENS) do
        local label = tok:gsub("%s+$", "")
        local w = self.p.measure(label, "code_small") + 18
        self:button(tx, 652, w, 34, "token_" .. i, label, "code_small")
        tx = tx + w + 8
        if tx > 1050 then break end
    end
    self.p.draw_text(70, 700, Content.editor.token_note, "small", "parchment")
    -- The working buttons.
    self:button(880, 58, 330, 48, "ed_run", Content.editor.run_gate, "body")
    self:button(880, 700, 150, 40, "ed_contract", Content.editor.contract, "small")
    local used = self.state.hints_used[act.id] or 0
    local hlabel = Content.editor.hints .. (" (%d/%d)"):format(
        math.min(used + 1, #act.hints), #act.hints)
    if used >= #act.hints then hlabel = Content.editor.hints .. " — spent" end
    self:button(1046, 700, 164, 40, "ed_hint", hlabel, "small")
    self:button(70, 58, 240, 40, "ed_back", Content.editor.back, "small")
    if ed.show_contract then
        self:plate(240, 130, 800, 500)
        self:text_block(276, 160, act.contract, "code", "ink", 730)
        self:button(520, 570, 240, 44, "ed_contract_close", "Close", "body")
    elseif ed.hint_text then
        self:plate(240, 520, 800, 150)
        self:text_block(276, 546, ed.hint_text, "body", "ink", 730)
    end
end

-- ---------- the gate, run ----------

function App:run_gate()
    local ed = self.editor
    local level = ed.level
    self:ed_persist_drafts()
    local record, passed
    if level.acts then
        local sources = {}
        for i in ipairs(level.acts) do
            sources[i] = join_lines(ed.buffers[i].lines)
        end
        record, passed = Gate.run(level, sources)
    else
        record, passed = Gate.run(level,
            join_lines(ed.buffers[1].lines))
    end
    for line in record:gmatch("[^\n]+") do self:log(line) end
    self:log("gate " .. level.id .. " checksum " .. Gate.checksum(record))
    -- The first failure, in the Keeper's plain words.
    local fail_say, fail_id = nil, nil
    if not passed then
        local acts = level.acts or { level }
        for _, act in ipairs(acts) do
            for _, t in ipairs(act.tests) do
                if record:find("test " .. t.id .. " FAIL", 1, true) then
                    fail_say, fail_id = t.say, t.id
                    break
                end
            end
            if fail_say then break end
        end
        if not fail_say then
            if record:find("leak FAIL", 1, true) then
                fail_say = "A name was proclaimed that no contract allows. "
                    .. "What a program creates beyond its stated surface, "
                    .. "the whole hall must answer for."
                fail_id = "leak"
            elseif record:find("budget FAIL", 1, true) then
                fail_say = "The work did not end. A journey states its "
                    .. "length; unbounded work is refused by contract, "
                    .. "not endured."
                fail_id = "budget"
            else
                fail_say = "The inscription did not run. Read the "
                    .. "gate's record: the first line that failed is "
                    .. "where the seam is."
                fail_id = "load"
            end
        end
    end
    self.gate_view = {
        record = record, passed = passed, level = level,
        fail_say = fail_say, fail_id = fail_id,
    }
    if passed then
        self.p.sound("bell")
        if not self.practice then
            if level.id == Boss.id then
                self.state.boss_done = true
            else
                self.state.sealed[level.id] = true
            end
            self:persist()
            self:log("seal " .. level.id)
        end
        self:start_effect("seal_glow")
    else
        self:log("backlash " .. level.id .. " " .. tostring(fail_id))
    end
    self:go("gate")
end

function App:render_gate()
    local gv = self.gate_view
    self.p.draw_image("town", 0, 0, W, H, 255)
    self.p.draw_rect(0, 0, W, H, "ink", 140)
    local title = gv.passed and Content.gate.pass_title
        or Content.gate.fail_title
    local tw = self.p.measure(title, "display")
    self.p.draw_text(math.floor((W - tw) / 2), 40, title, "display",
        gv.passed and "amber" or "parchment")
    self:plate(190, 110, 900, 500)
    local lines = {}
    for line in gv.record:gmatch("[^\n]+") do lines[#lines + 1] = line end
    local _, lh = self.p.measure("Ag", "code_small")
    local per = 26
    local first = self.scroll + 1
    local last = math.min(#lines, self.scroll + per)
    for i = first, last do
        self.p.draw_text(226, 126 + (i - first) * (lh + 4), lines[i],
            "code_small", "ink")
    end
    self:text_block(190, 626, Content.gate.record_note, "small",
        "parchment", 900)
    if gv.passed then
        if gv.level.id == Boss.id and not self.practice then
            self:button(440, 690, 400, 48, "gate_primary",
                "See the Seal", "body")
        else
            self:button(440, 690, 400, 48, "gate_primary",
                Content.gate.to_hall, "body")
        end
    else
        self:button(240, 690, 380, 48, "gate_keeper",
            "Hear the Keeper", "body")
        self:button(660, 690, 380, 48, "gate_editor",
            Content.backlash.to_editor, "body")
    end
end

function App:render_backlash()
    local gv = self.gate_view
    self.p.draw_image("town", 0, 0, W, H, 255)
    self.p.draw_rect(0, 0, W, H, "ink", 190)
    local tw = self.p.measure(Content.backlash.title, "title")
    self.p.draw_text(math.floor((W - tw) / 2), 90, Content.backlash.title,
        "title", "parchment")
    self:plate(240, 220, 800, 330)
    local y = self:text_block(276, 250, Content.backlash.intro,
        "body", "ink", 730)
    self:text_block(276, y + 12, { "\"" .. (gv.fail_say or "") .. "\"" },
        "body_bold", "ink_blue", 730)
    self.p.draw_text(276, y + 96, "— The Keeper of Lamps", "body", "ink")
    self:button(240, 620, 380, 52, "backlash_editor",
        Content.backlash.to_editor, "body")
    self:button(660, 620, 380, 52, "backlash_hall",
        Content.backlash.to_hall, "body")
end

function App:backlash_to_editor()
    self:open_editor(self.gate_view.level)
end

-- ---------- codex, chronicle, completion ----------

function App:render_codex()
    self.p.draw_image("town", 0, 0, W, H, 255)
    self.p.draw_rect(0, 0, W, H, "ink", 150)
    self:plate(240, 90, 800, 560)
    if self.state.boss_done then
        self.p.draw_text(276, 120, Content.codex_d1.title,
            "display", "ink_blue")
        self.p.draw_text(276, 176, Content.codex_d1.entry_title,
            "body_bold", "ink")
        local y = self:text_block(276, 216, Content.codex_d1.lines,
            "body", "ink", 730)
        self:text_block(276, y + 16, Content.codex_d1.loot_line,
            "body_bold", "ink_blue", 730)
    else
        self.p.draw_text(276, 120, Content.codex_empty.title,
            "display", "ink_blue")
        self:text_block(276, 176, Content.codex_empty.lines,
            "body", "ink", 730)
    end
    self:button(520, 580, 240, 44, "page_back", Content.gate.to_hall, "body")
end

function App:render_chronicle()
    self.p.draw_image("town", 0, 0, W, H, 255)
    self.p.draw_rect(0, 0, W, H, "ink", 150)
    self:plate(240, 90, 800, 560)
    self.p.draw_text(276, 120, Content.chronicle.title,
        "display", "ink_blue")
    local y = 180
    local any = false
    local keys = { "d1l1", "d1l2", "d1l3" }
    for _, id in ipairs(keys) do
        if self.state.sealed[id] then
            any = true
            y = self:text_block(276, y,
                { "✓ " .. Content.chronicle[id] }, "body", "ink", 730) + 8
        end
    end
    if self.state.boss_done then
        any = true
        y = self:text_block(276, y,
            { "✓ " .. Content.chronicle.d1boss }, "body", "ink", 730) + 8
    end
    if not any then
        y = self:text_block(276, y, Content.chronicle.empty,
            "body", "ink", 730)
    elseif self.state.boss_done then
        y = self:text_block(276, y + 12, Content.chronicle.closing,
            "body", "ink_blue", 730)
    end
    self:button(520, 580, 240, 44, "page_back", Content.gate.to_hall, "body")
end

function App:render_completion()
    self.p.draw_image("town", 0, 0, W, H, 255)
    self.p.draw_rect(0, 0, W, H, "ink", 130)
    self:plate(240, 150, 800, 430)
    local tw = self.p.measure(Content.completion.title, "display")
    self.p.draw_text(math.floor((W - tw) / 2), 190,
        Content.completion.title, "display", "ink_blue")
    self:text_block(300, 260, Content.completion.lines, "body", "ink", 680)
    self:button(340, 640, 280, 48, "completion_chronicle",
        Content.hub.chronicle_button, "body")
    self:button(660, 640, 280, 48, "completion_title",
        Content.completion.to_title, "body")
end

-- ---------- dispatch ----------

function App:on_button(id)
    if self.dialogue then
        if id == "dlg_next" then self:advance_dialogue() end
        return
    end
    if id == "motion_full" then self:choose_motion("full")
    elseif id == "motion_reduced" then self:choose_motion("reduced")
    elseif id == "title_begin" then self:title_begin()
    elseif id == "title_motion" then
        self.state.settings.motion =
            self.state.settings.motion == "full" and "reduced" or "full"
        self:persist()
    elseif id:sub(1, 6) == "board_" then
        local level = level_by_id(id:sub(7))
        if level then
            if level.id == Boss.id and not self:boss_unlocked()
                and not self.state.boss_done then
                return
            end
            self:start_commission(level)
        end
    elseif id == "hub_codex" then self:go("codex")
    elseif id == "hub_chronicle" then self:go("chronicle")
    elseif id == "demo_next" then
        self:demo_advance()
    elseif id == "ed_run" then self:run_gate()
    elseif id == "ed_back" then
        self:ed_persist_drafts()
        self:go("hub")
    elseif id == "ed_contract" then self.editor.show_contract = true
    elseif id == "ed_contract_close" then self.editor.show_contract = false
    elseif id == "ed_hint" then
        local act = self:ed_act()
        local used = self.state.hints_used[act.id] or 0
        if used < #act.hints then
            used = used + 1
            self.state.hints_used[act.id] = used
            self.editor.hint_text = act.hints[used]
            self:persist()
        end
    elseif id:sub(1, 6) == "ed_tab" then
        self.editor.act = tonumber(id:sub(7))
    elseif id:sub(1, 6) == "token_" then
        local tok = TOKENS[tonumber(id:sub(7))]
        if tok then self:editor_text(tok) end
    elseif id == "gate_primary" then
        if self.gate_view.level.id == Boss.id and not self.practice then
            self:go("completion")
        else
            self:go("hub")
        end
    elseif id == "gate_keeper" then
        self.p.sound("thud")
        self:start_effect("backlash_dim")
        self:go("backlash")
    elseif id == "gate_editor" or id == "backlash_editor" then
        self:backlash_to_editor()
    elseif id == "backlash_hall" then self:go("hub")
    elseif id == "page_back" then self:go("hub")
    elseif id == "completion_chronicle" then self:go("chronicle")
    elseif id == "completion_title" then self:go("title")
    end
end

function App:render()
    self.buttons = {}
    local s = self.screen
    if s == "motion" then self:render_motion()
    elseif s == "title" then self:render_title()
    elseif s == "arrival" then
        self:render_title()
    elseif s == "hub" or s == "commission" then self:render_hub()
    elseif s == "demo" then self:render_demo()
    elseif s == "editor" then self:render_editor()
    elseif s == "gate" then self:render_gate()
    elseif s == "backlash" then self:render_backlash()
    elseif s == "codex" then self:render_codex()
    elseif s == "chronicle" then self:render_chronicle()
    elseif s == "completion" then self:render_completion()
    end
    if self.dialogue then self:render_dialogue() end
    self:render_effects()
end

return App
