-- BOSS of Domain 2 — The Borderless Inn.
-- Act 1 is a diagnosis: the inn's night clerk counts the house by
-- the wing's border — a guest gone from room 2 shrinks the house on
-- paper while room 3 still sleeps. The count is a lie the border
-- tells; the seam is the count itself.
-- Act 2 is the build: the Innkeeper's Keys, a room-allocation
-- library whose occupancy count is kept by the library itself,
-- gated on the full suite — half validation, half adversarial.
local Boss2 = {
    id = "d2boss",
    domain = 2,
    title = "The Borderless Inn",
    master = "The Registrar",
    brief = {
        "At the parish edge stands an inn whose rooms are numbered",
        "from the door, and whose night clerk counts the house by",
        "its border: the last room he can see standing. A guest",
        "gone from room 2 makes the house smaller on paper, though",
        "room 3 still sleeps, and pays, and snores.",
        "",
        "First, walk the clerk's evening round and find where the",
        "count goes wrong. Then take the Innkeeper's Keys and",
        "keep the house yourself: rooms let and freed, the house",
        "compacted, and a count that is kept — never measured",
        "off the border, never read from the last full room.",
    },
    demo = {
        {
            title = "The house that shrinks on paper",
            lines = {
                "Room 2 stands empty tonight. The clerk's border",
                "says the house ends at room 1 — one guest. Cy,",
                "asleep in room 3, disagrees, and Cy is right.",
                "The border counts standing rooms only when they",
                "stand in a row; a gap makes it a liar.",
            },
            boxes = {
                { text = "room 1: Ada", sub = "standing" },
                { text = "room 2: —", sub = "gone" },
                { text = "room 3: Cy", sub = "standing" },
            },
        },
        {
            title = "Keys that keep the count",
            lines = {
                "The new book keeps the count itself, in its own",
                "hand, changed only when a room is let or freed.",
                "Reports walk the rooms in ascending order — the",
                "canonical walk — and callers are handed copies,",
                "never the book's own pages.",
            },
            boxes = {
                { text = "kept: 2", sub = "the count, owned" },
                { text = "room 3: Cy", sub = "still standing" },
            },
        },
    },
    loot = "The Innkeeper's Keys",
    codex = {
        title = "Keep the count yourself",
        lines = {
            "A length you depend on is state you own. It works",
            "because an explicit count is a contract; a border",
            "is weather.",
        },
    },
    acts = {
        {
            id = "d2boss-act1",
            title = "The Clerk's Round",
            contract = "round(rooms) -> \"occupied <n>\"\n"
                .. "  rooms is the wing as the clerk presents it: guest\n"
                .. "  names, one per room, where a room standing empty\n"
                .. "  is simply not there — the array may have holes.\n"
                .. "  n is the number of guests standing in the wing.\n"
                .. "evening(rooms) -> string\n"
                .. "  The evening report, canonical: one line\n"
                .. "  \"room <i>: <name>\" per standing guest, rooms\n"
                .. "  ascending, then the line \"occupied <n>\". An\n"
                .. "  empty wing reports \"occupied 0\".",
            starter = [=[
-- The Clerk's Round (Boss of Domain 2, first act) — repair
-- Contract: round(rooms) -> "occupied <n>"
--           evening(rooms) -> the canonical evening report
--   The wing may have holes: an empty room is not there.
function round(rooms)
    -- the seam is here: the clerk counts the house by its
    -- border — #rooms is weather, and a holed wing lies
    return "occupied " .. #rooms
end

function evening(rooms)
    local lines = {}
    for i = 1, #rooms do
        if rooms[i] ~= nil then
            lines[#lines + 1] = "room " .. i .. ": " .. tostring(rooms[i])
        end
    end
    lines[#lines + 1] = round(rooms)
    return table.concat(lines, "\n")
end
]=],
            provides = { "round", "evening" },
            tests = {
                { id = "v1", kind = "validation",
                  say = "A full wing, three guests in a row: the round and the report agree at three.",
                  run = function(env)
                      local rooms = { "Ada", "Bo", "Cy" }
                      return env.round(rooms) == "occupied 3"
                          and env.evening(rooms)
                              == "room 1: Ada\nroom 2: Bo\nroom 3: Cy\noccupied 3"
                  end },
                { id = "v2", kind = "validation",
                  say = "An empty wing reports occupied 0 — no room lines, no complaint.",
                  run = function(env)
                      local rooms = {}
                      return env.round(rooms) == "occupied 0"
                          and env.evening(rooms) == "occupied 0"
                  end },
                { id = "a1", kind = "adversarial",
                  say = "Room 2 stands empty and room 3 still sleeps: the count is two. The border says otherwise — it is the seam.",
                  run = function(env)
                      local rooms = { "Ada", "Bo", "Cy" }
                      rooms[2] = nil
                      return env.round(rooms) == "occupied 2"
                          and env.evening(rooms)
                              == "room 1: Ada\nroom 3: Cy\noccupied 2"
                  end },
                { id = "a2", kind = "adversarial",
                  say = "The wing begins with an empty room: two guests stand, at rooms 2 and 3, and the count is two.",
                  run = function(env)
                      local rooms = {}
                      rooms[2] = "Bo"
                      rooms[3] = "Cy"
                      return env.round(rooms) == "occupied 2"
                          and env.evening(rooms)
                              == "room 2: Bo\nroom 3: Cy\noccupied 2"
                  end },
            },
            hints = {
                "Count the standing guests by walking the wing and tallying every room that holds a name — pairs walks holes without ending at them.",
                "The report walks rooms in ascending order: find the highest room the wing holds, then walk 1 to there, speaking only for rooms that stand occupied.",
                "round tallies with pairs; evening walks places in order and finishes with round's own line. Neither asks the wing for its border, ever.",
            },
        },
        {
            id = "d2boss-act2",
            title = "The Innkeeper's Keys",
            contract = "Inn — the room-allocation library.\n"
                .. "  Inn.new(capacity) -> inn | nil, err\n"
                .. "    capacity is a whole number of rooms, at least 1.\n"
                .. "  Inn.adopt(capacity, plan) -> inn | nil, err\n"
                .. "    Takes over a house as its plan presents it: a\n"
                .. "    table from room numbers to guest names, which\n"
                .. "    may have holes. The plan is copied at ingest —\n"
                .. "    the inn keeps no part of the caller's table.\n"
                .. "    A plan seating one guest twice, or naming a\n"
                .. "    room the inn does not have, is refused.\n"
                .. "  inn:allocate(guest) -> room | nil, err\n"
                .. "    The lowest free room. A guest with no name, a\n"
                .. "    guest already keeping a room, and a full house\n"
                .. "    are answered nil, err.\n"
                .. "  inn:release(room) -> true | nil, err\n"
                .. "    A room standing empty, never let, or beyond\n"
                .. "    the house is answered nil, err.\n"
                .. "  inn:compact() -> true\n"
                .. "    The standing guests slide to rooms 1..count,\n"
                .. "    keeping their room order.\n"
                .. "  inn:count() -> the house's own count, kept by the\n"
                .. "    library at every letting and freeing.\n"
                .. "  inn:room_of(guest) -> room | nil, err\n"
                .. "  inn:report() -> string\n"
                .. "    One line \"room <i>: <name>\" per standing guest,\n"
                .. "    rooms ascending, then \"occupied <n> of\n"
                .. "    <capacity>\". An empty house reports the\n"
                .. "    summary line alone.\n"
                .. "  inn:plan() -> table\n"
                .. "    A copy of the house as a plan. What a caller\n"
                .. "    does to the copy is the caller's business; the\n"
                .. "    inn does not care, and must not.",
            starter = [=[
-- The Innkeeper's Keys (Boss of Domain 2, second act)
-- Contract:
--   Inn.new(capacity)          -> inn | nil, err
--   Inn.adopt(capacity, plan)  -> inn | nil, err
--   inn:allocate(guest)        -> room | nil, err
--   inn:release(room)          -> true | nil, err
--   inn:compact()              -> true
--   inn:count()                -> the house's own count
--   inn:room_of(guest)         -> room | nil, err
--   inn:report()               -> the canonical report
--   inn:plan()                 -> a copy of the house
-- A discourtesy is answered nil, err — never a raised error,
-- never a silent invention. The count is kept by the library.
Inn = {}

function Inn.new(capacity)
    if type(capacity) ~= "number" or capacity % 1 ~= 0 or capacity < 1 then
        return nil, "an inn needs a whole number of rooms, at least one"
    end
    local inn = {}
    -- the seam is here: the shell keeps nothing — no rooms, no
    -- count. A house is state, and state is kept, not implied.
    function inn:count()
        return 0
    end
    return inn
end
]=],
            provides = { "Inn" },
            tests = {
                { id = "v1", kind = "validation",
                  say = "Rooms are let from the door: Ada 1, Wren 2, Cy 3, and the report walks them in order.",
                  run = function(env)
                      local inn = env.Inn.new(3)
                      if inn == nil then return false end
                      local r1 = inn:allocate("Ada")
                      local r2 = inn:allocate("Wren")
                      local r3 = inn:allocate("Cy")
                      return r1 == 1 and r2 == 2 and r3 == 3
                          and inn:count() == 3
                          and inn:room_of("Wren") == 2
                          and inn:report()
                              == "room 1: Ada\nroom 2: Wren\nroom 3: Cy\noccupied 3 of 3"
                  end },
                { id = "v2", kind = "validation",
                  say = "A freed room is let again: the count falls to two, then the lowest free room is the next room given.",
                  run = function(env)
                      local inn = env.Inn.new(3)
                      inn:allocate("Ada"); inn:allocate("Wren"); inn:allocate("Cy")
                      local freed = inn:release(2)
                      local kept = inn:count()
                      local room = inn:allocate("Di")
                      return freed == true and kept == 2 and inn:count() == 3 and room == 2
                          and inn:report()
                              == "room 1: Ada\nroom 2: Di\nroom 3: Cy\noccupied 3 of 3"
                  end },
                { id = "v3", kind = "validation",
                  say = "Compaction slides the standing guests to the door, keeping their order: Bo, then Di.",
                  run = function(env)
                      local inn = env.Inn.new(5)
                      inn:allocate("Ada"); inn:allocate("Bo")
                      inn:allocate("Cy"); inn:allocate("Di")
                      inn:release(1); inn:release(3)
                      local ok = inn:compact()
                      return ok == true and inn:count() == 2
                          and inn:room_of("Bo") == 1 and inn:room_of("Di") == 2
                          and inn:report()
                              == "room 1: Bo\nroom 2: Di\noccupied 2 of 5"
                  end },
                { id = "v4", kind = "validation",
                  say = "The inn diverged from its naive model somewhere in the script. Keep the count at every letting and freeing.",
                  run = function(env)
                      local inn = env.Inn.new(6)
                      if inn == nil then return false end
                      local m_rooms, m_where, m_count = {}, {}, 0
                      local pool = { "Ada", "Wren", "Cy", "Bo", "Di", "Eli", "Fay", "Gil" }
                      local s = 20261110
                      local function rnd(n)
                          s = (s * 1103515245 + 12345) % 2147483648
                          return s % n + 1
                      end
                      local function m_report()
                          local lines = {}
                          for i = 1, 6 do
                              if m_rooms[i] ~= nil then
                                  lines[#lines + 1] = "room " .. i .. ": " .. m_rooms[i]
                              end
                          end
                          lines[#lines + 1] = "occupied " .. m_count .. " of 6"
                          return table.concat(lines, "\n")
                      end
                      for step = 1, 120 do
                          local op = rnd(4)
                          if op <= 2 then
                              local guest = pool[rnd(#pool)]
                              local room, err = inn:allocate(guest)
                              if m_where[guest] ~= nil or m_count >= 6 then
                                  if room ~= nil or type(err) ~= "string" then return false end
                              else
                                  local want = 1
                                  while m_rooms[want] ~= nil do want = want + 1 end
                                  if room ~= want then return false end
                                  m_rooms[want] = guest
                                  m_where[guest] = want
                                  m_count = m_count + 1
                              end
                          elseif op == 3 then
                              local room = rnd(6)
                              local ok, err = inn:release(room)
                              if m_rooms[room] ~= nil then
                                  if ok ~= true then return false end
                                  m_where[m_rooms[room]] = nil
                                  m_rooms[room] = nil
                                  m_count = m_count - 1
                              else
                                  if ok ~= nil or type(err) ~= "string" then return false end
                              end
                          else
                              local ok = inn:compact()
                              if ok ~= true then return false end
                              local standing = {}
                              for i = 1, 6 do
                                  if m_rooms[i] ~= nil then
                                      standing[#standing + 1] = m_rooms[i]
                                  end
                              end
                              m_rooms, m_where = {}, {}
                              for i, guest in ipairs(standing) do
                                  m_rooms[i] = guest
                                  m_where[guest] = i
                              end
                          end
                          if inn:count() ~= m_count or inn:report() ~= m_report() then
                              return false
                          end
                      end
                      return true
                  end },
                { id = "a1", kind = "adversarial",
                  say = "The adopted house keeps its shape: Cy stands at room 3 across the hole, and the next letting takes room 2.",
                  run = function(env)
                      local plan = { [1] = "Ada", [3] = "Cy" }
                      local inn = env.Inn.adopt(4, plan)
                      if inn == nil then return false end
                      local room = inn:allocate("Bo")
                      return inn:count() == 3 and room == 2
                          and inn:room_of("Cy") == 3 and inn:room_of("Ada") == 1
                          and inn:report()
                              == "room 1: Ada\nroom 2: Bo\nroom 3: Cy\noccupied 3 of 4"
                  end },
                { id = "a2", kind = "adversarial",
                  say = "A room freed twice, a room never let, a room beyond the house: each is answered, and the count does not move.",
                  run = function(env)
                      local inn = env.Inn.new(3)
                      inn:allocate("Ada")
                      local first = inn:release(1)
                      local again, e1 = inn:release(1)
                      local never, e2 = inn:release(2)
                      local beyond, e3 = inn:release(99)
                      return first == true
                          and again == nil and type(e1) == "string"
                          and never == nil and type(e2) == "string"
                          and beyond == nil and type(e3) == "string"
                          and inn:count() == 0
                  end },
                { id = "a3", kind = "adversarial",
                  say = "The caller's tables are the caller's: scribble on the plan, scribble on the copy — the inn's report does not change.",
                  run = function(env)
                      local plan = { [1] = "Ada", [3] = "Cy" }
                      local inn = env.Inn.adopt(4, plan)
                      if inn == nil then return false end
                      plan[1] = "Mallory"
                      plan[3] = nil
                      plan[2] = "Bo"
                      local copy = inn:plan()
                      copy[1] = "Mallory"
                      copy[3] = nil
                      return inn:count() == 2
                          and inn:report()
                              == "room 1: Ada\nroom 3: Cy\noccupied 2 of 4"
                  end },
                { id = "a4", kind = "adversarial",
                  say = "Discourtesies are answered, not obeyed: no name, the same name twice, a full house, a house of no rooms.",
                  run = function(env)
                      local nohouse, e0 = env.Inn.new(0)
                      local half, e1 = env.Inn.new(2.5)
                      local inn = env.Inn.new(1)
                      local noname, e2 = inn:allocate("")
                      local absent, e3 = inn:allocate(nil)
                      inn:allocate("Ada")
                      local dup, e4 = inn:allocate("Ada")
                      local full, e5 = inn:allocate("Bo")
                      local twice, e6 = env.Inn.adopt(3, { [1] = "Ada", [2] = "Ada" })
                      return nohouse == nil and type(e0) == "string"
                          and half == nil and type(e1) == "string"
                          and noname == nil and type(e2) == "string"
                          and absent == nil and type(e3) == "string"
                          and dup == nil and type(e4) == "string"
                          and full == nil and type(e5) == "string"
                          and twice == nil and type(e6) == "string"
                          and inn:count() == 1
                  end },
            },
            hints = {
                "Keep the house in three parts: the rooms, a name-to-room index, and the count — the count written only where a room is let or freed.",
                "adopt walks the caller's plan once and copies the standing guests into the inn's own rooms; the plan table itself is never kept, so later scribbles cannot reach the house.",
                "report is the canonical walk: places ascending, one line per standing guest, then the summary with the kept count. plan() builds a fresh table every call.",
            },
        },
    },
}

return Boss2
