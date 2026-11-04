#!/bin/bash
set -u
H=~/.local/share/pax/versemend-rehost/host
E=~/.local/share/pax/versemend-rehost/evidence
cd "$H" || exit 1
cargo build --release --target x86_64-linux-android > "$E/build-android-x86_64.log" 2>&1
echo "X86_RC=$?"
cargo build --release --target aarch64-linux-android > "$E/build-android-arm64.log" 2>&1
echo "ARM_RC=$?"
ls -la target/x86_64-linux-android/release/libversemend.so target/aarch64-linux-android/release/libversemend.so 2>&1
cd "$H/android" || exit 1
gradle assembleRelease > "$E/gradle-assemble.log" 2>&1
echo "GRADLE_RC=$?"
find app/build/outputs/apk -name "*.apk" -exec ls -la {} \; -exec sha256sum {} \;
echo "== ANDROID BUILD DONE =="
