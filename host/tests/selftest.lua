-- The slice's proof script. Runs identically under the system Lua
-- interpreter (tests/run-all.lua) and inside the shipped binary
-- (host --selftest): unit gates for the harness, the save, and the
-- photosafety law, then a full scripted playthrough of the loop —
-- title, hall, three commissions, a backlash, the boss, the seal —
-- asserting screens, verdicts, and the chronicle as it goes.
-- Output: a transcript. The two runs' transcripts must be
-- byte-identical; the harness diffs them.
local Selftest = {}

function Selftest.run(platform_factory)
    local out = {}
    local failures = 0
    local function emit(s) out[#out + 1] = s end
    local function check(name, cond)
        if cond then
            emit("check " .. name .. " PASS")
        else
            emit("check " .. name .. " FAIL")
            failures = failures + 1
        end
    end

    local Gate = require("gate")
    local Levels = require("levels")
    local Boss = require("boss")
    local Save = require("save")
    local Effects = require("effects")
    local F = require("fixtures")

    local level_by_id = {}
    for _, l in ipairs(Levels) do level_by_id[l.id] = l end

    -- ---- unit: the harness against fixtures, five runs each ----
    local function gate_unit(level, source, want_pass, tag)
        local sums = {}
        local verdicts = {}
        for i = 1, 5 do
            local record, passed = Gate.run(level, source)
            sums[i] = Gate.checksum(record)
            verdicts[i] = passed
        end
        local stable = true
        for i = 2, 5 do
            if sums[i] ~= sums[1] or verdicts[i] ~= verdicts[1] then
                stable = false
            end
        end
        check(tag .. " verdict", verdicts[1] == want_pass)
        check(tag .. " deterministic-x5", stable)
        emit("unit " .. tag .. " checksum " .. sums[1])
        return Gate.run(level, source)
    end

    for _, l in ipairs(Levels) do
        local fix = F[l.id]
        gate_unit(l, fix.solution, true, l.id .. "-solution")
        local wrong_record = gate_unit(l, fix.wrong, false, l.id .. "-wrong")
        check(l.id .. "-wrong-first-fail",
            wrong_record:find("test " .. fix.wrong_first_fail .. " FAIL",
                1, true) ~= nil)
    end
    -- Hostile programs, against Level 1's suite.
    local l1 = level_by_id.d1l1
    local rec_run = gate_unit(l1, F.hostile.runaway, false, "hostile-runaway")
    check("hostile-runaway budget",
        rec_run:find("budget FAIL", 1, true) ~= nil)
    local rec_co = gate_unit(l1, F.hostile.coroutine_runaway, false,
        "hostile-coroutine")
    check("hostile-coroutine budget",
        rec_co:find("budget FAIL", 1, true) ~= nil)
    local rec_leak = gate_unit(l1, F.hostile.leaker, false, "hostile-leaker")
    check("hostile-leaker leak",
        rec_leak:find("leak FAIL total", 1, true) ~= nil)
    local rec_miss = gate_unit(l1, F.hostile.missing, false, "hostile-missing")
    check("hostile-missing named",
        rec_miss:find("tests FAIL census-missing", 1, true) ~= nil)

    -- The boss: both acts together.
    local function boss_unit(src1, src2, want, tag)
        local sums, verdicts = {}, {}
        for i = 1, 5 do
            local record, passed = Gate.run(Boss, { src1, src2 })
            sums[i] = Gate.checksum(record)
            verdicts[i] = passed
        end
        local stable = true
        for i = 2, 5 do
            if sums[i] ~= sums[1] or verdicts[i] ~= verdicts[1] then
                stable = false
            end
        end
        check(tag .. " verdict", verdicts[1] == want)
        check(tag .. " deterministic-x5", stable)
        emit("unit " .. tag .. " checksum " .. sums[1])
        return Gate.run(Boss, { src1, src2 })
    end
    boss_unit(F.boss_act1.solution, F.boss_act2.solution, true, "boss-solution")
    local boss_wrong = boss_unit(F.boss_act1.solution, F.boss_act2.wrong,
        false, "boss-wrong")
    check("boss-wrong-first-fail",
        boss_wrong:find("test " .. F.boss_act2.wrong_first_fail .. " FAIL",
            1, true) ~= nil)

    -- ---- unit: the save round-trips, byte for byte ----
    do
        local st = Save.fresh()
        st.seen_arrival = true
        st.motion_chosen = true
        st.sealed.d1l1 = true
        st.drafts.d1l1 = F.d1l1.solution
        st.settings.motion = "reduced"
        local bytes1 = Save.serialize(st)
        local back, err = Save.parse(bytes1)
        check("save parses", back ~= nil)
        local bytes2 = back and Save.serialize(back) or ""
        check("save round-trip identical", bytes1 == bytes2)
        local corrupt = bytes1:sub(1, 40) .. "X" .. bytes1:sub(42)
        local bad = Save.parse(corrupt)
        check("save corruption refused", bad == nil)
        local future = Save.fresh()
        future.version = 2
        check("save version refused",
            Save.parse(Save.serialize(future)) == nil)
        emit("unit save checksum " .. Gate.checksum(bytes1))
    end

    -- ---- unit: the photosafety law, measured on the shipped curves ----
    do
        local names = {}
        for name in pairs(Effects.effects) do
            names[#names + 1] = name
        end
        table.sort(names)
        for _, name in ipairs(names) do
            local def = Effects.effects[name]
            local window = math.max(def.duration_ms or 10000, 1000)
            local rate = Effects.flashes_per_second(def, window, 120)
            check("flash " .. name, rate <= Effects.FLASH_PER_SECOND_MAX)
            emit(("unit flash %s %.3f"):format(name, rate))
        end
    end

    -- ---- the playthrough ----
    local Mock = platform_factory
    local platform = Mock.new()
    local App = require("app")
    local app = App.new(platform)

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

    check("boot screen", app.screen == "motion")
    app:render()
    click(500, 493) -- Motion: full
    check("title reached", app.screen == "title")
    click(640, 694) -- Begin the Journey
    check("arrival reached", app.screen == "arrival")
    for _ = 1, 4 do click(1080, 717) end -- the Keeper's four pages
    check("hub reached", app.screen == "hub")

    -- The guest book before the seal: present, and honestly closed.
    click(1098, 543) -- The Guest Book
    check("guestbook closed before the seal",
        app.screen == "guestbook" and app.guest_book.state == "closed")
    click(640, 602) -- back to the hall
    check("hub after guestbook", app.screen == "hub")

    local function play_level(level, board_y, solution, demo_cards)
        click(700, board_y) -- the commission board
        check(level.id .. " commission", app.screen == "commission")
        click(1080, 717) -- the brief
        check(level.id .. " demo", app.screen == "demo")
        for _ = 1, demo_cards do click(640, 604) end
        check(level.id .. " editor", app.screen == "editor")
        set_buffer(1, solution)
        click(1045, 82) -- Run the Gate
        check(level.id .. " gate pass",
            app.screen == "gate" and app.gate_view.passed)
        check(level.id .. " sealed", app.state.sealed[level.id] == true)
        click(640, 714) -- back to the hall
        check(level.id .. " hub again", app.screen == "hub")
    end

    play_level(level_by_id.d1l1, 171, F.d1l1.solution, 3)
    play_level(level_by_id.d1l2, 247, F.d1l2.solution, 2)
    play_level(level_by_id.d1l3, 323, F.d1l3.solution, 2)

    -- Practice at the yard: a wrong program, a backlash, a repair.
    click(700, 171)
    click(1080, 717)
    for _ = 1, 3 do click(640, 604) end
    check("practice editor", app.screen == "editor")
    -- The input path itself: type, correct, type.
    app:event({ type = "text", text = "ab" })
    app:event({ type = "key", key = "backspace" })
    app:event({ type = "text", text = "c" })
    check("typing path",
        app.editor.buffers[1].lines[1]:sub(1, 2) == "ac")
    set_buffer(1, F.d1l1.wrong)
    click(1045, 82)
    check("practice gate fails",
        app.screen == "gate" and not app.gate_view.passed)
    check("practice first fail named",
        app.gate_view.fail_id == F.d1l1.wrong_first_fail)
    click(430, 714) -- Hear the Keeper
    check("backlash reached", app.screen == "backlash")
    click(430, 646) -- Return to the Writing Surface
    check("backlash keeps the draft",
        app.screen == "editor"
            and table.concat(app.editor.buffers[1].lines, "\n")
                :find("value ~= nil", 1, true) ~= nil)
    set_buffer(1, F.d1l1.solution)
    click(1045, 82)
    check("practice repair passes",
        app.screen == "gate" and app.gate_view.passed)
    click(640, 714)
    check("hub after practice", app.screen == "hub")

    -- The boss.
    click(700, 399)
    check("boss commission", app.screen == "commission")
    click(1080, 717)
    for _ = 1, 1 do click(640, 604) end
    check("boss editor", app.screen == "editor")
    set_buffer(1, F.boss_act1.solution)
    click(727, 84) -- Act II tab
    set_buffer(2, F.boss_act2.solution)
    click(1045, 82)
    check("boss gate pass",
        app.screen == "gate" and app.gate_view.passed)
    check("boss sealed", app.state.boss_done == true)
    click(640, 714) -- See the Seal
    check("completion reached", app.screen == "completion")
    click(480, 664) -- The Chronicle
    check("chronicle reached", app.screen == "chronicle")
    click(640, 602) -- back to the hall
    check("hub after boss", app.screen == "hub")

    -- The leaf works in the world: the guest book is kept by the
    -- player's own sealed ledger program.
    click(1098, 543) -- The Guest Book
    check("guestbook open after the seal",
        app.screen == "guestbook" and app.guest_book.state == "open")
    click(360, 493) -- Ada
    check("guestbook finds Ada",
        app.guest_book.result ~= nil and app.guest_book.result.found
            and app.guest_book.result.attrs.seat == 4)
    click(744, 493) -- Cy
    check("guestbook keeps a chosen false",
        app.guest_book.result ~= nil and app.guest_book.result.found
            and app.guest_book.result.attrs.lamp == false)
    click(936, 493) -- The Hollow Guest — the absent name
    check("guestbook receives absence",
        app.guest_book.result ~= nil
            and not app.guest_book.result.found
            and type(app.guest_book.result.err) == "string")
    click(640, 602) -- back to the hall
    check("hub after kept book", app.screen == "hub")

    -- A later hand overwrites the sealed draft: the book refuses
    -- honestly, and nothing crashes.
    app.state.drafts["d1boss-act2"] = "this is not lua at all (("
    app:persist()
    click(1098, 543)
    check("guestbook broken draft refused",
        app.screen == "guestbook" and app.guest_book.state == "broken")
    click(640, 602)
    app.state.drafts["d1boss-act2"] = F.boss_act2.solution
    app:persist()

    -- The chronicle survives a restart, in the same single file.
    local saved = platform.read_save()
    check("save exists", type(saved) == "string")
    local parsed = saved and Save.parse(saved)
    check("save parses after play", parsed ~= nil
        and parsed.boss_done == true
        and parsed.sealed.d1l1 and parsed.sealed.d1l2
        and parsed.sealed.d1l3)
    local app2 = App.new(platform)
    check("restart lands on title", app2.screen == "title")
    app2:render()
    click = function(x, y)
        app2:event({ type = "click", x = x, y = y })
        app2:render()
        app2:update(16)
    end
    click(640, 694) -- Continue the Journey — no arrival twice
    check("restart continues at hub", app2.screen == "hub")

    -- Reduced motion is a first-class choice, persisted.
    local platform2 = Mock.new()
    local app3 = App.new(platform2)
    app3:render()
    app3:event({ type = "click", x = 780, y = 493 }) -- Motion: reduced
    app3:render()
    check("reduced chosen", app3.state.settings.motion == "reduced")
    local saved2 = Save.parse(platform2.read_save() or "")
    check("reduced persisted",
        saved2 ~= nil and saved2.settings ~= nil
            and saved2.settings.motion == "reduced")

    -- The transcript is the app's own log lines plus this script's.
    for _, line in ipairs(app.transcript) do emit(line) end
    emit("SELFTEST failures " .. failures)
    return table.concat(out, "\n") .. "\n", failures
end

return Selftest
