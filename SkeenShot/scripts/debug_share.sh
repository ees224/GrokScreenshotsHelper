#!/usr/bin/env bash
# SkeenShot Share Extension diagnostics
set -euo pipefail

APP="/Applications/SkeenShot.app"
APPEX="$APP/Contents/PlugIns/SkeenShotShare.appex"
BUNDLE_ID="com.edmundskeen.skeenshot.share"

echo "=== SkeenShot Share Extension Debug ==="
echo

echo "--- App bundle ---"
ls -la "$APP/Contents/PlugIns/" 2>/dev/null || echo "MISSING: $APP"

echo
echo "--- Extension Info.plist ---"
plutil -p "$APPEX/Contents/Info.plist" 2>/dev/null | head -30 || echo "MISSING: $APPEX"

echo
echo "--- Code signing ---"
codesign -dv --verbose=2 "$APP" 2>&1 | grep -E 'Identifier|TeamIdentifier|Signature|Sealed' || true
codesign -dv --verbose=2 "$APPEX" 2>&1 | grep -E 'Identifier|TeamIdentifier|Signature|Sealed' || true
codesign --verify --deep --strict "$APP" 2>&1 && echo "codesign verify: OK" || echo "codesign verify: FAILED"

echo
echo "--- pluginkit registration ---"
if pluginkit -m -i "$BUNDLE_ID" -v 2>&1 | grep -q "$BUNDLE_ID"; then
  pluginkit -m -i "$BUNDLE_ID" -v
  echo "Status: REGISTERED"
else
  echo "Status: NOT REGISTERED (this is why Share sheet won't show it)"
  echo "Fix: run ~/GrokScreenshotsHelper/SkeenShot/scripts/register_extension.sh"
fi

echo
echo "--- All share extensions (sample) ---"
pluginkit -m -p com.apple.share-services -v 2>&1 | grep -i skeen || echo "(skeenshot not in list)"

echo
echo "--- System extension toggle ---"
echo "Check: System Settings → Privacy & Security → Extensions → Sharing"