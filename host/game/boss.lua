-- BOSS of Domain 1 — The Hollow Guest.
-- Act 1 is a diagnosis: the guild's attendant serves seats from the
-- old ledger and crashes on any name the ledger does not hold — the
-- nil-index surprise, latent in a program that looks finished.
-- Act 2 is the build: the Guest Ledger itself, gated on the full
-- suite — half validation, half adversarial.
local Boss = {
    id = "d1boss",
    domain = 1,
    title = "The Hollow Guest",
    brief = {
        "Every night the great table is laid for one guest more than",
        "the hall has ever seated. The register insists he dines.",
        "No one has seen him. The attendant, who serves the seats,",
        "has begun to fail — loudly, and always at the same moment:",
        "when a name is called that the old ledger does not hold.",
        "",
        "First, find the seam in the attendant's round and repair it:",
        "an absent guest is a documented absence, never a crash.",
        "Then build the guild a new Guest Ledger, one that keeps its",
        "contract under every discourtesy the road can offer.",
    },
    demo = {
        {
            title = "The place that is laid",
            lines = {
                "The table holds a place with no guest in it. The",
                "old code reads the register, reaches for the",
                "guest's seat — and the guest is not there to have",
                "one. The crash blames the serving. The fault",
                "lives at the lookup, where the absence was born.",
            },
            boxes = {
                { text = "lookup", sub = "nil, err" },
                { text = ".seat", sub = "the crash" },
            },
        },
    },
    loot = "The Guest Ledger",
    codex = {
        title = "Absence is a value; receive it",
        lines = {
            "A function that can fail to find returns the documented",
            "absence, or nil with the reason named. The check lives",
            "at the call site, once. It works because the distance",
            "between a cause and its crash is where debugging",
            "budgets go to die.",
        },
    },
    acts = {
        {
            id = "d1boss-act1",
            title = "The Attendant's Round",
            contract = "serve(ledger, name) -> string\n"
                .. "  Looks the guest up in the ledger and returns their\n"
                .. "  seat: \"seat <n>\". A guest the ledger does not hold\n"
                .. "  is not an error in the world: return \"the empty\n"
                .. "  place\" — the documented absence.",
            starter = [=[
-- The Attendant's Round (Boss of Domain 1, first act) — repair
-- Contract: serve(ledger, name) -> string
--   Looks the guest up and returns their seat: "seat <n>".
--   A guest the ledger does not hold is not an error in the
--   world: return "the empty place" — the documented absence.
function serve(ledger, name)
    local guest = ledger:lookup(name)
    return "seat " .. guest.seat
end
]=],
            provides = { "serve" },
            tests = {
                { id = "v1", kind = "validation",
                  say = "Ada sits at seat 4. The round failed on a guest who is simply there.",
                  run = function(env)
                      local led = fixture_ledger()
                      return env.serve(led, "Ada") == "seat 4"
                  end },
                { id = "v2", kind = "validation",
                  say = "Wren sits at seat 7. Serve the guest who is there.",
                  run = function(env)
                      local led = fixture_ledger()
                      return env.serve(led, "Wren") == "seat 7"
                  end },
                { id = "a1", kind = "adversarial",
                  say = "The absent guest still crashes the round. Receive the absence where it is born.",
                  run = function(env)
                      local led = fixture_ledger()
                      return env.serve(led, "Nobody") == "the empty place"
                  end },
                { id = "a2", kind = "adversarial",
                  say = "A near name is not the guest. \"Ad\" is nobody; the place is empty.",
                  run = function(env)
                      local led = fixture_ledger()
                      return env.serve(led, "Ad") == "the empty place"
                  end },
            },
            hints = {
                "The crash is reported at the serving, but the absence is born at the lookup. Read what lookup promises: a guest, or nil with a reason.",
                "Receive the lookup's answer before you touch it: if the guest is nil, the seat question has no answer — return the documented absence.",
                "if guest == nil then return \"the empty place\" end — then, and only then, ask for the seat.",
            },
        },
        {
            id = "d1boss-act2",
            title = "The Guest Ledger",
            contract = "Ledger — the registry library.\n"
                .. "  Ledger.new() -> registry\n"
                .. "  registry:register(name, attrs) -> true | nil, err\n"
                .. "    A name is a non-empty string; a guest is entered\n"
                .. "    once. A discourtesy is answered nil, err — never\n"
                .. "    a raised error, never a silent overwrite.\n"
                .. "  registry:lookup(name) -> attrs | nil, err\n"
                .. "  registry:update(name, attrs) -> true | nil, err\n"
                .. "    Merges the given attributes into the guest's.\n"
                .. "  registry:remove(name) -> true | nil, err\n"
                .. "  registry:census() -> the guests' names, sorted,\n"
                .. "    joined with \"\\n\".\n"
                .. "  The ledger is built from tables and closures: the\n"
                .. "  mirror-craft is another domain's teaching, and its\n"
                .. "  tools are not in this room.",
            starter = [=[
-- The Guest Ledger (Boss of Domain 1, second act)
-- Contract:
--   Ledger.new() -> registry
--   registry:register(name, attrs) -> true | nil, err
--   registry:lookup(name)           -> attrs | nil, err
--   registry:update(name, attrs)   -> true | nil, err
--   registry:remove(name)          -> true | nil, err
--   registry:census()              -> names, sorted, joined "\n"
-- A discourtesy is answered nil, err — never a raised error,
-- never a silent overwrite. The ledger is built from tables and
-- closures: the mirror-craft is another domain's teaching, and
-- its tools are not in this room.
Ledger = {}

function Ledger.new()
    -- the seam is here: the ledger keeps nothing yet
    return {}
end
]=],
            provides = { "Ledger" },
            tests = {
                { id = "v1", kind = "validation",
                  say = "A registered guest could not be found, or their record came back wrong.",
                  run = function(env)
                      local r = env.Ledger.new()
                      if r:register("Ada", { seat = 4 }) ~= true then
                          return false
                      end
                      local a = r:lookup("Ada")
                      return a ~= nil and a.seat == 4
                  end },
                { id = "v2", kind = "validation",
                  say = "The census must walk the names in sorted order, whatever order they arrived in.",
                  run = function(env)
                      local r = env.Ledger.new()
                      r:register("Wren", { seat = 7 })
                      r:register("Ada", { seat = 4 })
                      return r:census() == "Ada\nWren"
                  end },
                { id = "v3", kind = "validation",
                  say = "Update must merge, not replace; removal must make the place empty.",
                  run = function(env)
                      local r = env.Ledger.new()
                      r:register("Ada", { seat = 1 })
                      if r:update("Ada", { lamp = true }) ~= true then
                          return false
                      end
                      local a = r:lookup("Ada")
                      if a == nil or a.seat ~= 1 or a.lamp ~= true then
                          return false
                      end
                      if r:remove("Ada") ~= true then return false end
                      return r:lookup("Ada") == nil
                  end },
                { id = "v4", kind = "validation",
                  say = "A guest's record must come back with everything it was given.",
                  run = function(env)
                      local r = env.Ledger.new()
                      r:register("Bo", { seat = 2, note = "late" })
                      local a = r:lookup("Bo")
                      return a ~= nil and a.seat == 2 and a.note == "late"
                  end },
                { id = "a1", kind = "adversarial",
                  say = "An absent guest was answered with silence or a crash. The contract is nil, with the reason named.",
                  run = function(env)
                      local r = env.Ledger.new()
                      local a, err = r:lookup("Ghost")
                      return a == nil and type(err) == "string"
                  end },
                { id = "a2", kind = "adversarial",
                  say = "A second entry overwrote the first, or was not refused. A guest is entered once.",
                  run = function(env)
                      local r = env.Ledger.new()
                      r:register("Ada", { seat = 4 })
                      local ok, err = r:register("Ada", { seat = 9 })
                      if ok ~= nil or type(err) ~= "string" then
                          return false
                      end
                      local a = r:lookup("Ada")
                      return a ~= nil and a.seat == 4
                  end },
                { id = "a3", kind = "adversarial",
                  say = "An attribute chosen as false did not survive. false is a value; it is kept like any other.",
                  run = function(env)
                      local r = env.Ledger.new()
                      r:register("Cy", { lamp = false })
                      local a = r:lookup("Cy")
                      return a ~= nil and a.lamp == false
                  end },
                { id = "a4", kind = "adversarial",
                  say = "A discourtesy — an absent removal, an empty name, no name at all — was met with a crash or a shrug. Answer nil, err.",
                  run = function(env)
                      local r = env.Ledger.new()
                      local ok1, e1 = r:remove("Ghost")
                      local ok2, e2 = r:register("", {})
                      local ok3, e3 = r:register(nil, {})
                      return ok1 == nil and type(e1) == "string"
                          and ok2 == nil and type(e2) == "string"
                          and ok3 == nil and type(e3) == "string"
                  end },
            },
            hints = {
                "Keep the guests in a table of your own, one entry per name. lookup is a single question: is the name there?",
                "Every refusal is the same shape: return nil, \"the reason\". Check the discourtesy before you touch the state.",
                "census collects the names with pairs, sorts them with table.sort, and joins them — a canonical walk, never the order they arrived in.",
            },
        },
    },
}

-- The guild's old ledger, provided for the first act's diagnosis.
-- Lives in the harness's world, not the player's: its lookup already
-- keeps the contract (attrs, or nil, err) — the attendant's draft is
-- what fails to receive it.
function fixture_ledger()
    local guests = {
        Ada = { seat = 4 },
        Wren = { seat = 7 },
    }
    local led = {}
    function led:lookup(name)
        local g = guests[name]
        if g == nil then
            return nil, "no guest by that name"
        end
        return g
    end
    return led
end

return Boss
