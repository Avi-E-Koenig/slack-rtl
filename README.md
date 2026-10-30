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

It also works in threads, search results, and light and dark themes.

It's **CSS only**: no JavaScript, no permissions, no data collection. It only runs on `app.slack.com`.

## Install

Not on the Chrome Web Store yet. To install from source:

1. Clone or [download](../../archive/refs/heads/main.zip) this repo.
2. Open `chrome://extensions` and turn on **Developer mode**.
3. Click **Load unpacked** and select the `extension/` folder.
4. Reload your Slack tab.

To update, pull the latest version, click the reload icon on the extension's card, then reload Slack.

## Limitations

- Web app only. The Slack desktop app is Electron and can't load browser extensions.
- Slack changes its markup from time to time; if something breaks, please open an issue (or a PR!).
- When you copy a numbered list out of Slack, the numbers are dropped (Slack's copy behaviour; not fixed yet).

## Contributing

PRs are welcome: bug fixes, coverage for parts of Slack that still render RTL badly (channel topics, canvases, …), Firefox support, store packaging.

Tips:

- All rules live in [`extension/rtl.css`](extension/rtl.css). Every declaration needs `!important`: Chrome injects content-script CSS *before* Slack's own stylesheets, so Slack's equal-specificity rules would otherwise win. Testing by pasting a `<style>` tag into DevTools hides this, so always verify with the extension actually loaded.
- Prefer Slack's `data-qa` attributes and stable `p-`/`c-` class names over hashed class names (e.g. `foo__AbC12`), which change between deploys.
- Please include before/after screenshots in your PR, using test content only.

### Dev tools (optional)

`tools/` has scripts to drive a test Chromium over CDP (requires [Playwright](https://playwright.dev) installed globally: `npm i -g playwright && npx playwright install chromium`):

- `tools/browser.sh`: plain Chromium with a persistent profile (`.pw-profile/`, git-ignored). Use it to log in to Slack once; it has no automation flags, so Google SSO works.
- `NPM_GLOBAL=$(npm root -g) node tools/browser-ext.mjs`: the same profile with the unpacked extension loaded.
- `NPM_GLOBAL=$(npm root -g) node tools/cdp.mjs <script.mjs> [url]`: attaches to the running browser and runs `export default async page => …` against the Slack tab, printing the result as JSON.

`browser.sh` points at Playwright's Chromium under `~/.cache/ms-playwright/`; adjust the path for your version.

## License

[MIT](LICENSE)
