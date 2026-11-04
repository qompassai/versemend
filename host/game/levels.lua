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

return Levels
