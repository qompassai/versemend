#!/bin/bash
set -u
S=emulator-5560
E=~/.local/share/pax/versemend-rehost/evidence
APK=~/.local/share/pax/versemend-rehost/host/android/app/build/outputs/apk/release/app-release.apk
AAPT=$(ls /opt/android-sdk/build-tools/*/aapt2 2>/dev/null | head -1)
echo "== badging =="
"$AAPT" dump badging "$APK" 2>/dev/null | grep -E "^package|sdkVersion|targetSdkVersion|application-label:" | head -5
mkdir -p "$E/android"
echo "== install =="
adb -s $S install -r "$APK"
echo "== version assert (dumpsys BEFORE screenshots) =="
adb -s $S shell dumpsys package ai.qompass.versemend | grep -E "versionCode|versionName" | head -2
echo "== launch =="
adb -s $S shell am force-stop ai.qompass.versemend
adb -s $S shell monkey -p ai.qompass.versemend -c android.intent.category.LAUNCHER 1 2>&1 | tail -1
sleep 14
adb -s $S shell dumpsys activity activities | grep -E "topResumedActivity|ResumedActivity" | head -2
adb -s $S exec-out screencap -p > "$E/android/a-title.png"
ls -la "$E/android/a-title.png"
echo "== DRIVE-A DONE =="
