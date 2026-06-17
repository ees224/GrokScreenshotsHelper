#!/usr/bin/env bash
set -euo pipefail

SCREENSHOTS_DIR="${SKEENSHOT_DIR:-$HOME/GrokScreenshots}"
CONFIG_FILE="$SCREENSHOTS_DIR/config.toml"
HEADLESS=0
IMAGE_PATH=""

usage() {
  echo "Usage: analyze.sh [--headless] <image-path>" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --headless) HEADLESS=1; shift ;;
    -h|--help) usage ;;
    *) IMAGE_PATH="$1"; shift ;;
  esac
done

[[ -n "$IMAGE_PATH" ]] || usage
[[ -f "$IMAGE_PATH" ]] || { echo "File not found: $IMAGE_PATH" >&2; exit 1; }

SIDEcar="${IMAGE_PATH%.png}.json"
NOTE=""
if [[ -f "$SIDEcar" ]]; then
  NOTE="$(python3 - <<PY
import json
try:
    data = json.load(open("${SIDEcar}"))
    print(data.get("note") or "")
except Exception:
    print("")
PY
)"
fi

ANALYSIS_PATH="${IMAGE_PATH%.png}.analysis.md"

if [[ "$HEADLESS" -eq 0 ]]; then
  echo "$IMAGE_PATH"
  exit 0
fi

if ! command -v grok >/dev/null 2>&1; then
  echo "grok CLI not found; cannot run headless analysis." >&2
  exit 1
fi

PROMPT="Analyze the screenshot at ${IMAGE_PATH}."
if [[ -n "$NOTE" ]]; then
  PROMPT="$PROMPT User note: ${NOTE}"
fi
PROMPT="$PROMPT Describe what you see, extract actionable text/UI details, and suggest next steps for the Grok Build session. Keep the response concise."

RESULT="$(grok -p "$PROMPT" --yolo --tools read_file 2>/dev/null || true)"
if [[ -z "$RESULT" ]]; then
  echo "Headless analysis failed." >&2
  exit 1
fi

{
  echo "# SkeenShot Analysis"
  echo
  echo "- Image: \`$IMAGE_PATH\`"
  echo "- Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo
  echo "$RESULT"
} > "$ANALYSIS_PATH"

echo "$ANALYSIS_PATH"