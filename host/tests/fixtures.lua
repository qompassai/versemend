-- Gate fixtures: for every level a reference solution (must pass),
-- a plausible wrong program (must fail, at a named test), and hostile
-- programs (must be refused by budget or leak audit). Half the suite
-- is validation; half is adversarial — here as in the game.
local F = {}

F.d1l1 = {
    solution = [=[
function census(entries)
    local counts = {}
    for i = 1, #entries do
        local kind = type(entries[i].value)
        counts[kind] = (counts[kind] or 0) + 1
    end
    local kinds = {}
    for kind in pairs(counts) do
        kinds[#kinds + 1] = kind
    end
    table.sort(kinds)
    local lines = {}
    for i = 1, #kinds do
        lines[#lines + 1] = kinds[i] .. " " .. counts[kinds[i]]
    end
    return table.concat(lines, "\n")
end
]=],
    -- Wrong: skips absent values entirely — the empty place uncounted.
    wrong = [=[
function census(entries)
    local counts = {}
    for i = 1, #entries do
        if entries[i].value ~= nil then
            local kind = type(entries[i].value)
            counts[kind] = (counts[kind] or 0) + 1
        end
    end
    local kinds = {}
    for kind in pairs(counts) do
        kinds[#kinds + 1] = kind
    end
    table.sort(kinds)
    local lines = {}
    for i = 1, #kinds do
        lines[#lines + 1] = kinds[i] .. " " .. counts[kinds[i]]
    end
    return table.concat(lines, "\n")
end
]=],
    wrong_first_fail = "a1",
}

F.d1l2 = {
    solution = [=[
function admit(guest, options)
    if options.enabled == false then return "refuse" end
    if not guest.member then return "refuse" end
    if options.places == 0 then return "refuse" end
    return "admit"
end

function fee(options)
    if options.fee == nil then return 2 end
    if options.fee == false then return 0 end
    return options.fee
end
]=],
    -- Wrong: repaired the standing test, kept the clobbering `or`.
    wrong = [=[
function admit(guest, options)
    local enabled = options.enabled or true
    if enabled == false then return "refuse" end
    if not guest.member then return "refuse" end
    if options.places == 0 then return "refuse" end
    return "admit"
end

function fee(options)
    return options.fee or 2
end
]=],
    wrong_first_fail = "v3",
}

F.d1l3 = {
    solution = [=[
assay = {}

function assay.halve(n, d)
    return n // d
end

function assay.share(n, d)
    return n / d
end

function assay.rest(n, d)
    return n % d
end

function assay.nature(v)
    return math.type(v) or type(v)
end

function assay.weigh(v)
    return tostring(v)
end

function assay.same(a, b)
    return a == b
end
]=],
    -- Wrong: one division for both questions.
    wrong = [=[
assay = {}

function assay.halve(n, d)
    return n // d
end

function assay.share(n, d)
    return n // d
end

function assay.rest(n, d)
    return n % d
end

function assay.nature(v)
    return math.type(v) or type(v)
end

function assay.weigh(v)
    return tostring(v)
end

function assay.same(a, b)
    return a == b
end
]=],
    wrong_first_fail = "v2",
}

F.boss_act1 = {
    solution = [=[
function serve(ledger, name)
    local guest = ledger:lookup(name)
    if guest == nil then
        return "the empty place"
    end
    return "seat " .. guest.seat
end
]=],
}

F.boss_act2 = {
    solution = [=[
Ledger = {}

function Ledger.new()
    local guests = {}
    local registry = {}

    function registry:register(name, attrs)
        if type(name) ~= "string" or name == "" then
            return nil, "a guest needs a name"
        end
        if type(attrs) ~= "table" then
            return nil, "a guest needs a record"
        end
        if guests[name] ~= nil then
            return nil, "already in the ledger"
        end
        guests[name] = attrs
        return true
    end

    function registry:lookup(name)
        local g = guests[name]
        if g == nil then
            return nil, "no guest by that name"
        end
        return g
    end

    function registry:update(name, attrs)
        local g = guests[name]
        if g == nil then
            return nil, "no guest by that name"
        end
        for k, v in pairs(attrs) do
            g[k] = v
        end
        return true
    end

    function registry:remove(name)
        if guests[name] == nil then
            return nil, "no guest by that name"
        end
        guests[name] = nil
        return true
    end

    function registry:census()
        local names = {}
        for name in pairs(guests) do
            names[#names + 1] = name
        end
        table.sort(names)
        return table.concat(names, "\n")
    end

    return registry
end
]=],
    -- Wrong: lookup raises on absence instead of answering nil, err.
    wrong = [=[
Ledger = {}

function Ledger.new()
    local guests = {}
    local registry = {}

    function registry:register(name, attrs)
        guests[name] = attrs
        return true
    end

    function registry:lookup(name)
        local g = guests[name]
        if g == nil then
            error("no such guest")
        end
        return g
    end

    function registry:update(name, attrs)
        local g = guests[name]
        for k, v in pairs(attrs) do
            g[k] = v
        end
        return true
    end

    function registry:remove(name)
        guests[name] = nil
        return true
    end

    function registry:census()
        local names = {}
        for name in pairs(guests) do
            names[#names + 1] = name
        end
        table.sort(names)
        return table.concat(names, "\n")
    end

    return registry
end
]=],
    wrong_first_fail = "a1",
}

F.hostile = {
    runaway = [=[
function census(entries)
    while true do
    end
end
]=],
    coroutine_runaway = [=[
function census(entries)
    local co = coroutine.create(function()
        while true do
        end
    end)
    coroutine.resume(co)
    return ""
end
]=],
    leaker = [=[
total = 0
function census(entries)
    return ""
end
]=],
    missing = [=[
local something = 1
]=],
}

return F
