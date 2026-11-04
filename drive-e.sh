#!/bin/bash
# Drive part 2: reset editor, keyevent surgery for L1, run its gate.
set -u
S=emulator-5560
E=~/.local/share/pax/versemend-rehost/evidence/android
SOL=~/.local/share/pax/versemend-rehost/solutions
tap() { adb -s $S shell input tap "$1" "$2"; sleep "${3:-2}"; }
shot() { adb -s $S exec-out screencap -p > "$E/$1"; echo "shot $1"; }
clearbuf() {
  adb -s $S shell input keyevent 123; sleep 1
  adb -s $S shell "input keyevent $(printf '67 %.0s' $(seq 1 700))"
  sleep 3
}

echo "== leave editor (IME hide check) =="
tap 620 156 3              # Back to the Hall (310,78)
adb -s $S shell dumpsys input_method | grep -E "mInputShown" | head -1
shot t-hall-return.png

echo "== re-enter L1 editor =="
tap 1400 342 3             # L1 row
tap 2160 1434 3            # brief
tap 1280 1208 2; tap 1280 1208 2; tap 1280 1208 3
adb -s $S shell dumpsys input_method | grep -E "mInputShown" | head -1
shot u-editor-fresh.png

echo "== clear starter by injected DEL keyevents =="
tap 341 742 2              # caret: end of last line
clearbuf
shot v-editor-cleared.png

echo "== type d1l1 solution by injected key events =="
. "$SOL/typein-d1l1.sh"
sleep 3
shot w-editor-solution.png

echo "== run the gate =="
tap 2090 164 6             # Run the Gate (1045,82)
shot x-gate-l1.png
adb -s $S shell dumpsys input_method | grep -E "mInputShown" | head -1
echo "DRIVE PART 2 DONE"
