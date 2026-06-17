#!/usr/bin/env bash
# One-time fix: build with Xcode automatic signing (creates Mac Development profile).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="$ROOT/SkeenShot/SkeenShot.xcodeproj"

echo "Opening Xcode for signing setup..."
echo "In Xcode:"
echo "  1. Select project SkeenShot → both targets (SkeenShot + SkeenShotShare)"
echo "  2. Signing & Capabilities → Team: your Apple ID team"
echo "  3. Product → Archive OR Product → Build (⌘B)"
echo "  4. Re-run: $ROOT/install.sh"
echo ""
open "$PROJECT"