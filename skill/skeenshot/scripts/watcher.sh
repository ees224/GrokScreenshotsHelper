#!/usr/bin/env bash
set -euo pipefail

SCREENSHOTS_DIR="${SKEENSHOT_DIR:-$HOME/GrokScreenshots}"
INBOX_FILE="$SCREENSHOTS_DIR/inbox.jsonl"
MANIFEST="$SCREENSHOTS_DIR/processed/manifest.txt"
PID_FILE="$SCREENSHOTS_DIR/.watcher.pid"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYZE_SH="$SCRIPT_DIR/analyze.sh"
ONCE=0
DAEMON=0

mkdir -p "$SCREENSHOTS_DIR/processed"
touch "$MANIFEST" "$INBOX_FILE"

get_analyze_mode() {
  local config="$SCREENSHOTS_DIR/config.toml"
  if [[ -f "$config" ]] && grep -q '^analyze_mode' "$config"; then
    grep '^analyze_mode' "$config" | head -1 | sed -E 's/.*=\s*"([^"]+)".*/\1/'
  else
    echo "queue"
  fi
}

notify() {
  local title="$1"
  local body="$2"
  osascript -e "display notification \"$body\" with title \"$title\"" 2>/dev/null || true
}

process_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  [[ "$file" == *.png ]] || return 0
  grep -Fxq "$file" "$MANIFEST" 2>/dev/null && return 0

  local session_id=""
  if [[ -f "${file%.png}.json" ]]; then
    session_id="$(python3 - <<PY
import json
try:
    print(json.load(open("${file%.png}.json")).get("session_id") or "")
except Exception:
    print("")
PY
)"
  fi

  python3 - <<PY
import json, datetime
entry = {
    "path": "${file}",
    "timestamp": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S") + "Z",
    "session_id": "${session_id}" or None,
    "source": "watcher",
    "status": "pending"
}
with open("${INBOX_FILE}", "a", encoding="utf-8") as f:
    f.write(json.dumps(entry) + "\n")
PY

  echo "$file" >> "$MANIFEST"
  notify "SkeenShot" "Saved $(basename "$file") — run /skeenshot analyze in Grok"

  local mode
  mode="$(get_analyze_mode)"
  if [[ "$mode" == "headless" || "$mode" == "both" ]]; then
    if [[ -x "$ANALYZE_SH" ]]; then
      analysis="$("$ANALYZE_SH" --headless "$file" 2>/dev/null || true)"
      if [[ -n "$analysis" && -f "$analysis" ]]; then
        summary="$(head -5 "$analysis" | tr '\n' ' ')"
        notify "SkeenShot Analysis" "$summary"
      fi
    fi
  fi

  echo "NEW:$file"
}

scan_once() {
  shopt -s nullglob
  for file in "$SCREENSHOTS_DIR"/skeenshot_*.png; do
    process_file "$file"
  done
  # Also pick up manual drops in inbox/ (any PNG)
  for file in "$SCREENSHOTS_DIR/inbox"/*.png "$SCREENSHOTS_DIR/inbox"/*.PNG; do
    process_file "$file"
  done
}

watch_fswatch() {
  fswatch -0 -e "$SCREENSHOTS_DIR/processed" -e "$SCREENSHOTS_DIR/archive" -e "$SCREENSHOTS_DIR/inbox" "$SCREENSHOTS_DIR" | while IFS= read -r -d '' path; do
    process_file "$path"
  done
}

watch_poll() {
  while true; do
    scan_once
    sleep 2
  done
}

stop_existing() {
  if [[ -f "$PID_FILE" ]]; then
    old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
      kill "$old_pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --once) ONCE=1; shift ;;
    --daemon) DAEMON=1; shift ;;
    --stop) stop_existing; exit 0 ;;
    *) shift ;;
  esac
done

if [[ "$ONCE" -eq 1 ]]; then
  scan_once
  exit 0
fi

stop_existing

if [[ "$DAEMON" -eq 1 ]]; then
  (
    if command -v fswatch >/dev/null 2>&1; then
      watch_fswatch
    else
      watch_poll
    fi
  ) &
  echo $! > "$PID_FILE"
  echo "Watcher started (pid $(cat "$PID_FILE"))"
  exit 0
fi

if command -v fswatch >/dev/null 2>&1; then
  watch_fswatch
else
  watch_poll
fi