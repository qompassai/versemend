-- All in-game text that is not level data: the Keeper's conversation,
-- the hall's furniture, the chronicle, the codex. One home, so the
-- sanitization sweep has one throat to seize. The world is sealed:
-- its only imports are principles, and the craft itself — the old
-- tongue, Lua — which is the subject and is named as such.
local Content = {}

Content.game_title = "VERSEMEND"
Content.game_subtitle = "The Spellwright's Guild"
Content.course_name = "The Old Tongue — a course in Tiger Style Lua"

Content.motion_prompt = {
    title = "Before the lamps are lit",
    lines = {
        "This hall can move gently, or hold still. Both tell the",
        "same story; choose the one your eyes prefer. You can",
        "change your mind at the title screen, at any time.",
    },
    full = "Motion: full",
    reduced = "Motion: reduced",
}

Content.title = {
    begin = "Begin the Journey",
    continue_journey = "Continue the Journey",
    codex = "The Codex",
    motion_full = "Motion: full",
    motion_reduced = "Motion: reduced",
    note = "A course in the old tongue, kept by the guild of spellwrights.",
}

Content.arrival = {
    {
        speaker = "The Keeper of Lamps",
        lines = {
            "You came. Good. I am the Keeper of Lamps, and this",
            "hall is lit by written fire — every lamp in the",
            "parishes burns because an inscription says so, in",
            "the old tongue, Lua.",
        },
    },
    {
        speaker = "The Keeper of Lamps",
        lines = {
            "The inscriptions are failing, Apprentice. Not from",
            "malice, and rarely from ignorance of the parts. They",
            "fail at their seams — where a value was trusted",
            "without being received.",
        },
    },
    {
        speaker = "The Keeper of Lamps",
        lines = {
            "I will teach you my craft: what is lit, what is",
            "dark, and what merely looks lit. Work the commissions",
            "on the board. Prove each one at the gate, in running",
            "code, in front of witnesses. That is the whole law",
            "of this hall.",
        },
    },
    {
        speaker = "The Keeper of Lamps",
        lines = {
            "And know this before you begin: when the kingdom",
            "wins anyway, you will wake here, and everything you",
            "have learned will still be yours. We call it",
            "backlash. It charges time. Never knowledge.",
        },
    },
}

Content.hub = {
    board_title = "The Commission Board",
    board_note = "Domain 1 — Values & the two truths, kept by the Keeper of Lamps.",
    sealed_mark = "sealed",
    practice_mark = "sealed — practice at the yard",
    boss_locked = "The Hollow Guest — silent until the three works are sealed",
    boss_open = "The Hollow Guest — the boss of Domain 1",
    keeper_idle = {
        "The lamps that are lit, I can count. The lamps that",
        "merely look lit are your education.",
    },
    codex_button = "The Codex",
    chronicle_button = "The Chronicle",
    guest_book_button = "The Guest Book",
}

Content.guest_book = {
    title = "The Guest Book",
    closed_lines = {
        "The hall's guest book lies open, and no entry in it",
        "can be trusted: the attendant serves from memory,",
        "and fails on any name the old ledger does not hold.",
        "",
        "When the Guest Ledger is kept — the Hollow Guest",
        "faced, the technique sealed — this book will be kept",
        "by your own ledger, and an absent name will be",
        "received here as calmly as it is at the gate.",
    },
    open_intro = {
        "The book is kept now by your own Guest Ledger —",
        "the program you proved at the gate, working at",
        "the door. Ask after a guest:",
    },
    broken_lines = {
        "The kept ledger does not open. The inscription in",
        "the chronicle no longer runs — a later hand has",
        "overwritten the sealed draft. Seal the Hollow",
        "Guest again, and the book will keep itself",
        "once more.",
    },
    found_seat = "keeps seat %d.",
    lamp_lit = "Their lamp is lit.",
    lamp_dark = "Their lamp is dark — dark by choice, kept exactly as chosen.",
    absent = "the empty place",
    absent_note = "No crash. No blame. The absence was received.",
    back = "Return to the Hall",
}

Content.demo_intro = "Watch the mechanism work once, in the world."
Content.demo_next = "Continue"
Content.demo_to_editor = "To the writing surface"

Content.editor = {
    title_suffix = " — the writing surface",
    run_gate = "Run the Gate",
    contract = "The Contract",
    hints = "Hint",
    back = "Back to the Hall",
    token_note = "Token keys write the same tongue; the answer is never among them.",
}

Content.gate = {
    pass_title = "THE GATE OPENS",
    fail_title = "THE GATE HOLDS",
    record_note = "The gate's record is the evidence. It is written once, exactly, and may be re-walked at any time.",
    to_hall = "Return to the Hall",
    again = "Run the Gate Again",
}

Content.backlash = {
    title = "BACKLASH",
    intro = {
        "The lamps gutter along the parish road, and you wake",
        "at the hall with your draft exactly as you left it.",
        "Backlash is the kingdom's tuition: it charges time,",
        "never knowledge. Hear what the gate found:",
    },
    to_editor = "Return to the Writing Surface",
    to_hall = "Rest at the Hall",
}

Content.seal = {
    level = "The commission is sealed and entered in the chronicle.",
    boss = "The boss has fallen. Domain 1 is sealed.",
}

Content.codex_empty = {
    title = "The Codex",
    spread = "The spread: fourteen leaves, every one blank — honestly.",
    lines = {
        "Your codex is a book of blank pages, honestly kept.",
        "A technique is entered here only when its trial has",
        "been proved at a gate — never before, never on a",
        "promise.",
    },
}

Content.codex_d1 = {
    title = "Domain 1 — the technique is yours",
    spread = "The spread: leaf I is filled. Thirteen leaves wait, blank.",
    entry_title = "Absence is a value; receive it",
    lines = {
        "A function that can fail to find returns the documented",
        "absence, or nil with the reason named. The check lives",
        "at the call site, once. It works because the distance",
        "between a cause and its crash is where debugging",
        "budgets go to die.",
    },
    loot_line = "Kept in the grimoire: The Guest Ledger — the registry library.",
}

Content.chronicle = {
    title = "The Guild Chronicle",
    empty = "Blank pages, honestly kept. An entry exists only when its proof has been seen.",
    d1l1 = "Domain 1, first work — The Census. Sealed at the gate.",
    d1l2 = "Domain 1, second work — The Two Truths. Sealed at the gate.",
    d1l3 = "Domain 1, third work — The Assayer's Scales. Sealed at the gate.",
    d1boss = "Domain 1, the boss — The Hollow Guest has fallen. The Guest Ledger is kept.",
    closing = "The chronicle's next pages are blank — honestly. The road continues beyond this slice of the kingdom.",
}

Content.completion = {
    title = "DOMAIN 1 — SEALED",
    lines = {
        "The Keeper sets the Guest Ledger on the great table,",
        "beside the census you took on your first morning.",
        "",
        "\"You receive what the world hands you, and you check",
        "it at the door. That is the first lamp of the course.",
        "The others are lit from it.\"",
    },
    to_title = "Return to the Title",
}

return Content
