#!/usr/bin/env bash
# Save an image file to SkeenShot folder (for Shortcuts / Quick Action / Services).
set -euo pipefail

SRC="${1:-}"
if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "Usage: quick_save.sh <image-path>" >&2
  exit 1
fi

DEST_DIR="${SKEENSHOT_DIR:-$HOME/GrokScreenshots}"
CONTEXT="$DEST_DIR/.context.json"
SESSION_SHORT="unknown"

if [[ -f "$CONTEXT" ]]; then
  SESSION_SHORT="$(python3 - <<PY
import json
try:
    d=json.load(open("$CONTEXT"))
    sid=d.get("session_id") or ""
    print(sid[:8] if sid else "unknown")
except Exception:
    print("unknown")
PY
)"
fi

TS="$(date +%Y%m%d_%H%M%S)"
BASE="skeenshot_${SESSION_SHORT}_${TS}"
OUT="$DEST_DIR/${BASE}.png"

# Normalize to PNG
if [[ "${SRC,,}" == *.png ]]; then
  cp "$SRC" "$OUT"
else
  sips -s format png "$SRC" --out "$OUT" >/dev/null
fi

python3 - <<PY
import json, datetime, os
sidecar = {
    "session_id": None,
    "source": "quick_save",
    "saved_path": "$OUT",
    "timestamp": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "note": None
}
if os.path.exists("$CONTEXT"):
    try:
        sidecar.update(json.load(open("$CONTEXT")))
    except Exception:
        pass
with open("${OUT%.png}.json", "w") as f:
    json.dump(sidecar, f, indent=2)
    f.write("\n")
PY

"$HOME/GrokScreenshotsHelper/skill/skeenshot/scripts/watcher.sh" --once >/dev/null || true
echo "$OUT"
printf '%s' "$OUT" | pbcopy
osascript -e 'display notification "Saved to GrokScreenshots" with title "SkeenShot"'