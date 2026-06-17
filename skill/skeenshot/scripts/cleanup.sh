#!/usr/bin/env bash
set -euo pipefail

SCREENSHOTS_DIR="${SKEENSHOT_DIR:-$HOME/GrokScreenshots}"
ARCHIVE_DIR="$SCREENSHOTS_DIR/archive"
DAYS=30

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

mkdir -p "$ARCHIVE_DIR"
find "$SCREENSHOTS_DIR" -maxdepth 1 -name 'skeenshot_*.png' -mtime +"$DAYS" -print0 | while IFS= read -r -d '' file; do
  base="$(basename "$file")"
  mv "$file" "$ARCHIVE_DIR/$base"
  [[ -f "${file%.png}.json" ]] && mv "${file%.png}.json" "$ARCHIVE_DIR/${base%.png}.json"
  [[ -f "${file%.png}.analysis.md" ]] && mv "${file%.png}.analysis.md" "$ARCHIVE_DIR/${base%.png}.analysis.md"
done
echo "Archived files older than ${DAYS} days."