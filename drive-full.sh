#!/bin/bash
# Versemend re-host: full-loop Android drive + IME proof.
set -u
S=emulator-5560
E=~/.local/share/pax/versemend-rehost/evidence/android
SOL=~/.local/share/pax/versemend-rehost/solutions
tap() { adb -s $S shell input tap "$1" "$2"; sleep "${3:-2}"; }
shot() { adb -s $S exec-out screencap -p > "$E/$1"; echo "shot $1"; }
clip() { DISPLAY=:0 xclip -selection clipboard -i "$SOL/$1.txt"; sleep 1; }

echo "== launch fresh =="
adb -s $S shell am start -n ai.qompass.versemend/ai.qompass.versemend.VersemendActivity >/dev/null 2>&1
sleep 14
tap 1000 1004 3            # Motion: full (500,493)
shot k-title.png
tap 1280 1388 4            # Begin (640,694)
for i in 1 2 3 4; do tap 2160 1434 2; done   # arrival (1080,717)
shot l-hub.png

echo "== L1 editor + IME typing proof =="
tap 1400 342 3             # L1 row (700,171)
tap 2160 1434 3            # the brief (1080,717)
tap 1280 1208 2; tap 1280 1208 2; tap 1280 1208 3   # demo cards (640,604)
shot m-editor-l1.png
adb -s $S shell dumpsys input_method | grep -E "mInputShown" | head -1
# soft-key typing: e n d (grounded coords)
adb -s $S shell input tap 768 1030; sleep 1
adb -s $S shell input tap 1531 1291; sleep 1
adb -s $S shell input tap 819 1160; sleep 2
shot n-ime-typed.png
# one backspace via soft key: expect exactly one char removed
adb -s $S shell input tap 2419 1030; sleep 2
shot o-ime-backspace.png
# clear the remaining two chars
adb -s $S shell input tap 2419 1030; sleep 1
adb -s $S shell input tap 2419 1030; sleep 2

echo "== clear starter (long-press backspace) =="
adb -s $S shell input swipe 2419 1030 2419 1030 12000
sleep 2
shot p-editor-cleared.png

echo "== paste solution via Gboard clipboard =="
clip d1l1
# Gboard clipboard icon in the suggestion strip (grounded later if this misses)
adb -s $S shell input tap 1244 1141; sleep 3
shot q-gboard-clipboard.png
echo "DRIVE PART 1 DONE"
