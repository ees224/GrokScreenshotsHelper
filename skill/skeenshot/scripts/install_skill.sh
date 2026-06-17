#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/.grok/skills/skeenshot"

mkdir -p "$HOME/.grok/skills"
if [[ -e "$DEST" && ! -L "$DEST" ]]; then
  rm -rf "$DEST"
fi
ln -sfn "$SRC" "$DEST"
chmod +x "$SRC/scripts/"*.sh
echo "Installed skill at $DEST"