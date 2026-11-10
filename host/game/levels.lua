-- Domain 1 — Values & the two truths. Kept by the Keeper of Lamps.
-- Levels are data: brief, demonstration cards, contract, starter code,
-- the gate suite (half validation, half adversarial), a hint ladder,
-- and for every test the plain words the Keeper speaks when it is the
-- first to fail. Reference solutions live in tests/fixtures.lua, never
-- in the game.
local Levels = {}

Levels[#Levels + 1] = {
    id = "d1l1",
    domain = 1,
    number = 1,
    title = "The Census",
    mechanism = "The eight kinds",
    verb = "Receive",
    brief = {
        "The great table is laid by inscription each morning, and some",
        "mornings a place is simply not there. Before the hall can be",
        "served, someone must say what IS on the table — every thing by",
        "its kind, no thing by its name.",
        "",
        "Take the census of the table, Apprentice. Count each entry by",
        "the kind of its value. An entry whose value is absent is not",
        "an error in the world: absence is a value, and it is counted",
        "under its own kind like any other.",
    },
    demo = {
        {
            title = "The table at morning",
            lines = {
                "Three places are laid. Look at what each holds —",
                "not at the name card in front of it.",
            },
            boxes = {
                { text = "3", sub = "?" },
                { text = "\"lamp\"", sub = "?" },
                { text = "true", sub = "?" },
            },
        },
        {
            title = "Kinds, not names",
            lines = {
                "The tongue names eight kinds of value. Ask a value",
                "its kind with type() — it answers honestly, whatever",
                "the name card says.",
            },
            boxes = {
                { text = "3", sub = "number" },
                { text = "\"lamp\"", sub = "string" },
                { text = "true", sub = "boolean" },
            },
        },
        {
            title = "The empty place",
            lines = {
                "A fourth place is laid, and nothing is on it. The",
                "nothing has a kind too, and its kind is a word the",
                "tongue says plainly: nil.",
            },
            boxes = {
                { text = "3", sub = "number" },
                { text = "\"lamp\"", sub = "string" },
                { text = "true", sub = "boolean" },
                { text = "—", sub = "nil" },
            },
        },
    },
    contract = "census(entries) -> string\n"
        .. "  entries: an array of entry tables, { name = ..., value = ... }.\n"
        .. "  An entry's value may be absent; count it under its kind.\n"
        .. "  Return one line per kind present: \"<kind> <count>\", kinds\n"
        .. "  in alphabetical order, lines joined with \"\\n\".",
    starter = [=[
-- The Census (Domain 1, Level 1)
-- Contract: census(entries) -> string
--   entries: an array of entry tables { name = ..., value = ... }.
--   An entry's value may be absent; absence is a value too —
--   count it under its own kind.
--   Return one line per kind present: "<kind> <count>", kinds in
--   alphabetical order, lines joined with "\n".
function census(entries)
    -- the seam is here: this draft counts places, not kinds
    return "places " .. #entries
end
]=],
    provides = { "census" },
    tests = {
        { id = "v1", kind = "validation",
          say = "The plain table was miscounted: three things, three kinds, one each.",
          run = function(env)
              local e = {
                  { name = "Ada", value = 3 },
                  { name = "Bo", value = "lamp" },
                  { name = "Cy", value = true },
              }
              return env.census(e) == "boolean 1\nnumber 1\nstring 1"
          end },
        { id = "v2", kind = "validation",
          say = "An empty table has an empty census — no lines at all.",
          run = function(env)
              return env.census({}) == ""
          end },
        { id = "v3", kind = "validation",
          say = "Three and three-and-a-half are one kind: number. The census counts kinds.",
          run = function(env)
              local e = {
                  { name = "A", value = 3 },
                  { name = "B", value = 3.5 },
                  { name = "C", value = {} },
                  { name = "D", value = function() end },
              }
              return env.census(e) == "function 1\nnumber 2\ntable 1"
          end },
        { id = "v4", kind = "validation",
          say = "A place holding false is a place holding something. false is a value.",
          run = function(env)
              local e = { { name = "Ada", value = false } }
              return env.census(e) == "boolean 1"
          end },
        { id = "a1", kind = "adversarial",
          say = "The empty place was not counted. Absence is a value: receive it.",
          run = function(env)
              local e = {
                  { name = "Ada", value = 1 },
                  { name = "The Hollow Place" },
              }
              return env.census(e) == "nil 1\nnumber 1"
          end },
        { id = "a2", kind = "adversarial",
          say = "A thing was counted by its name card. A function's kind is not its name.",
          run = function(env)
              local e = {
                  { name = "greeting", value = function() end },
                  { name = "sum", value = "a string" },
              }
              return env.census(e) == "function 1\nstring 1"
          end },
        { id = "a3", kind = "adversarial",
          say = "The thread was missed, or the strings were split apart. Kinds gather.",
          run = function(env)
              local e = {
                  { name = "A", value = "x" },
                  { name = "B", value = coroutine.create(function() end) },
                  { name = "C", value = "y" },
              }
              return env.census(e) == "string 2\nthread 1"
          end },
    },
    hints = {
        "Walk every entry. For each one, ask its value for its kind: type(entry.value).",
        "Keep a count per kind in a table of your own. A kind you have not seen yet counts from zero — (counts[kind] or 0) + 1.",
        "Collect the kinds, table.sort them, and build one line per kind: kind .. \" \" .. count. Join the lines with \"\\n\".",
    },
}

