//! Versemend spike — LuaJIT strand runner (route (a): two processes).
//! A separate small binary whose mlua build selects LuaJIT (mlua's version
//! features are mutually exclusive per build, so the strand gets its own
//! binary). Embeds the shared strand harness + presets, runs one gate,
//! prints the canonical record. Exit 0 = gate ran; 2 = runner failure.

use mlua::prelude::*;

const GATE_JIT_LUA: &str = include_str!("gate-jit.lua");
const STRAND_LUA: &str = include_str!("strand.lua");

fn main() {
    let arg = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "solution".to_string());
    let code = run(&arg);
    std::process::exit(code);
}

fn run(arg: &str) -> i32 {
    // The strand harness needs debug.sethook count hooks; mlua classifies
    // the debug library as unsafe for its safe constructors (see the main
    // host's Gate::new for the full reasoning). Same deliberate choice.
    let lua = unsafe { Lua::unsafe_new_with(mlua::StdLib::ALL, LuaOptions::default()) };
    let gate: LuaTable = match lua.load(GATE_JIT_LUA).eval() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("gate-jit load failed: {e}");
            return 2;
        }
    };
    let strand: LuaTable = match lua.load(STRAND_LUA).eval() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("strand load failed: {e}");
            return 2;
        }
    };
    let source: String = match strand.get::<LuaString>(arg) {
        Ok(s) => s.to_str().map(|s| s.to_string()).unwrap_or_default(),
        Err(_) => match std::fs::read_to_string(arg) {
            Ok(text) => text,
            Err(_) => {
                eprintln!("no such preset or file: {arg}");
                return 2;
            }
        },
    };
    let run_gate: LuaFunction = match gate.get("run_gate") {
        Ok(f) => f,
        Err(e) => {
            eprintln!("run_gate: {e}");
            return 2;
        }
    };
    match run_gate.call::<String>(&*source) {
        Ok(record) => {
            print!("{record}");
            0
        }
        Err(e) => {
            eprintln!("run_gate failed: {e}");
            2
        }
    }
}
