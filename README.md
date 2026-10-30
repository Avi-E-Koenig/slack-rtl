# Slack RTL

A tiny, free Chrome extension that fixes Hebrew (and other right-to-left) text in the [Slack web app](https://app.slack.com).

**PRs are welcome!** See [Contributing](#contributing).

## What it fixes

Slack already detects RTL text (it puts `dir="auto"` on messages and the composer), then overrides it with a hard-coded `text-align: left`. This extension undoes that and fixes the knock-on bidi bugs:

- Hebrew messages align right; each line picks its own direction, so mixed Hebrew/English messages read correctly
- Bulleted and numbered lists, with markers on the correct side
- Block quotes, with the quote bar on the correct side
- Inline code and links are isolated, so `1 to add` isn't reordered to `to add 1`
- `@mentions` stay intact inside Hebrew text
- Code blocks stay left-to-right
- Composer, thread replies and message editing: each line gets its own direction as you type
- Sidebar: the `guest` label no longer jumps in front of Hebrew names
- Canvases: each paragraph takes its own direction; list, number and checkbox markers follow the item's language

It also works in threads, search results, and light and dark themes.

It's **CSS only**: no JavaScript, no permissions, no data collection. It only runs on `app.slack.com`.

## Install

Not on the Chrome Web Store yet. To install from source:

1. Clone or [download](../../archive/refs/heads/main.zip) this repo.
2. Open `chrome://extensions` and turn on **Developer mode**.
3. Click **Load unpacked** and select the `extension/` folder.
4. Reload your Slack tab.

To update, pull the latest version, click the reload icon on the extension's card, then reload Slack.

**Firefox** (109+): open `about:debugging#/runtime/this-firefox`, click **Load Temporary Add-on…** and pick `extension/manifest.json`. Temporary add-ons are removed when Firefox restarts. The manifest passes `web-ext lint`, but Firefox hasn't been tested against live Slack yet; reports welcome.

## Optional add-on: copy list numbers

Slack drops the `1.`, `2.` … when you copy a numbered list out of a message. [`extras/copy-list-numbers/`](extras/copy-list-numbers) is a separate, **opt-in** extension that puts them back. Unlike the main extension it contains a small script (it only rewrites the copied plain text, only on `app.slack.com`, and sends nothing anywhere). Install it the same way (**Load unpacked** → `extras/copy-list-numbers`).

## Limitations

- Web app only. The Slack desktop app is Electron and can't load browser extensions.
- Slack changes its markup from time to time; if something breaks, please open an issue (or a PR!).
- When you copy a numbered list out of Slack, the numbers are dropped (Slack's copy behaviour); install the optional add-on above to keep them.

## Contributing

PRs are welcome: bug fixes, coverage for parts of Slack that still render RTL badly (channel topics, huddle chat, …), Firefox support, store packaging.

Tips:

- All rules live in [`extension/rtl.css`](extension/rtl.css). Every declaration needs `!important`: Chrome injects content-script CSS *before* Slack's own stylesheets, so Slack's equal-specificity rules would otherwise win. Testing by pasting a `<style>` tag into DevTools hides this, so always verify with the extension actually loaded.
- Prefer Slack's `data-qa` attributes and stable `p-`/`c-` class names over hashed class names (e.g. `foo__AbC12`), which change between deploys.
- Run `npm test`, and add a fixture plus a test in `tests/` when you fix a new surface.
- Please include before/after screenshots in your PR, using test content only.

### Dev tools (optional)

`tools/` drives a test Chromium over the Chrome DevTools Protocol (CDP). Setup: `npm install && npx playwright install chromium firefox`.

| Command | What it does |
|---|---|
| `npm run login` | Chromium with a dedicated test profile (`.pw-profile/`, git-ignored) and **no** automation flags, so Google SSO works. Log in to Slack once here. |
| `npm run dev` | Same profile with the unpacked extension loaded (`EXTRAS=1 npm run dev` also loads `extras/`). |
| `npm run cdp -- <script.mjs> [url]` | Attaches to the running browser and runs `export default async page => …` against the Slack tab; prints the result as JSON. |
| `npm test` | Offline regression tests: Slack-shaped fixtures + Slack's problem rules, `rtl.css` injected first (like Chrome), assertions on rendered positions. No Slack login needed. |
| `npm run smoke` | Counts matches for every selector in `rtl.css` on the current Slack page, to catch Slack renaming things. `0` = not on screen, or renamed. |
| `npm run icons` | Re-renders the PNG icons from `extension/icons/icon.svg`. |
| `npm run lint` | `web-ext lint` on the extension. |
| `npm run package` | Builds `dist/slack-rtl-<version>.zip` for store upload (`npm run package -- extras/copy-list-numbers` for the add-on). |

**Releasing:** bump `version` in `extension/manifest.json` and `CHANGELOG.md`, merge, then push a matching tag (`git tag v0.3.0 && git push origin v0.3.0`). The Release workflow tests, lints and attaches `slack-rtl-<version>.zip` to a GitHub release.

> **Security:** CDP gives full control of that browser, including the logged-in Slack session. The tools bind it to `127.0.0.1:9222` only. Use a test workspace or account if you can, don't expose the port, and close the browser when you're done.

## License

[MIT](LICENSE)
