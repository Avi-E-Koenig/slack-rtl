#!/usr/bin/env bash
# Plain Chromium (no automation flags, so Google SSO works) with a persistent profile
# for Google SSO login (it ignores --load-extension; use browser-ext.mjs for that). Inspection scripts attach afterwards via
# chromium.connectOverCDP('http://localhost:9222').
DIR="$(cd "$(dirname "$0")/.." && pwd)"
exec ~/.cache/ms-playwright/chromium-1248/chrome-linux64/chrome \
  --user-data-dir="$DIR/.pw-profile" \
  --remote-debugging-port=9222 \
  --no-first-run --no-default-browser-check \
  https://app.slack.com/client
