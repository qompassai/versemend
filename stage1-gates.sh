#!/bin/bash
# Versemend re-host Stage 1 gates (run on primo)
set -u
H=~/.local/share/pax/versemend-rehost/host
J=~/.local/share/pax/versemend-rehost/jitrunner
E=~/.local/share/pax/versemend-rehost/evidence
mkdir -p "$E"
cd "$H" || exit 1

echo "== cargo test (host) =="
cargo test > "$E/cargo-test.log" 2>&1; echo "TEST_RC=$?"
grep -E "test result" "$E/cargo-test.log"

echo "== clippy -D warnings =="
cargo clippy --all-targets -- -D warnings > "$E/clippy.log" 2>&1; echo "CLIPPY_RC=$?"

echo "== fmt =="
cargo fmt --check > "$E/fmt.log" 2>&1; echo "FMT_RC=$?"

echo "== release builds =="
cargo build --release > "$E/build-release.log" 2>&1; echo "BUILD_RC=$?"
(cd "$J" && cargo build --release > "$E/build-jitrunner.log" 2>&1); echo "JIT_BUILD_RC=$?"
cp "$J/target/release/versemend-jitrunner" "$H/target/release/"
ls -la "$H/target/release/versemend" "$H/target/release/versemend-jitrunner"

echo "== adoption: selftest vs slice transcript =="
cd "$H/target/release" || exit 1
./versemend --selftest > "$E/transcript-rusthost.txt" 2>&1; echo "SELFTEST_RC=$?"
SLICE=~/.local/share/pax/versemend-playable/evidence/transcript-host.txt
if cmp -s "$E/transcript-rusthost.txt" "$SLICE"; then echo "TRANSCRIPT_IDENTICAL=yes"; else echo "TRANSCRIPT_IDENTICAL=no"; diff "$SLICE" "$E/transcript-rusthost.txt" | head -20; fi
grep -c "^check .* PASS" "$E/transcript-rusthost.txt"
grep "SELFTEST failures" "$E/transcript-rusthost.txt"
grep "unit .* checksum" "$E/transcript-rusthost.txt"

echo "== strand proof x2 =="
./versemend --strand-proof 2>&1 | tee "$E/strand-proof-1.txt"; echo "STRAND1_RC=${PIPESTATUS[0]}"
./versemend --strand-proof 2>&1 | tee "$E/strand-proof-2.txt"; echo "STRAND2_RC=${PIPESTATUS[0]}"

echo "== determinism: selftest x2 hash =="
./versemend --selftest 2>/dev/null | sha256sum
./versemend --selftest 2>/dev/null | sha256sum
sha256sum "$E/transcript-rusthost.txt"

echo "== STAGE1 SCRIPT DONE =="
