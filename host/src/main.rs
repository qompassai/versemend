//! Versemend production host — binary entry.
//!
//! Modes (mirroring the slice C host's evidence paths):
//!   versemend                    the game, in a window
//!   versemend --selftest         the slice's 82-check harness against
//!                                this host's platforms; transcript on
//!                                stdout, exit code = failure count
//!   versemend --strand-proof     D-833 dual-interpreter proof: the
//!                                game's Lua 5.5 gate in-process + the
//!                                LuaJIT strand runner as a subprocess
//!   versemend --screenshot DIR   the slice's scripted walk rendered
//!                                by the real GUI platform, one PNG
//!                                per named beat in DIR

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.iter().any(|a| a == "--selftest") {
        std::process::exit(versemend::selftest());
    }
    if args.iter().any(|a| a == "--strand-proof") {
        std::process::exit(versemend::strand_proof());
    }
    if let Some(pos) = args.iter().position(|a| a == "--screenshot") {
        let Some(dir) = args.get(pos + 1) else {
            eprintln!("usage: versemend --screenshot DIR");
            std::process::exit(2);
        };
        versemend::run_screenshot_mode(std::path::PathBuf::from(dir));
        return;
    }
    versemend::run_app();
}
