#!/usr/bin/env bash
# Builds a store-upload zip into dist/.
#   scripts/package.sh                            -> dist/slack-rtl-<version>.zip
#   scripts/package.sh extras/copy-list-numbers   -> dist/slack-rtl-copy-list-numbers-<version>.zip
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/${1:-extension}"
NAME=slack-rtl
[ "${1:-extension}" != extension ] && NAME="slack-rtl-$(basename "$SRC")"
VERSION=$(node -p "require('$SRC/manifest.json').version")
OUT="$ROOT/dist/$NAME-$VERSION.zip"
mkdir -p "$ROOT/dist"
rm -f "$OUT"
(cd "$SRC" && zip -qr "$OUT" . -x 'icons/icon.svg')
echo "$OUT"
