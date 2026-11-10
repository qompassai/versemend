# Versemend

## A fantasy role-playing game where you mend a kingdom's failing magic by writing real Lua.

<p align="center"><a href="https://github.com/qompassai/versemend">GitHub</a></p>

## Built with

![Lua](https://img.shields.io/badge/Lua-5.5-2C2D72?logo=lua&logoColor=white) ![Rust](https://img.shields.io/badge/Rust-000000?logo=rust&logoColor=white) ![Neovim](https://img.shields.io/badge/Neovim-nightly-57A143?logo=neovim&logoColor=white)

## What you do

In this kingdom, magic is written. Spells are programs in the old tongue — Lua — and mills turn, lamps burn, and ferries keep their hours because somebody wrote the inscription that tells them to. Lately the inscriptions are failing in patterns nobody recorded. You are the Apprentice: a young spellwright of the Spellwright's Guild who travels the kingdom setting its enchantments right — not by out-fighting broken magic, but by out-diagnosing it, in running code, in front of witnesses.

You take commissions at the guildhall, one domain of the language at a time. Field encounters teach each mechanism as physics; inscription repairs hand you a real program with a seam in it, to fix in the game's embedded Lua interpreter; and each domain ends in a guild trial — a complete small program you write or complete, which must run under the real interpreter and pass its full gate. What you learn is Tiger Style Lua: contracts stated before code, every loop bounded by a named constant, errors returned as values and never swallowed.

## Features

- A fourteen-domain curriculum, from first values and control flow through tables, closures, metatables, coroutines, and on to the C API and embedding — each domain a region of the kingdom with its own master, commissions, and trial
- Real programs, really run: repairs and trials execute in an embedded Lua 5.5 interpreter (with a LuaJIT strand in the endgame wing), gated by the programs' own test suites — half validation, half adversarial
- Deterministic by design: runs are proven, checksummed, and replayable, the same way on the desktop host and the Android build

## Status

**In development.** The first two domains are built and fully gated — 147 automated checks, zero failures, with identical proof transcripts across the in-process, system-Lua, and LuaJIT-strand routes — and the remaining domains are being built one at a time, in curriculum order. This repo carries the Rust host, the Android packaging, and the game itself. Free on release.

## Credits

A Qompass AI project.

Made with Rust and vendored Lua 5.5 (via mlua), with a two-process LuaJIT strand.
