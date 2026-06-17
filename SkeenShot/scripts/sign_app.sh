#!/usr/bin/env bash
# Sign SkeenShot.app + Share Extension for pluginkit registration.
set -euo pipefail

APP="${1:-/Applications/SkeenShot.app}"
IDENTITY="${SIGNING_IDENTITY:-Apple Development: tskeen@mac.com (P5GAPPJA4U)}"
APPEX="$APP/Contents/PlugIns/SkeenShotShare.appex"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENT_APP="$SCRIPT_DIR/../SkeenShot/SkeenShot.entitlements"
ENT_EXT="$SCRIPT_DIR/../SkeenShotShare/SkeenShotShare.entitlements"

if [[ ! -d "$APP" ]]; then
  echo "App not found: $APP" >&2
  exit 1
fi

if ! security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
  echo "Signing identity not found: $IDENTITY" >&2
  security find-identity -v -p codesigning
  exit 1
fi

echo "==> Signing Share Extension"
codesign --force --sign "$IDENTITY" \
  --entitlements "$ENT_EXT" \
  --timestamp \
  --options runtime \
  "$APPEX/Contents/MacOS/SkeenShotShare"
codesign --force --sign "$IDENTITY" \
  --entitlements "$ENT_EXT" \
  --timestamp \
  --options runtime \
  "$APPEX"

echo "==> Signing host app"
codesign --force --sign "$IDENTITY" \
  --entitlements "$ENT_APP" \
  --timestamp \
  --options runtime \
  "$APP/Contents/MacOS/SkeenShot"
codesign --force --sign "$IDENTITY" \
  --entitlements "$ENT_APP" \
  --timestamp \
  --options runtime \
  "$APP"

echo "==> Verifying"
codesign --verify --deep --strict --verbose=2 "$APP"
spctl -a -vv "$APP" 2>&1 || echo "(spctl may show reject until notarized — OK for local dev)"

echo "Signed: $APP"