-- Versemend spike LuaJIT-strand gate harness (shared verbatim).
-- Runs on LuaJIT (Lua 5.1 semantics + the bit library), for the strand that
-- teaches the editor-host dialect. The player gets a whitelist environment
-- PLUS a small `vim` stub — the strand's host surface in miniature.
-- Contract mirrors gate.lua: run_gate(source) -> canonical record string.
local STEP_MAX = 200000
local HOOK_EVERY = 1000
local bit = require("bit")

local BASE_NAMES = {
    "assert", "error", "ipairs", "next", "pairs", "pcall", "select",
    "tonumber", "tostring", "type",
}

local function make_vim()
    local vim = {}
    function vim.trim(s)
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
    end
    function vim.startswith(s, prefix)
        return s:sub(1, #prefix) == prefix
    end
    function vim.split(s, sep)
        local parts, pos = {}, 1
        while true do
            local i = s:find(sep, pos, true)
            if not i then
                parts[#parts + 1] = s:sub(pos)
                return parts
            end
            parts[#parts + 1] = s:sub(pos, i - 1)
            pos = i + #sep
        end
    end
    return vim
end

local function make_env()
    local env = {}
    for _, k in ipairs(BASE_NAMES) do env[k] = _G[k] end
    for _, k in ipairs({ "string", "table", "math" }) do
        local lib = {}
        for lk, lv in pairs(_G[k]) do lib[lk] = lv end
        env[k] = lib
    end
    env.vim = make_vim()
    return env
end

local function sorted_keys(t)
    local ks = {}
    for k in pairs(t) do ks[#ks + 1] = k end
    table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
    return ks
end

-- djb2 with per-step 32-bit banding: exact in LuaJIT's double arithmetic.
local function djb2(s)
    local h = 5381
    for i = 1, #s do
        h = bit.band(h * 33 + s:byte(i), 0xFFFFFFFF)
    end
    return bit.tohex(h)
end

local TESTS = {
    { id = "v1", run = function(slug) return slug(" Hello World ") == "hello-world" end },
    { id = "v2", run = function(slug) return slug("Lua") == "lua" end },
    { id = "v3", run = function(slug) return slug("") == "" end },
    { id = "a1", run = function(slug) return slug("a b  c") == "a-b--c" end },
    { id = "a2", run = function(slug) return slug("  Trim Me  ") == "trim-me" end },
}

local function run_gate(source)
    -- Strand law (spike-proven): LuaJIT's trace compiler stops delivering
    -- count hooks inside a hot empty loop, so a budget hook alone cannot
    -- bound JIT-compiled player code — the first run of this harness hung
    -- on exactly that. Strand gates therefore run INTERPRETED (jit.off for
    -- the gate's duration): determinism and budget before speed.
    if jit then jit.off() end
    local lines = {}
    local function emit(s) lines[#lines + 1] = s end
    emit("VERSEMMEND-GATE-JIT 1")
    emit("runtime " .. _VERSION .. " (LuaJIT strand)")
    local budget_blown = false
    local count = 0
    local function hook()
        count = count + HOOK_EVERY
        if count > STEP_MAX then error("STEP_BUDGET_EXCEEDED", 0) end
    end
    local env = make_env()
    local before = {}
    for _, k in ipairs(sorted_keys(env)) do before[k] = true end
    local chunk, cerr = loadstring(source, "player")
    if not chunk then
        emit("load FAIL " .. tostring(cerr):gsub("\n", " "))
        emit("verdict FAIL")
        return table.concat(lines, "\n") .. "\n"
    end
    setfenv(chunk, env)
    count = 0
    debug.sethook(hook, "", HOOK_EVERY)
    local ok, lerr = pcall(chunk)
    debug.sethook()
    if not ok then
        if lerr == "STEP_BUDGET_EXCEEDED" then budget_blown = true end
        emit("load FAIL " .. tostring(lerr):gsub("\n", " "))
        emit("budget " .. (budget_blown and "FAIL" or "PASS"))
        emit("verdict FAIL")
        if jit then jit.on() end
        return table.concat(lines, "\n") .. "\n"
    end
    emit("load PASS")
    local leaked = {}
    for _, k in ipairs(sorted_keys(env)) do
        if not before[k] and k ~= "slug" then leaked[#leaked + 1] = tostring(k) end
    end
    if #leaked > 0 then
        emit("leak FAIL " .. table.concat(leaked, ","))
    else
        emit("leak PASS")
    end
    local all_pass = #leaked == 0
    if type(env.slug) ~= "function" then
        emit("tests FAIL slug-missing")
        all_pass = false
    else
        for _, t in ipairs(TESTS) do
            count = 0
            debug.sethook(hook, "", HOOK_EVERY)
            local tok, terr = pcall(t.run, env.slug)
            debug.sethook()
            if terr == "STEP_BUDGET_EXCEEDED" then budget_blown = true end
            if tok and terr == true then
                emit("test " .. t.id .. " PASS")
            else
                emit("test " .. t.id .. " FAIL")
                all_pass = false
            end
        end
    end
    emit("budget " .. (budget_blown and "FAIL" or "PASS"))
    if budget_blown then all_pass = false end
    emit("verdict " .. (all_pass and "PASS" or "FAIL"))
    if jit then jit.on() end
    return table.concat(lines, "\n") .. "\n"
end

return { run_gate = run_gate, checksum = djb2, STEP_MAX = STEP_MAX }
