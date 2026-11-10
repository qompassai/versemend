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

F.d2l1 = {
    solution = [=[
function house(kind)
    if kind == "sequence" then
        return { "Ada", "Bo", "Cy" }
    elseif kind == "record" then
        return { name = "The Registrar", office = "The Roll Room", lamps = 3 }
    elseif kind == "mixture" then
        return { "Ada", "Cy", name = "Bo", watch = 2 }
    end
    return nil, "the house knows no such kind: " .. tostring(kind)
end

function shape(t)
    local a, r = 0, 0
    for k in pairs(t) do
        if type(k) == "number" and k % 1 == 0 and k >= 1 then
            a = a + 1
        else
            r = r + 1
        end
    end
    return a .. " array, " .. r .. " record"
end
]=],
    wrong = [=[
function house(kind)
    if kind == "sequence" then
        return { "Ada", "Bo", "Cy" }
    elseif kind == "record" then
        return { name = "The Registrar", office = "The Roll Room", lamps = 3 }
    elseif kind == "mixture" then
        return { "Ada", "Bo", "Cy", watch = 2 }
    end
    return nil, "the house knows no such kind: " .. tostring(kind)
end

function shape(t)
    local a, r = 0, 0
    for k in pairs(t) do
        if type(k) == "number" and k % 1 == 0 and k >= 1 then
            a = a + 1
        else
            r = r + 1
        end
    end
    return a .. " array, " .. r .. " record"
end
]=],
    wrong_first_fail = "v3",
}

