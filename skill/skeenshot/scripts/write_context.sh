#!/usr/bin/env bash
set -euo pipefail

SCREENSHOTS_DIR="${SKEENSHOT_DIR:-$HOME/GrokScreenshots}"
CONTEXT_FILE="$SCREENSHOTS_DIR/.context.json"
ACTIVE_SESSIONS="$HOME/.grok/active_sessions.json"
NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$SCREENSHOTS_DIR"

session_id="${GROK_SESSION_ID:-}"
cwd="${GROK_WORKSPACE_ROOT:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
workspace_root="${GROK_WORKSPACE_ROOT:-${CLAUDE_PROJECT_DIR:-$cwd}}"

if [[ -z "$session_id" && -f "$ACTIVE_SESSIONS" ]]; then
  session_id="$(python3 - <<'PY'
import json, os
path = os.path.expanduser("~/.grok/active_sessions.json")
try:
    data = json.load(open(path))
    cwd = os.getcwd()
    match = next((s for s in reversed(data) if s.get("cwd") == cwd), None)
    if not match and data:
        match = data[-1]
    print(match.get("session_id", "") if match else "")
except Exception:
    print("")
PY
)"
  if [[ -n "$session_id" ]]; then
    cwd="$(python3 - <<'PY'
import json, os
path = os.path.expanduser("~/.grok/active_sessions.json")
try:
    data = json.load(open(path))
    cwd = os.getcwd()
    match = next((s for s in reversed(data) if s.get("cwd") == cwd), None)
    if not match and data:
        match = data[-1]
    print(match.get("cwd", os.getcwd()) if match else os.getcwd())
except Exception:
    print(os.getcwd())
PY
)"
    workspace_root="$cwd"
  fi
fi

python3 - <<PY
import json, os
out = {
    "session_id": "${session_id}" or None,
    "cwd": "${cwd}",
    "workspace_root": "${workspace_root}",
    "updated_at": "${NOW}"
}
path = os.path.expanduser("${CONTEXT_FILE}")
with open(path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
    f.write("\n")
print(path)
PY