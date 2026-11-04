#!/bin/bash
set -u
H=~/.local/share/pax/versemend-rehost/host
E=~/.local/share/pax/versemend-rehost/evidence
APK=$H/android/app/build/outputs/apk/release/app-release.apk
cd "$H/android" && gradle assembleRelease > "$E/gradle-assemble2.log" 2>&1; echo "GRADLE_RC=$?"
sha256sum "$APK"; ls -la "$APK"
S=emulator-5560
adb -s $S install -r "$APK"
adb -s $S shell am force-stop ai.qompass.versemend
adb -s $S shell am start -n ai.qompass.versemend/com.google.androidgamesdk.GameActivity 2>&1 | tail -1
sleep 16
adb -s $S shell dumpsys activity activities | grep -E "topResumedActivity" | head -1
adb -s $S exec-out screencap -p > "$E/android/a-title.png"
ls -la "$E/android/a-title.png"
adb -s $S shell pidof ai.qompass.versemend || echo NO_PID
echo "== REBUILD+LAUNCH DONE =="