Levels[#Levels + 1] = {
    id = "d1l2",
    domain = 1,
    number = 2,
    title = "The Two Truths",
    mechanism = "Truthiness",
    verb = "Receive",
    brief = {
        "The hall door is kept by an old inscription, written by a",
        "traveller from a stricter country — a place where zero means",
        "no and every question is answered yes or no. Here, the tongue",
        "knows only two false things: nil, and false itself. Everything",
        "else is true, even when it looks like nothing.",
        "",
        "The inscription refuses guests it should admit, and admits",
        "one guest it should refuse: a member whose rite was suspended",
        "by a chosen word. Repair the door-keeping. A value the user",
        "chose — even false, even nothing-looking — must survive your",
        "keeping exactly as chosen.",
    },
    demo = {
        {
            title = "Two false things",
            lines = {
                "In the old tongue, only nil and false are false.",
                "Zero is true. The empty string is true. A carved",
                "token in the hand is true.",
            },
            boxes = {
                { text = "nil", sub = "false" },
                { text = "false", sub = "false" },
                { text = "0", sub = "true" },
                { text = "\"\"", sub = "true" },
            },
        },
        {
            title = "The clobbering word",
            lines = {
                "Write `options.enabled or true` and a guest who",
                "chose false is overruled — the `or` cannot tell",
                "\"absent\" from \"chosen false\". Only one test can:",
                "enabled == nil.",
            },
            boxes = {
                { text = "absent", sub = "nil" },
                { text = "suspended", sub = "false" },
                { text = "in force", sub = "true" },
            },
        },
    },
    contract = "admit(guest, options) -> \"admit\" | \"refuse\"\n"
        .. "  The rite in force admits a guest who holds standing while\n"
        .. "  a place remains. Absent `enabled` means the rite has not\n"
        .. "  been suspended; only a chosen false suspends it. Standing\n"
        .. "  is any truthy value. places == 0 means the hall is full.\n"
        .. "fee(options) -> number\n"
        .. "  The door fee in coppers. Absent fee: the standard 2.\n"
        .. "  A fee of false means the guild waived it: the fee owed is 0.",
    starter = [=[
-- The Two Truths (Domain 1, Level 2) — repair
-- Contract: admit(guest, options) -> "admit" | "refuse"
--   The rite in force admits a guest who holds standing while a
--   place remains. Absent `enabled` means the rite has not been
--   suspended; only a chosen false suspends it. Standing is any
--   truthy value. places == 0 means the hall is full.
-- fee(options) -> number
--   The door fee in coppers. Absent fee: the standard 2.
--   A fee of false means the guild waived it: the fee owed is 0.
function admit(guest, options)
    local enabled = options.enabled or true
    if enabled == false then return "refuse" end
    if guest.member == true and options.places ~= 0 then
        return "admit"
    end
    return "refuse"
end

function fee(options)
    return options.fee or 2
end
]=],
    provides = { "admit", "fee" },
    tests = {
        { id = "v1", kind = "validation",
          say = "A plain member, rite in force, places free — the door refused them.",
          run = function(env)
              return env.admit({ name = "Ada", member = true },
                  { enabled = true, places = 2 }) == "admit"
          end },
        { id = "v2", kind = "validation",
          say = "A guest with no standing was admitted. Absent standing refuses.",
          run = function(env)
              return env.admit({ name = "Bo" },
                  { enabled = true, places = 2 }) == "refuse"
          end },
        { id = "v3", kind = "validation",
          say = "A chosen suspension was overruled. false is a value the user chose.",
          run = function(env)
              return env.admit({ member = true },
                  { enabled = false, places = 2 }) == "refuse"
          end },
        { id = "v4", kind = "validation",
          say = "A full hall admitted one more. Zero places is a fact, not an absence.",
          run = function(env)
              return env.admit({ member = true },
                  { enabled = true, places = 0 }) == "refuse"
          end },
        { id = "v5", kind = "validation",
          say = "The fee is wrong on a plain day: absent fee is 2, a stated fee is itself.",
          run = function(env)
              return env.fee({}) == 2 and env.fee({ fee = 5 }) == 5
          end },
        { id = "a1", kind = "adversarial",
          say = "Standing written in words was refused. Truth is not spelled `true`.",
          run = function(env)
              return env.admit({ member = "of the guild" },
                  { enabled = true, places = 1 }) == "admit"
          end },
        { id = "a2", kind = "adversarial",
          say = "An unspoken rite was treated as suspended. Absence is tested with == nil, never by spelling.",
          run = function(env)
              return env.admit({ member = true },
                  { places = 1 }) == "admit"
          end },
        { id = "a3", kind = "adversarial",
          say = "A waived fee was charged anyway. false was chosen; it must survive.",
          run = function(env)
              return env.fee({ fee = false }) == 0
          end },
        { id = "a4", kind = "adversarial",
          say = "A guest holding the carved token was refused. A table in the hand is true.",
          run = function(env)
              return env.admit({ member = {} },
                  { enabled = true, places = 1 }) == "admit"
          end },
    },
    hints = {
        "Two seams, both spelled with comparisons from a stricter country. Find every place the draft tests a value against a spelling of truth.",
        "`x or default` cannot tell absent from chosen-false. The absence test is x == nil; the suspension test is x == false.",
        "Standing is a truthiness question: `if not guest.member` refuses exactly the two false things. Nothing else needs spelling.",
    },
}