F.d2l2 = {
    solution = [=[
Roll = {}

function Roll.new()
    local items = {}
    local span = 0
    local roll = { kept = 0 }

    function roll:push(value)
        if value == nil then
            return nil, "a plank of nothing is refused"
        end
        span = span + 1
        items[span] = value
        roll.kept = roll.kept + 1
        return true
    end

    function roll:remove_at(place)
        if type(place) ~= "number" or place % 1 ~= 0 or place < 1 or place > span then
            return nil, "no such place on the bridge"
        end
        local value = items[place]
        if value == nil then
            return nil, "no plank stands at that place"
        end
        items[place] = nil
        roll.kept = roll.kept - 1
        return value
    end

    function roll:get(place)
        if type(place) ~= "number" or place % 1 ~= 0 or place < 1 or place > span then
            return nil, "no such place on the bridge"
        end
        local value = items[place]
        if value == nil then
            return nil, "no plank stands at that place"
        end
        return value
    end

    function roll:count()
        return roll.kept
    end

    function roll:span()
        return span
    end

    function roll:walk()
        local lines = {}
        for i = 1, span do
            lines[#lines + 1] = i .. ": "
                .. (items[i] ~= nil and tostring(items[i]) or "—")
        end
        return table.concat(lines, "\n")
    end

    return roll
end
]=],
    wrong = [=[
Roll = {}

function Roll.new()
    local items = {}
    local roll = { kept = 0 }

    function roll:push(value)
        if value == nil then
            return nil, "a plank of nothing is refused"
        end
        items[#items + 1] = value
        roll.kept = #items
        return true
    end

    function roll:remove_at(place)
        local value = items[place]
        if value == nil then
            return nil, "no plank stands at that place"
        end
        items[place] = nil
        roll.kept = #items
        return value
    end

    function roll:get(place)
        local value = items[place]
        if value == nil then
            return nil, "no plank stands at that place"
        end
        return value
    end

    function roll:count()
        return #items
    end

    function roll:span()
        return #items
    end

    function roll:walk()
        local lines = {}
        for i = 1, #items do
            lines[#lines + 1] = i .. ": "
                .. (items[i] ~= nil and tostring(items[i]) or "—")
        end
        return table.concat(lines, "\n")
    end

    return roll
end
]=],
    wrong_first_fail = "v2",
}

F.d2l3 = {
    solution = [=[
walks = {}

local function render(list)
    return table.concat(list, "\n")
end

function walks.by_pairs(t)
    local out = {}
    for k, v in pairs(t) do
        out[#out + 1] = tostring(k) .. "=" .. tostring(v)
    end
    return render(out)
end

function walks.by_ipairs(t)
    local out = {}
    for _, v in ipairs(t) do
        out[#out + 1] = tostring(v)
    end
    return render(out)
end

function walks.by_next(t)
    local out = {}
    local k, v = next(t)
    while k ~= nil do
        out[#out + 1] = tostring(k) .. "=" .. tostring(v)
        k, v = next(t, k)
    end
    return render(out)
end

function walks.canonical(t)
    local ints, strs = {}, {}
    for k in pairs(t) do
        if type(k) == "number" then
            ints[#ints + 1] = k
        else
            strs[#strs + 1] = k
        end
    end
    table.sort(ints)
    table.sort(strs)
    local out = {}
    for _, k in ipairs(ints) do
        out[#out + 1] = tostring(k) .. "=" .. tostring(t[k])
    end
    for _, k in ipairs(strs) do
        out[#out + 1] = tostring(k) .. "=" .. tostring(t[k])
    end
    return render(out)
end
]=],
    wrong = [=[
walks = {}

local function render(list)
    return table.concat(list, "\n")
end

function walks.by_pairs(t)
    local out = {}
    for k, v in pairs(t) do
        out[#out + 1] = tostring(k) .. "=" .. tostring(v)
    end
    return render(out)
end

function walks.by_ipairs(t)
    local out = {}
    for _, v in ipairs(t) do
        out[#out + 1] = tostring(v)
    end
    return render(out)
end

function walks.by_next(t)
    local out = {}
    local k, v = next(t)
    while k ~= nil do
        out[#out + 1] = tostring(k) .. "=" .. tostring(v)
        k, v = next(t, k)
    end
    return render(out)
end

function walks.canonical(t)
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local out = {}
    for _, k in ipairs(keys) do
        out[#out + 1] = tostring(k) .. "=" .. tostring(t[k])
    end
    return render(out)
end
]=],
    wrong_first_fail = "v1",
}

F.boss2_act1 = {
    solution = [=[
local function standing(rooms)
    local n = 0
    for _ in pairs(rooms) do
        n = n + 1
    end
    return n
end

function round(rooms)
    return "occupied " .. standing(rooms)
end

function evening(rooms)
    local top = 0
    for k in pairs(rooms) do
        if type(k) == "number" and k > top then
            top = k
        end
    end
    local lines = {}
    for i = 1, top do
        if rooms[i] ~= nil then
            lines[#lines + 1] = "room " .. i .. ": " .. tostring(rooms[i])
        end
    end
    lines[#lines + 1] = "occupied " .. standing(rooms)
    return table.concat(lines, "\n")
end
]=],
}

F.boss2_act2 = {
    solution = [=[
Inn = {}

local function whole_rooms(capacity)
    return type(capacity) == "number" and capacity % 1 == 0 and capacity >= 1
end

local function make_inn(capacity)
    local rooms = {}
    local where = {}
    local count = 0
    local inn = {}

    local function put(place, guest)
        rooms[place] = guest
        where[guest] = place
        count = count + 1
    end

    function inn:allocate(guest)
        if type(guest) ~= "string" or guest == "" then
            return nil, "a guest needs a name"
        end
        if where[guest] ~= nil then
            return nil, guest .. " already keeps a room"
        end
        if count >= capacity then
            return nil, "the inn is full"
        end
        for place = 1, capacity do
            if rooms[place] == nil then
                put(place, guest)
                return place
            end
        end
        return nil, "the inn is full"
    end

    function inn:release(place)
        if type(place) ~= "number" or place % 1 ~= 0
            or place < 1 or place > capacity then
            return nil, "the inn has no such room"
        end
        local guest = rooms[place]
        if guest == nil then
            return nil, "that room stands empty"
        end
        rooms[place] = nil
        where[guest] = nil
        count = count - 1
        return true
    end

    function inn:compact()
        local standing = {}
        for place = 1, capacity do
            if rooms[place] ~= nil then
                standing[#standing + 1] = rooms[place]
            end
        end
        rooms = {}
        where = {}
        count = 0
        for place, guest in ipairs(standing) do
            put(place, guest)
        end
        return true
    end

    function inn:count()
        return count
    end

    function inn:room_of(guest)
        local place = where[guest]
        if place == nil then
            return nil, "no guest by that name keeps a room"
        end
        return place
    end

    function inn:report()
        local lines = {}
        for place = 1, capacity do
            if rooms[place] ~= nil then
                lines[#lines + 1] = "room " .. place .. ": " .. rooms[place]
            end
        end
        lines[#lines + 1] = "occupied " .. count .. " of " .. capacity
        return table.concat(lines, "\n")
    end

    function inn:plan()
        local out = {}
        for place = 1, capacity do
            if rooms[place] ~= nil then
                out[place] = rooms[place]
            end
        end
        return out
    end

    return inn, put
end

function Inn.new(capacity)
    if not whole_rooms(capacity) then
        return nil, "an inn needs a whole number of rooms, at least one"
    end
    local inn = make_inn(capacity)
    return inn
end

function Inn.adopt(capacity, plan)
    if not whole_rooms(capacity) then
        return nil, "an inn needs a whole number of rooms, at least one"
    end
    if type(plan) ~= "table" then
        return nil, "a plan is a table of rooms"
    end
    local seen = {}
    for place, guest in pairs(plan) do
        if type(place) ~= "number" or place % 1 ~= 0
            or place < 1 or place > capacity then
            return nil, "the plan names a room the inn does not have"
        end
        if type(guest) ~= "string" or guest == "" then
            return nil, "the plan names a guest who is not there"
        end
        if seen[guest] then
            return nil, "the plan seats " .. guest .. " twice"
        end
        seen[guest] = true
    end
    local inn, put = make_inn(capacity)
    for place = 1, capacity do
        local guest = plan[place]
        if guest ~= nil then
            put(place, guest)
        end
    end
    return inn
end
]=],
    wrong = [=[
Inn = {}

local function whole_rooms(capacity)
    return type(capacity) == "number" and capacity % 1 == 0 and capacity >= 1
end

local function make_inn(capacity)
    local rooms = {}
    local where = {}
    local count = 0
    local inn = {}

    local function put(place, guest)
        rooms[place] = guest
        where[guest] = place
        count = count + 1
    end

    function inn:allocate(guest)
        if type(guest) ~= "string" or guest == "" then
            return nil, "a guest needs a name"
        end
        if where[guest] ~= nil then
            return nil, guest .. " already keeps a room"
        end
        if count >= capacity then
            return nil, "the inn is full"
        end
        for place = 1, capacity do
            if rooms[place] == nil then
                put(place, guest)
                return place
            end
        end
        return nil, "the inn is full"
    end

    function inn:release(place)
        if type(place) ~= "number" or place % 1 ~= 0
            or place < 1 or place > capacity then
            return nil, "the inn has no such room"
        end
        local guest = rooms[place]
        if guest == nil then
            return nil, "that room stands empty"
        end
        rooms[place] = nil
        where[guest] = nil
        count = count - 1
        return true
    end

    function inn:compact()
        local standing = {}
        for place = 1, capacity do
            if rooms[place] ~= nil then
                standing[#standing + 1] = rooms[place]
            end
        end
        rooms = {}
        where = {}
        count = 0
        for place, guest in ipairs(standing) do
            put(place, guest)
        end
        return true
    end

    function inn:count()
        return #rooms
    end

    function inn:room_of(guest)
        local place = where[guest]
        if place == nil then
            return nil, "no guest by that name keeps a room"
        end
        return place
    end

    function inn:report()
        local lines = {}
        for place = 1, capacity do
            if rooms[place] ~= nil then
                lines[#lines + 1] = "room " .. place .. ": " .. rooms[place]
            end
        end
        lines[#lines + 1] = "occupied " .. #rooms .. " of " .. capacity
        return table.concat(lines, "\n")
    end

    function inn:plan()
        local out = {}
        for place = 1, capacity do
            if rooms[place] ~= nil then
                out[place] = rooms[place]
            end
        end
        return out
    end

    return inn, put
end

function Inn.new(capacity)
    if not whole_rooms(capacity) then
        return nil, "an inn needs a whole number of rooms, at least one"
    end
    local inn = make_inn(capacity)
    return inn
end

function Inn.adopt(capacity, plan)
    if not whole_rooms(capacity) then
        return nil, "an inn needs a whole number of rooms, at least one"
    end
    if type(plan) ~= "table" then
        return nil, "a plan is a table of rooms"
    end
    local seen = {}
    for place, guest in pairs(plan) do
        if type(place) ~= "number" or place % 1 ~= 0
            or place < 1 or place > capacity then
            return nil, "the plan names a room the inn does not have"
        end
        if type(guest) ~= "string" or guest == "" then
            return nil, "the plan names a guest who is not there"
        end
        if seen[guest] then
            return nil, "the plan seats " .. guest .. " twice"
        end
        seen[guest] = true
    end
    local inn, put = make_inn(capacity)
    for place = 1, capacity do
        local guest = plan[place]
        if guest ~= nil then
            put(place, guest)
        end
    end
    return inn
end
]=],
    wrong_first_fail = "v2",
}

return F
