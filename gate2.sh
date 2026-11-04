#!/bin/bash
set -u
H=~/.local/share/pax/versemend-rehost/host
E=~/.local/share/pax/versemend-rehost/evidence
cd "$H" || exit 1
cargo fmt && cargo fmt --check; echo "FMT_RC=$?"
cargo clippy --all-targets -- -D warnings > "$E/clippy2.log" 2>&1; echo "CLIPPY_RC=$?"
cargo test > "$E/cargo-test2.log" 2>&1; echo "TEST_RC=$?"
grep -E "test result" "$E/cargo-test2.log"
cargo build --release > "$E/build-release2.log" 2>&1; echo "BUILD_RC=$?"
echo "== GATE2 DONE =="
