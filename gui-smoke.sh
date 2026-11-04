#!/bin/bash
set -u
H=~/.local/share/pax/versemend-rehost/host
E=~/.local/share/pax/versemend-rehost/evidence
RT=$E/runtime
rm -rf "$RT"; mkdir -p "$RT/shots"
cp "$H/target/release/versemend" "$H/target/release/versemend-jitrunner" "$RT/"
cp -r "$H/assets" "$RT/assets"
cd "$RT" || exit 1
export WINIT_UNIX_BACKEND=x11 LIBGL_ALWAYS_SOFTWARE=1 RUST_LOG=warn

echo "== GUI smoke (25 s, Xvfb :99, null sink) =="
Xvfb :99 -screen 0 1400x950x24 > "$E/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 2
export DISPLAY=:99
timeout 25 ./versemend > "$E/gui-smoke.log" 2>&1
echo "GUI_RC=$? (124 = timeout kill after a clean run)"
grep -E "FIRST_FRAME_MS|error|panic" "$E/gui-smoke.log" | head -10
pactl list sink-inputs 2>/dev/null | grep -c "Sink Input" || true

echo "== screenshot mode =="
rm -f versemend-save.txt
timeout 240 ./versemend --screenshot "$RT/shots" > "$E/screenshot-run.log" 2>&1
echo "SHOTS_RC=$?"
grep -E "SHOTS_COLLECTED|SHOT_OK|SHOT_TIMEOUT" "$E/screenshot-run.log"
ls -la "$RT/shots"
kill $XVFB_PID 2>/dev/null
echo "== GUI SMOKE DONE =="
