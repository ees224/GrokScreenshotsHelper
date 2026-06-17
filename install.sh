#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCREENSHOTS_DIR="$HOME/GrokScreenshots"
INSTALL_HOOKS="${INSTALL_HOOKS:-1}"
BUILD_APP="${BUILD_APP:-1}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-P5GAPPJA4U}"

echo "==> SkeenShot install"
echo "Root: $ROOT"

mkdir -p "$SCREENSHOTS_DIR"/{inbox,processed,archive}

if [[ ! -f "$SCREENSHOTS_DIR/config.toml" ]]; then
  cp "$ROOT/config/skeenshot.toml.example" "$SCREENSHOTS_DIR/config.toml"
  echo "Created $SCREENSHOTS_DIR/config.toml"
fi

echo "==> Installing Grok skill"
"$ROOT/skill/skeenshot/scripts/install_skill.sh"

if [[ "$BUILD_APP" == "1" ]]; then
  echo "==> Generating app icons"
  python3 "$ROOT/SkeenShot/scripts/generate_icons.py"

  echo "==> Building SkeenShot.app (Xcode signing + provisioning)"
  cd "$ROOT/SkeenShot"
  set +e
  xcodebuild \
    -scheme SkeenShot \
    -configuration Release \
    -derivedDataPath build \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    CODE_SIGN_STYLE=Automatic \
    -allowProvisioningUpdates \
    build 2>&1 | tee "$ROOT/SkeenShot/build/last-build.log"
  BUILD_OK=${PIPESTATUS[0]}
  set -e

  APP_SRC="$ROOT/SkeenShot/build/Build/Products/Release/SkeenShot.app"
  APP_DEST="/Applications/SkeenShot.app"

  if [[ "$BUILD_OK" -ne 0 ]]; then
    echo "==> Automatic signing failed; falling back to manual sign"
    xcodebuild \
      -scheme SkeenShot \
      -configuration Release \
      -derivedDataPath build \
      CODE_SIGN_IDENTITY="-" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      build
    chmod +x "$ROOT/SkeenShot/scripts/sign_app.sh"
    "$ROOT/SkeenShot/scripts/sign_app.sh" "$APP_SRC" || true
  fi

  if [[ -d "$APP_SRC" ]]; then
    rm -rf "$APP_DEST"
    ditto "$APP_SRC" "$APP_DEST"
    echo "Installed $APP_DEST"
    chmod +x "$ROOT/SkeenShot/scripts/register_extension.sh"
    "$ROOT/SkeenShot/scripts/register_extension.sh" || true
    open -g "$APP_DEST"
  else
    echo "Build succeeded but app not found at $APP_SRC" >&2
    exit 1
  fi
fi

if [[ "$INSTALL_HOOKS" == "1" ]]; then
  mkdir -p "$HOME/.grok/hooks"
  HOOK_SRC="$ROOT/hooks/skeenshot-context.json"
  HOOK_DEST="$HOME/.grok/hooks/skeenshot-context.json"
  sed "s|/Users/edmundskeen|$HOME|g" "$HOOK_SRC" > "$HOOK_DEST"
  echo "Installed hook $HOOK_DEST"
fi

chmod +x "$ROOT/skill/skeenshot/scripts/"*.sh
chmod +x "$ROOT/SkeenShot/scripts/"*.sh 2>/dev/null || true

echo ""
echo "SkeenShot installed."
echo "  Screenshots: $SCREENSHOTS_DIR"
echo "  Skill:       ~/.grok/skills/skeenshot"
echo "  App:         /Applications/SkeenShot.app"
echo ""
echo "Next steps:"
echo "  1. System Settings → Privacy & Security → Extensions → Sharing → enable SkeenShot"
echo "  2. Screenshot → Share → Send to Grok (SkeenShot)"
echo "  3. In Grok TUI: /skeenshot"