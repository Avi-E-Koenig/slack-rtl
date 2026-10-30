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

## Install in Chrome

It's not on the Chrome Web Store yet, so you load it from this repo. It takes about a minute, and Edge and other Chromium browsers work the same way.

1. **Download:** on this page click **Code → Download ZIP** ([direct link](../../archive/refs/heads/main.zip)), then extract the ZIP. You get a folder named `slack-rtl-main`.
2. **Open the extensions page:** type `chrome://extensions` in the address bar.
3. **Turn on Developer mode** with the toggle in the top-right corner.
4. **Load it:** click **Load unpacked** and select the `extension` folder *inside* `slack-rtl-main`, the one that contains `manifest.json`. **Slack RTL** appears in the list.
5. **Reload Slack:** refresh any open [app.slack.com](https://app.slack.com) tab. Hebrew messages now align right.

Keep the extracted folder; Chrome loads the extension from it. You can move it somewhere permanent before step 4.

**Update:** download and extract the new ZIP over the old folder, click the ↻ reload icon on the extension's card in `chrome://extensions`, then refresh Slack.

**Remove:** click **Remove** on the extension's card.

> Chrome may show a "Disable developer mode extensions" banner at startup. Click ✕ to keep it; this is normal for extensions loaded from a folder.

### Use it like a desktop app

Install Slack as its own app window. It gets a taskbar or dock icon and notifications, and the extension works inside it:

- **Chrome:** open [app.slack.com](https://app.slack.com), then ⋮ → **Cast, save and share** → **Install page as app**.
- **Edge:** ⋯ → **Apps** → **Install this site as an app**.

### Firefox

Firefox 109+: open `about:debugging#/runtime/this-firefox`, click **Load Temporary Add-on…** and pick `extension/manifest.json`. Temporary add-ons are removed when Firefox restarts until it's published on Firefox Add-ons.

## The Slack desktop app is not supported

The installed Slack desktop app (Electron) can't load browser extensions. We tried injecting the same CSS through a launcher ([#3](../../issues/3), [#16](../../pull/16)). It worked, but it isn't practical:

- Slack deliberately refuses to start with a debugging port on its normal profile, to protect your session. So injection needs a separate Slack instance with its own profile and its own sign-in.
- Signing in to that instance is unreliable. The browser's sign-in hand-off (`slack://…`) always goes to your normal Slack, never to the second instance.

Patching Slack's app files isn't an option either: they're signed and overwritten on every update. Use the web app, ideally [installed as an app window](#use-it-like-a-desktop-app). If you find a clean way to support the desktop app, PRs are welcome.

## Optional add-on: copy list numbers

Slack drops the `1.`, `2.` … when you copy a numbered list out of a message. [`extras/copy-list-numbers/`](extras/copy-list-numbers) is a separate, **opt-in** extension that puts them back. Unlike the main extension it contains a small script (it only rewrites the copied plain text, only on `app.slack.com`, and sends nothing anywhere). Install it the same way (**Load unpacked** → `extras/copy-list-numbers`).

## Limitations

- Web app only: the [Slack desktop app is not supported](#the-slack-desktop-app-is-not-supported). Use the web app [installed as an app window](#use-it-like-a-desktop-app) instead.
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
