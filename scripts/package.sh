#!/usr/bin/env bash
# Builds dist/slack-rtl-<version>.zip from extension/ for Chrome Web Store / AMO upload.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=$(node -p "require('$ROOT/extension/manifest.json').version")
OUT="$ROOT/dist/slack-rtl-$VERSION.zip"
mkdir -p "$ROOT/dist"
rm -f "$OUT"
(cd "$ROOT/extension" && zip -qr "$OUT" . -x 'icons/icon.svg')
echo "$OUT"
