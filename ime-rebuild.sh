#!/bin/bash
set -u
H=~/.local/share/pax/versemend-rehost/host
E=~/.local/share/pax/versemend-rehost/evidence
cd "$H" || exit 1
echo "== android-target check + clippy =="
cargo clippy --target x86_64-linux-android --all-targets -- -D warnings > "$E/clippy-android.log" 2>&1
echo "CLIPPY_ANDROID_RC=$?"
echo "== rebuild android libs =="
cargo build --release --target x86_64-linux-android > "$E/build-android-x86_64-v2.log" 2>&1
echo "X86_RC=$?"
cargo build --release --target aarch64-linux-android > "$E/build-android-arm64-v2.log" 2>&1
echo "ARM_RC=$?"
cd "$H/android" && gradle assembleRelease > "$E/gradle-assemble3.log" 2>&1
echo "GRADLE_RC=$?"
APK=$H/android/app/build/outputs/apk/release/app-release.apk
sha256sum "$APK"; ls -la "$APK"
S=emulator-5560
adb -s $S install -r "$APK"
adb -s $S shell am force-stop ai.qompass.versemend
adb -s $S shell pm clear ai.qompass.versemend
echo "== IME REBUILD DONE =="
