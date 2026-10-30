# Changelog

## Unreleased

- Regression suite runs in both Chromium and Firefox (Gecko).
- CI: tests + `web-ext lint` on every PR; tag `vX.Y.Z` builds the store zip and publishes a GitHub release.
- Offline regression tests (`npm test`): geometry assertions on Slack-shaped fixtures, including a control test proving the fixtures reproduce the stock bugs.
- Dev tools: pinned Playwright via `package.json` (`npm run login|dev|cdp|smoke|icons|lint|package`), CDP bound to `127.0.0.1`, selector smoke check, security note.

## 0.2.0 (2026-10-30)

- Icons, Firefox (`browser_specific_settings.gecko`) manifest support, `scripts/package.sh`.

## 0.1.0 (2026-10-30)

- CSS-only RTL fixes: messages (per-line direction), lists, quotes, inline code, links, mentions, code blocks, composer, threads, edit mode, sidebar names.