Levels[#Levels + 1] = {
    id = "d1l3",
    domain = 1,
    number = 3,
    title = "The Assayer's Scales",
    mechanism = "Numbers with two natures",
    verb = "Receive",
    brief = {
        "The guild's assayer weighs every tithe on two scales, and",
        "both scales are honest. A number in the old tongue wears one",
        "of two natures — integer or float — and the seam shows in",
        "division, in remainders, in how a weight is written down.",
        "",
        "Build the assayer's small library. Every operation must",
        "state which nature its result carries, and prove it: a",
        "halving that owes whole pieces, a sharing that owes exact",
        "parts, a remainder that follows its divisor's sign, and a",
        "weighing written so it can be read back to the same weight.",
    },
    demo = {
        {
            title = "Two scales, both honest",
            lines = {
                "Seven coppers, split two ways. The whole-piece",
                "scale says 3, and one copper remains. The exact",
                "scale says 3.5. Neither scale is lying; they are",
                "answering different questions.",
            },
            boxes = {
                { text = "7 // 2", sub = "3, integer" },
                { text = "7 / 2", sub = "3.5, float" },
            },
        },
        {
            title = "Equal, and not the same",
            lines = {
                "1 and 1.0 weigh the same — the comparison says so.",
                "But lay them on the nature scale and they differ.",
                "A contract names which scale a result answers to.",
            },
            boxes = {
                { text = "1 == 1.0", sub = "true" },
                { text = "math.type(1)", sub = "integer" },
                { text = "math.type(1.0)", sub = "float" },
            },
        },
    },
    contract = "assay — a table of the assayer's operations:\n"
        .. "  assay.halve(n, d)  -> n // d: whole pieces; integer nature.\n"
        .. "  assay.share(n, d)  -> n / d: exact parts; float nature.\n"
        .. "  assay.rest(n, d)   -> n % d: the remainder; its sign follows\n"
        .. "    the divisor, its nature follows the operands.\n"
        .. "  assay.nature(v)    -> \"integer\" | \"float\" for numbers,\n"
        .. "    otherwise the value's kind.\n"
        .. "  assay.weigh(v)     -> the written weight: integers plainly,\n"
        .. "    floats so they read back to the identical value.\n"
        .. "  assay.same(a, b)   -> true when a == b, across the seam.",
    starter = [=[
-- The Assayer's Scales (Domain 1, Level 3)
-- Contract: assay — a table of operations. Each result carries a
-- nature, and the nature is part of the contract:
--   assay.halve(n, d) -> n // d   (integer nature)
--   assay.share(n, d) -> n / d    (float nature)
--   assay.rest(n, d)  -> n % d    (sign follows the divisor)
--   assay.nature(v)   -> "integer" | "float" | the value's kind
--   assay.weigh(v)    -> the written weight, readable back exactly
--   assay.same(a, b)  -> a == b, across the seam
assay = {}

function assay.halve(n, d)
    -- the seam is here
    return 0
end

function assay.share(n, d)
    return 0
end

function assay.rest(n, d)
    return 0
end

function assay.nature(v)
    return ""
end

function assay.weigh(v)
    return ""
end

function assay.same(a, b)
    return false
end
]=],
    provides = { "assay" },
    tests = {
        { id = "v1", kind = "validation",
          say = "The halving is wrong: seven halved owes three whole pieces, of integer nature.",
          run = function(env)
              local h = env.assay.halve(7, 2)
              return h == 3 and env.assay.nature(h) == "integer"
          end },
        { id = "v2", kind = "validation",
          say = "The sharing is wrong: seven shared by two is three and a half, a float.",
          run = function(env)
              local s = env.assay.share(7, 2)
              return s == 3.5 and env.assay.nature(s) == "float"
          end },
        { id = "v3", kind = "validation",
          say = "One and one-point-nought are equal but not the same nature. Both halves must hold.",
          run = function(env)
              return env.assay.same(1, 1.0) == true
                  and env.assay.nature(1) == "integer"
                  and env.assay.nature(1.0) == "float"
          end },
        { id = "v4", kind = "validation",
          say = "The written weights are wrong: the integer prints plainly, the float keeps its mark.",
          run = function(env)
              return env.assay.weigh(3) == "3" and env.assay.weigh(3.0) == "3.0"
          end },
        { id = "a1", kind = "adversarial",
          say = "A debt halved was rounded toward the debtor. Halving floors: -7 // 2 is -4, whole and integer.",
          run = function(env)
              local h = env.assay.halve(-7, 2)
              return h == -4 and env.assay.nature(h) == "integer"
          end },
        { id = "a2", kind = "adversarial",
          say = "The remainder took the wrong sign. A remainder follows its divisor: -7 % 3 is 2.",
          run = function(env)
              return env.assay.rest(-7, 3) == 2
          end },
        { id = "a3", kind = "adversarial",
          say = "A written weight could not be read back. Floats are written to round-trip, exactly.",
          run = function(env)
              local third = 1 / 3
              return tonumber(env.assay.weigh(third)) == third
                  and env.assay.nature(env.assay.share(1, 3)) == "float"
          end },
        { id = "a4", kind = "adversarial",
          say = "A float remainder was forced into integer dress. The nature follows the operands.",
          run = function(env)
              local r = env.assay.rest(7.5, 2)
              return r == 1.5 and env.assay.nature(r) == "float"
          end },
    },
    hints = {
        "The tongue has two divisions because it has two questions: // owes whole pieces, / owes exact parts. The operators state the nature for you.",
        "math.type(v) names a number's nature and returns nil for anything else — for those, fall back to type(v).",
        "tostring already writes a float so it reads back to the identical value. Do not format a weight into a shorter lie.",
    },
}

