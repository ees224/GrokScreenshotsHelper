#!/usr/bin/env bash
set -euo pipefail

HELPER_ROOT="${SKEENSHOT_HELPER_ROOT:-$HOME/GrokScreenshotsHelper}"

# Prefer newest local build (has canvas-on-launch fix) over stale /Applications copy.
CANDIDATES=(
  "$HELPER_ROOT/SkeenShot/build/Build/Products/Debug/SkeenShot.app"
  "$HELPER_ROOT/SkeenShot/build/Build/Products/Release/SkeenShot.app"
  "/Applications/SkeenShot.app"
)

pick_app() {
  local best="" best_mtime=0 mtime
  for app in "${CANDIDATES[@]}"; do
    [[ -d "$app" ]] || continue
    mtime=$(stat -f %m "$app/Contents/MacOS/SkeenShot" 2>/dev/null || echo 0)
    if (( mtime > best_mtime )); then
      best_mtime=$mtime
      best=$app
    fi
  done
  echo "$best"
}

APP="$(pick_app)"

if [[ -z "$APP" ]]; then
  echo "SkeenShot.app not found. Run: cd ~/GrokScreenshotsHelper && ./install.sh" >&2
  exit 1
fi

# LSUIElement=true hides Dock/canvas on older /Applications installs — warn once.
if plutil -extract LSUIElement raw "$APP/Contents/Info.plist" 2>/dev/null | grep -q true; then
  echo "NOTE: $APP is menubar-only (LSUIElement). Run ./install.sh to update." >&2
fi

open "$APP"