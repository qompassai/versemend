-- Versemend gate harness (generalized from the engine spike's proven
-- shape: whitelist environment, instruction budget by count hook,
-- global-leak audit, canonical result record).
--
-- Contract: Gate.run(level, source) -> record (string), passed (boolean)
--   level = {
--     id = "d1l1",
--     provides = { "census" },          -- names the program may proclaim
--     tests = { { id = "v1", kind = "validation",
--                 run = function(env) return <boolean> end }, ... },
--   }
-- A boss level instead carries acts = { act, act } where each act is a
-- level-shaped table with its own source field set by Gate.run_boss.
--
-- The record is deterministic: no times, no addresses, sorted key walks
-- only. Player code runs in a whitelist environment; the coroutine
-- library it receives installs the same count hook in every thread it
-- creates, so a runaway cannot escape the budget by changing threads.
local STEP_MAX = 200000
local HOOK_EVERY = 1000
local BUDGET_ERR = "STEP_BUDGET_EXCEEDED"

local BASE_NAMES = {
    "assert", "error", "ipairs", "next", "pairs", "pcall", "select",
    "tonumber", "tostring", "type", "xpcall",
}
local LIB_NAMES = { "string", "table", "math", "utf8" }

local function fnv1a(s)
    local h = 2166136261
    for i = 1, #s do
        h = h ~ s:byte(i)
        h = (h * 16777619) & 0xFFFFFFFF
    end
    return string.format("%08x", h)
end

local function sorted_keys(t)
    local ks = {}
    for k in pairs(t) do ks[#ks + 1] = k end
    table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
    return ks
end

local function normalize(msg)
    local s = tostring(msg):gsub("0x%x+", "0xADDR")
    s = s:gsub("\n", " ")
    return s
end

-- Runs one act (one source against one suite) and appends its lines.
local function run_act(act, source, emit, state)
    local count = 0
    local function hook()
        count = count + HOOK_EVERY
        if count > STEP_MAX then
            state.budget_blown = true
            error(BUDGET_ERR, 0)
        end
    end

    local env = {}
    for _, k in ipairs(BASE_NAMES) do env[k] = _G[k] end
    for _, k in ipairs(LIB_NAMES) do
        local lib = {}
        for lk, lv in pairs(_G[k]) do lib[lk] = lv end
        env[k] = lib
    end
    -- Coroutine library with the budget hook installed per thread.
    local colib = {}
    for lk, lv in pairs(coroutine) do colib[lk] = lv end
    colib.create = function(f)
        return coroutine.create(function(...)
            debug.sethook(hook, "", HOOK_EVERY)
            return f(...)
        end)
    end
    colib.wrap = function(f)
        return coroutine.wrap(function(...)
            debug.sethook(hook, "", HOOK_EVERY)
            return f(...)
        end)
    end
    env.coroutine = colib

    local before = {}
    for _, k in ipairs(sorted_keys(env)) do before[k] = true end
    local provided = {}
    for _, name in ipairs(act.provides) do provided[name] = true end

    local chunk, cerr = load(source, "player", "t", env)
    if not chunk then
        emit("load FAIL " .. normalize(cerr))
        return false
    end
    count = 0
    debug.sethook(hook, "", HOOK_EVERY)
    local ok, lerr = pcall(chunk)
    debug.sethook()
    if not ok then
        if lerr == BUDGET_ERR then state.budget_blown = true end
        emit("load FAIL " .. normalize(lerr))
        return false
    end
    emit("load PASS")

    local leaked = {}
    for _, k in ipairs(sorted_keys(env)) do
        if not before[k] and not provided[k] then
            leaked[#leaked + 1] = tostring(k)
        end
    end
    local act_pass = true
    if #leaked > 0 then
        emit("leak FAIL " .. table.concat(leaked, ","))
        act_pass = false
    else
        emit("leak PASS")
    end

    for _, name in ipairs(act.provides) do
        if env[name] == nil then
            emit("tests FAIL " .. name .. "-missing")
            act_pass = false
        end
    end
    for _, t in ipairs(act.tests) do
        count = 0
        debug.sethook(hook, "", HOOK_EVERY)
        local tok, terr = pcall(t.run, env)
        debug.sethook()
        if terr == BUDGET_ERR then state.budget_blown = true end
        if tok and terr == true then
            emit("test " .. t.id .. " PASS")
        else
            emit("test " .. t.id .. " FAIL")
            act_pass = false
        end
    end
    return act_pass
end

local function run(level, source)
    local lines = {}
    local function emit(s) lines[#lines + 1] = s end
    local state = { budget_blown = false }
    emit("VERSEMEND-GATE 1")
    emit("level " .. level.id)
    emit("runtime " .. _VERSION)
    local passed
    if level.acts then
        passed = true
        for i, act in ipairs(level.acts) do
            emit("act " .. i)
            local act_source = (type(source) == "table") and source[i] or source
            if not run_act(act, act_source, emit, state) then
                passed = false
            end
        end
    else
        passed = run_act(level, source, emit, state)
    end
    emit("budget " .. (state.budget_blown and "FAIL" or "PASS"))
    if state.budget_blown then passed = false end
    emit("verdict " .. (passed and "PASS" or "FAIL"))
    return table.concat(lines, "\n") .. "\n", passed
end

local M = { run = run, checksum = fnv1a, STEP_MAX = STEP_MAX }
return M