-- Domain 2 — Tables, the one structure. Kept by the Registrar.
-- Appended to the same Levels table: the hub boards one domain at
-- a time, and the proof script's unit loop walks every level here.

Levels[#Levels + 1] = {
    id = "d2l1",
    domain = 2,
    number = 1,
    title = "The One House",
    mechanism = "Constructors and keys",
    verb = "Count",
    master = "The Registrar",
    brief = {
        "The guild keeps one structure for everything, Apprentice,",
        "and it is the table. A house is built in a single breath —",
        "the constructor — and what it holds is told by its keys:",
        "places in a row, or names on the doors.",
        "",
        "Build me the Registrar's three houses: the sequence, the",
        "record, and the mixture, where keyed entries stand among",
        "the places without taking one. Then tell me the shape of",
        "any house by counting what is actually in it.",
    },
    demo = {
        {
            title = "One house, two shapes",
            lines = {
                "A constructor writes both shapes in one breath:",
                "entries in a row take places; entries with a key",
                "take the name they are given — and no place.",
            },
            boxes = {
                { text = "\"Ada\"", sub = "place 1" },
                { text = "name = \"Bo\"", sub = "a key" },
                { text = "\"Cy\"", sub = "place 2" },
            },
        },
        {
            title = "Counting what stands",
            lines = {
                "The shape of a house is counted by walking it and",
                "asking each key its kind — never by asking where",
                "the house ends. A missing place is skipped by the",
                "walk and counted by nobody; it was never there.",
            },
            boxes = {
                { text = "[1] = \"x\"", sub = "counted" },
                { text = "[3] = \"z\"", sub = "counted" },
                { text = "[2]", sub = "not there" },
            },
        },
    },
    contract = "house(kind) -> table | nil, err\n"
        .. "  kind is \"sequence\", \"record\", or \"mixture\"; any\n"
        .. "  other word is a discourtesy, answered nil, err.\n"
        .. "  \"sequence\": the roll of the first watch, in order —\n"
        .. "    Ada, Bo, Cy; places only, no keys.\n"
        .. "  \"record\": the Registrar's own entry, keys only —\n"
        .. "    name = \"The Registrar\", office = \"The Roll Room\",\n"
        .. "    lamps = 3.\n"
        .. "  \"mixture\": the interleaved house — Ada at place 1,\n"
        .. "    Cy at place 2, and the keyed entries name = \"Bo\",\n"
        .. "    watch = 2 standing among them.\n"
        .. "shape(t) -> string\n"
        .. "  \"<a> array, <r> record\": a counts the integer keys\n"
        .. "  of t, 1 and upward, that are present — counted by\n"
        .. "  walking, never by a border; r counts every other key.\n"
        .. "  A value of false or 0 is present, and is counted.",
    starter = [=[
-- The One House (Domain 2, Level 1)
-- Contract: house(kind) -> table | nil, err  (see panel)
--           shape(t) -> "<a> array, <r> record"
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
    -- the seam is here: this draft takes the array's measure
    -- from its border — and a border is weather, not a count
    local a = #t
    local r = 0
    for k in pairs(t) do
        if not (type(k) == "number" and k % 1 == 0 and k >= 1) then
            r = r + 1
        end
    end
    return a .. " array, " .. r .. " record"
end
]=],
    provides = { "house", "shape" },
    tests = {
        { id = "v1", kind = "validation",
          say = "The sequence house is wrong: Ada, Bo, Cy at places 1, 2, 3, and nothing keyed.",
          run = function(env)
              local t, err = env.house("sequence")
              if t == nil then return false end
              return t[1] == "Ada" and t[2] == "Bo" and t[3] == "Cy"
                  and env.shape(t) == "3 array, 0 record"
          end },
        { id = "v2", kind = "validation",
          say = "The record house is wrong: three keyed entries, and no places at all.",
          run = function(env)
              local t, err = env.house("record")
              if t == nil then return false end
              return t.name == "The Registrar" and t.office == "The Roll Room"
                  and t.lamps == 3 and env.shape(t) == "0 array, 3 record"
          end },
        { id = "v3", kind = "validation",
          say = "The mixture is the lesson: keyed entries take no place, so Cy stands at place 2, not 3.",
          run = function(env)
              local t, err = env.house("mixture")
              if t == nil then return false end
              return t[1] == "Ada" and t[2] == "Cy" and t.name == "Bo"
                  and t.watch == 2 and env.shape(t) == "2 array, 2 record"
          end },
        { id = "v4", kind = "validation",
          say = "A holed house still has a shape: two places stand, one key is hung. Count what is there.",
          run = function(env)
              local t = { [1] = "x", [3] = "z", mark = true }
              return env.shape(t) == "2 array, 1 record"
          end },
        { id = "a1", kind = "adversarial",
          say = "A kind the house does not know is a discourtesy: answer nil with the reason named.",
          run = function(env)
              local t, err = env.house("attic")
              return t == nil and type(err) == "string"
          end },
        { id = "a2", kind = "adversarial",
          say = "\"Sequence\" is not \"sequence\". The roll is case-true; a near word is no word.",
          run = function(env)
              local t, err = env.house("Sequence")
              return t == nil and type(err) == "string"
          end },
        { id = "a3", kind = "adversarial",
          say = "Zero is present. false is present. Absence is the only absence — count what stands.",
          run = function(env)
              local t = { [1] = 0, flag = false }
              return env.shape(t) == "1 array, 1 record"
          end },
    },
    hints = {
        "A constructor reads its entries in order: the unkeyed ones take the next place, the keyed ones take their name and no place at all.",
        "shape walks the table with pairs and sorts each key it meets: an integer, 1 or greater, is a place; anything else is a key hung on the house.",
        "for k in pairs(t) do if type(k) == \"number\" and k % 1 == 0 and k >= 1 then a = a + 1 else r = r + 1 end end — never #t: the border is not a count.",
    },
}

