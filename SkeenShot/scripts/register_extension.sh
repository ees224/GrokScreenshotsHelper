#!/usr/bin/env bash
set -euo pipefail

APP="/Applications/SkeenShot.app"
APPEX="$APP/Contents/PlugIns/SkeenShotShare.appex"
BUNDLE_ID="com.edmundskeen.skeenshot.share"

if [[ ! -d "$APPEX" ]]; then
  echo "Share extension not found at $APPEX" >&2
  exit 1
fi

echo "==> Verifying code signature"
codesign --verify --deep --strict "$APP" 2>&1 || {
  echo "WARNING: App is not properly signed. Share extensions require Apple Development signing." >&2
}

echo "==> Registering with pluginkit"
pluginkit -r "$APPEX" 2>/dev/null || true
pluginkit -a "$APPEX"
pluginkit -e use -i "$BUNDLE_ID" 2>/dev/null || true

echo "==> pluginkit status"
if pluginkit -m -i "$BUNDLE_ID" -v 2>&1 | grep -q "$BUNDLE_ID"; then
  echo "OK: $BUNDLE_ID is registered with pluginkit"
  pluginkit -m -i "$BUNDLE_ID" -v
else
  echo "NOTE: Share Extension not registered with pluginkit."
  echo "      Cause: missing embedded.provisionprofile (needs Xcode Automatic Signing)."
  echo "      Fix: run ~/GrokScreenshotsHelper/SkeenShot/scripts/xcode_sign_and_install.sh"
  echo "      Workaround: Shortcuts Share action — see ~/GrokScreenshotsHelper/shortcuts/README.md"
fi

echo "==> Launching host app (required for first-time extension discovery)"
open -g "$APP"

echo ""
echo "If Share still missing from screenshot preview:"
echo "  1. System Settings → Privacy & Security → Extensions → Sharing → enable SkeenShot"
echo "  2. Log out/in or: killall Screenshot 2>/dev/null; killall screencaptureui 2>/dev/null"
echo "  3. Re-run: $0"