Levels[#Levels + 1] = {
    id = "d2l2",
    domain = 2,
    number = 2,
    title = "The Missing Plank",
    mechanism = "The border",
    verb = "Count",
    master = "The Registrar",
    brief = {
        "The parish roll is written on the planks of the mill",
        "bridge, one name to a plank. A plank may be lifted for",
        "repair — the bridge keeps its length, the name is gone,",
        "and the crossing goes on around the gap.",
        "",
        "The old roll counted the parish by the bridge's far end,",
        "and buried two travellers in the arithmetic. Keep the",
        "roll yourself, Apprentice: every laying and lifting",
        "entered, and the count kept in the roll's own ledger —",
        "never taken from where the bridge happens to end.",
    },
    demo = {
        {
            title = "The bridge and its gap",
            lines = {
                "Three planks are laid, then the middle one is",
                "lifted. The bridge is still three places long.",
                "How many names does it carry? Two — and the far",
                "end will not tell you so.",
            },
            boxes = {
                { text = "1: Ada", sub = "standing" },
                { text = "2: —", sub = "lifted" },
                { text = "3: Cy", sub = "standing" },
            },
        },
        {
            title = "The count in the roll",
            lines = {
                "The roll carries its count in its own ledger",
                "line, written at every laying and every lifting.",
                "A length you depend on is state you own: the",
                "border is weather; the count is a kept thing.",
            },
            boxes = {
                { text = "kept = 2", sub = "the ledger line" },
                { text = "#bridge", sub = "weather" },
            },
        },
    },
    contract = "Roll — a ledgered list.\n"
        .. "  Roll.new() -> roll\n"
        .. "  roll:push(value) -> true | nil, err\n"
        .. "    Lays the next plank at the bridge's end — past\n"
        .. "    every place the bridge has ever had. A plank of\n"
        .. "    nothing is refused: nil, err.\n"
        .. "  roll:remove_at(place) -> value | nil, err\n"
        .. "    Lifts the plank at a place; the bridge keeps its\n"
        .. "    length and the count falls by one. A place that\n"
        .. "    stands empty, or lies beyond the bridge, is\n"
        .. "    answered nil, err.\n"
        .. "  roll:get(place) -> value | nil, err\n"
        .. "  roll:count() -> the roll's own count. The same\n"
        .. "    number is kept in the roll's ledger field,\n"
        .. "    roll.kept, written at every change — the field\n"
        .. "    is part of the contract.\n"
        .. "  roll:span() -> the bridge's length in places.\n"
        .. "  roll:walk() -> one line per place, \"<place>: <name>\",\n"
        .. "    a lifted plank shown as \"<place>: —\", lines joined\n"
        .. "    with \"\\n\"; an empty bridge answers \"\".",
    starter = [=[
-- The Missing Plank (Domain 2, Level 2)
-- Contract: Roll.new() -> roll, with push / remove_at / get /
--   count / span / walk, and the ledger field roll.kept.
--   (See the panel for the full contract.)
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
        -- the seam is here: the draft asks the bridge where it
        -- ends and calls the answer the count — a border is
        -- weather, and a holed bridge ends where it pleases
        return #items
    end

    function roll:span()
        return #items
    end

    function roll:walk()
        local lines = {}
        for i = 1, #items do
            lines[#lines + 1] = i .. ": " .. (items[i] ~= nil and tostring(items[i]) or "—")
        end
        return table.concat(lines, "\n")
    end

    return roll
end
]=],
    provides = { "Roll" },
    tests = {
        { id = "v1", kind = "validation",
          say = "Three planks laid: the count is three, the ledger field says three, the bridge spans three.",
          run = function(env)
              local roll = env.Roll.new()
              roll:push("Ada"); roll:push("Bo"); roll:push("Cy")
              return roll:count() == 3 and roll.kept == 3 and roll:span() == 3
                  and roll:walk() == "1: Ada\n2: Bo\n3: Cy"
          end },
        { id = "v2", kind = "validation",
          say = "A lifted plank leaves the bridge its length: span three, count two, a gap at place 2.",
          run = function(env)
              local roll = env.Roll.new()
              roll:push("Ada"); roll:push("Bo"); roll:push("Cy")
              local lifted = roll:remove_at(2)
              return lifted == "Bo" and roll:count() == 2 and roll.kept == 2
                  and roll:span() == 3 and roll:get(2) == nil
                  and roll:walk() == "1: Ada\n2: —\n3: Cy"
          end },
        { id = "v3", kind = "validation",
          say = "A new plank is laid past the bridge's end, not in the gap: places are history, not vacancies.",
          run = function(env)
              local roll = env.Roll.new()
              roll:push("Ada"); roll:push("Bo"); roll:push("Cy")
              roll:remove_at(2)
              roll:push("Di")
              return roll:span() == 4 and roll:count() == 3 and roll.kept == 3
                  and roll:get(4) == "Di"
                  and roll:walk() == "1: Ada\n2: —\n3: Cy\n4: Di"
          end },
        { id = "v4", kind = "validation",
          say = "The roll diverged from its model somewhere in the script. Keep the count at every single change.",
          run = function(env)
              local roll = env.Roll.new()
              local m_items, m_span, m_kept = {}, 0, 0
              local pool = { "Ada", "Bo", "Cy", "Di", "Eli" }
              local s = 20261109
              local function rnd(n)
                  s = (s * 1103515245 + 12345) % 2147483648
                  return s % n + 1
              end
              local function m_walk()
                  local lines = {}
                  for i = 1, m_span do
                      lines[#lines + 1] = i .. ": "
                          .. (m_items[i] ~= nil and tostring(m_items[i]) or "—")
                  end
                  return table.concat(lines, "\n")
              end
              for step = 1, 60 do
                  local op = rnd(3)
                  if op == 1 or m_span == 0 then
                      local v = pool[rnd(#pool)]
                      local ok = roll:push(v)
                      if ok ~= true then return false end
                      m_span = m_span + 1
                      m_items[m_span] = v
                      m_kept = m_kept + 1
                  elseif op == 2 then
                      local place = rnd(m_span + 1)
                      local got, err = roll:remove_at(place)
                      if m_items[place] ~= nil then
                          if got ~= m_items[place] then return false end
                          m_items[place] = nil
                          m_kept = m_kept - 1
                      else
                          if got ~= nil or type(err) ~= "string" then return false end
                      end
                  else
                      local place = rnd(m_span + 1)
                      local got, err = roll:get(place)
                      if m_items[place] ~= nil then
                          if got ~= m_items[place] then return false end
                      else
                          if got ~= nil or type(err) ~= "string" then return false end
                      end
                  end
                  if roll:count() ~= m_kept or roll.kept ~= m_kept
                      or roll:span() ~= m_span or roll:walk() ~= m_walk() then
                      return false
                  end
              end
              return true
          end },
        { id = "a1", kind = "adversarial",
          say = "A plank already lifted cannot be lifted again: the place stands empty, and the count must not fall twice.",
          run = function(env)
              local roll = env.Roll.new()
              roll:push("Ada"); roll:push("Bo"); roll:push("Cy")
              roll:remove_at(2)
              local gone, err = roll:remove_at(2)
              return gone == nil and type(err) == "string"
                  and roll:count() == 2 and roll.kept == 2
          end },
        { id = "a2", kind = "adversarial",
          say = "Places beyond the bridge, and place zero, are not places: answer nil with the reason named.",
          run = function(env)
              local roll = env.Roll.new()
              roll:push("Ada")
              local g0, e0 = roll:get(0)
              local g9, e9 = roll:get(99)
              local r9, e8 = roll:remove_at(99)
              return g0 == nil and type(e0) == "string"
                  and g9 == nil and type(e9) == "string"
                  and r9 == nil and type(e8) == "string"
                  and roll:count() == 1 and roll.kept == 1
          end },
        { id = "a3", kind = "adversarial",
          say = "A plank of nothing is refused. nil is not a name, and the count must not move for it.",
          run = function(env)
              local roll = env.Roll.new()
              roll:push("Ada")
              local ok, err = roll:push(nil)
              return ok == nil and type(err) == "string"
                  and roll:count() == 1 and roll.kept == 1 and roll:span() == 1
          end },
        { id = "a4", kind = "adversarial",
          say = "Here is the border lie, named: the bridge ends at 1 or 3 by the border's weather, and the count is two. Keep it yourself.",
          run = function(env)
              local roll = env.Roll.new()
              roll:push("Ada"); roll:push("Bo"); roll:push("Cy")
              roll:remove_at(2)
              return roll:count() == 2 and roll.kept == 2
                  and roll:walk() == "1: Ada\n2: —\n3: Cy"
          end },
    },
    hints = {
        "Keep three numbers' worth of truth: the planks, the bridge's span, and the count — the count written up and written down at every change, never recomputed.",
        "roll.kept is the ledger field: push writes kept = kept + 1, remove_at writes kept = kept - 1, and count() reads the field. It cannot drift, because nothing else writes it.",
        "span is its own kept number too: push lays at span + 1. If span ever came from #items, a lifted plank would shorten the bridge — and the next push would fill the gap.",
    },
}

Levels[#Levels + 1] = {
    id = "d2l3",
    domain = 2,
    number = 3,
    title = "Three Walks",
    mechanism = "Iteration with intent",
    verb = "Count",
    master = "The Registrar",
    brief = {
        "The feast roll is written fresh each night, and no two",
        "nights agree — not because the feast changes, but",
        "because the scribe walks the table as it comes to hand,",
        "and a table makes no promise about the order it keeps.",
        "",
        "There are three walks, Apprentice, and each promises",
        "something different. Learn what each one swears to, and",
        "then walk the canonical walk: gather the keys, sort",
        "them by a stated rule, and walk in that order — so the",
        "same table, written twice, reads the same twice.",
    },
    demo = {
        {
            title = "Three promises",
            lines = {
                "pairs promises every entry once — and no order.",
                "ipairs promises the places in order — and stops",
                "at the first place that is not there. next is the",
                "step beneath both: from a key, the next key.",
            },
            boxes = {
                { text = "pairs", sub = "all, unordered" },
                { text = "ipairs", sub = "places, to the gap" },
                { text = "next", sub = "the step itself" },
            },
        },
        {
            title = "The canonical walk",
            lines = {
                "Gather the keys. Sort them by the stated rule:",
                "integer keys ascending first, then string keys",
                "alphabetical. Walk in that order, and the roll",
                "is the same roll however the table was built.",
            },
            boxes = {
                { text = "1", sub = "places first" },
                { text = "2", sub = "ascending" },
                { text = "name", sub = "then names" },
            },
        },
    },
    contract = "walks — the three walks and the canonical one.\n"
        .. "  walks.by_pairs(t) -> string\n"
        .. "    Every entry of t, one line \"<key>=<value>\"; the\n"
        .. "    walk promises each entry once and no order at all.\n"
        .. "  walks.by_ipairs(t) -> string\n"
        .. "    The values at places 1, 2, 3, ..., one per line,\n"
        .. "    in order, ending at the first missing place.\n"
        .. "  walks.by_next(t) -> string\n"
        .. "    Every entry of t, one line \"<key>=<value>\", walked\n"
        .. "    by next from key to key; no order promised.\n"
        .. "  walks.canonical(t) -> string\n"
        .. "    Every entry, one line \"<key>=<value>\": integer keys\n"
        .. "    first, ascending; then string keys, alphabetical.\n"
        .. "    The same table always walks to the same string.\n"
        .. "  Values are written with tostring. The keys on this\n"
        .. "  roll are integers and strings; no other kind is\n"
        .. "  entered, and none need be answered.",
    starter = [=[
-- Three Walks (Domain 2, Level 3)
-- Contract: walks.by_pairs / by_ipairs / by_next / canonical
--   (see the panel for what each walk promises)
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
    -- the seam is here: the draft walks the table as it comes
    -- to hand and calls the result canonical — it is a walk,
    -- but nothing about it is chosen, so nothing is canonical
    return walks.by_pairs(t)
end
]=],
    provides = { "walks" },
    tests = {
        { id = "v1", kind = "validation",
          say = "The canonical walk is ordered: places ascending — 1, 2, 10 — then the names alphabetical.",
          run = function(env)
              local t = { [1] = "Ada", [2] = "Bo", [10] = "Di", name = "Cy", seat = 4 }
              return env.walks.canonical(t) == "1=Ada\n2=Bo\n10=Di\nname=Cy\nseat=4"
          end },
        { id = "v2", kind = "validation",
          say = "ipairs stops at the first missing place: place 4's guest is not reached from place 1.",
          run = function(env)
              local t = { [1] = "Ada", [2] = "Bo", [4] = "Di" }
              return env.walks.by_ipairs(t) == "Ada\nBo"
          end },
        { id = "v3", kind = "validation",
          say = "by_pairs owes every entry exactly once. Count the lines and sort them: the set is the promise.",
          run = function(env)
              local t = { [1] = "Ada", [2] = "Bo", [10] = "Di", name = "Cy", seat = 4 }
              local got = {}
              for line in (env.walks.by_pairs(t) .. "\n"):gmatch("(.-)\n") do
                  got[#got + 1] = line
              end
              table.sort(got)
              return table.concat(got, "\n") == "10=Di\n1=Ada\n2=Bo\nname=Cy\nseat=4"
          end },
        { id = "v4", kind = "validation",
          say = "by_next walks the same whole table as pairs — every entry, once — and ipairs walks a clean row fully.",
          run = function(env)
              local t = { [1] = "Ada", [2] = "Bo", [10] = "Di", name = "Cy", seat = 4 }
              local got = {}
              for line in (env.walks.by_next(t) .. "\n"):gmatch("(.-)\n") do
                  got[#got + 1] = line
              end
              table.sort(got)
              local seq = { [1] = "a", [2] = "b", [3] = "c" }
              return table.concat(got, "\n") == "10=Di\n1=Ada\n2=Bo\nname=Cy\nseat=4"
                  and env.walks.by_ipairs(seq) == "a\nb\nc"
          end },
        { id = "a1", kind = "adversarial",
          say = "The same feast, seated in a different order as it was built, read differently. Determinism is a walk you choose.",
          run = function(env)
              local t1 = { [1] = "Ada", [2] = "Bo", [10] = "Di", name = "Cy", seat = 4 }
              local t2 = {}
              t2.seat = 4
              t2.name = "Cy"
              t2[10] = "Di"
              t2[2] = "Bo"
              t2[1] = "Ada"
              local want = "1=Ada\n2=Bo\n10=Di\nname=Cy\nseat=4"
              return env.walks.canonical(t1) == want
                  and env.walks.canonical(t2) == want
          end },
        { id = "a2", kind = "adversarial",
          say = "A walk of places that begins with a gap ends at once: nothing stands at place 1.",
          run = function(env)
              local t = { [2] = "Bo" }
              return env.walks.by_ipairs(t) == ""
          end },
        { id = "a3", kind = "adversarial",
          say = "A negative place is still a place: integer keys ascend through it, ahead of every name.",
          run = function(env)
              local t = { [-1] = "west", [1] = "Ada", name = "Cy" }
              return env.walks.canonical(t) == "-1=west\n1=Ada\nname=Cy"
          end },
        { id = "a4", kind = "adversarial",
          say = "An empty table walks to an empty roll — every walk, no lines, no complaint.",
          run = function(env)
              return env.walks.canonical({}) == "" and env.walks.by_pairs({}) == ""
                  and env.walks.by_next({}) == "" and env.walks.by_ipairs({}) == ""
          end },
    },
    hints = {
        "canonical is a walk you choose: collect the keys into a list of your own first — a list has an order because you give it one.",
        "Sort the collected keys in two companies: the integers among themselves ascending, the strings among themselves alphabetical; then walk your list, not the table.",
        "table.sort(ints); table.sort(strs) — then read t[k] in list order. Never sort keys by their spellings: \"10\" walks before \"2\" as a word, and after it as a place.",
    },
}

return Levels
