# Slack RTL

Free fixes for Hebrew (and other right-to-left) text in Slack, for both the **web app** and the **desktop app**.

| You use Slack… | Get | |
|---|---|---|
| **In the browser** ([app.slack.com](https://app.slack.com)), Chrome or Edge | The **Chrome extension** | **[Add to Chrome](https://chromewebstore.google.com/detail/slack-rtl/ikenkefhipmmoaacphjacneglpmbabjp)** · [details](#install-in-chrome) |
| **As the desktop app on Windows** | **Slack (RTL)**, a patched copy of your Slack app (experimental) | **[Step-by-step guide](desktop/windows/README.md)** |
| As the desktop app on macOS or Linux | Not supported yet. Use the web app [installed as an app window](#use-it-like-a-desktop-app) | |

Both use the same CSS fix ([`extension/rtl.css`](extension/rtl.css)), so Hebrew looks the same in either.

**PRs are welcome!** See [Contributing](#contributing).

## What it fixes

Slack already detects RTL text (it puts `dir="auto"` on messages and the composer), then overrides it with a hard-coded `text-align: left`. Slack RTL undoes that and fixes the knock-on bidi bugs:

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

The Chrome extension is **CSS only**: no JavaScript, no permissions, no data collection. It only runs on `app.slack.com`. The desktop installer adds that same CSS to a local copy of your Slack app and changes nothing else in it ([how it works](desktop/windows/README.md#how-it-works)).

## Install in Chrome

1. Open **[Slack RTL on the Chrome Web Store](https://chromewebstore.google.com/detail/slack-rtl/ikenkefhipmmoaacphjacneglpmbabjp)** and click **Add to Chrome**.
2. Refresh any open [app.slack.com](https://app.slack.com) tab. Hebrew messages now align right.

Chrome keeps it up to date automatically. To remove it, right-click its icon → **Remove from Chrome**, or use `chrome://extensions`.

Edge and other Chromium browsers can install it from the same page (in Edge, first allow **extensions from other stores** when prompted).

### Manual install (from this repo)

For trying unreleased changes, or for the [optional add-on](#optional-add-on-copy-list-numbers), which isn't in the store. It takes about a minute.

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

## Install the desktop app version (Windows, experimental)

Browser extensions can't run inside the installed Slack desktop app. On **Windows**, [`desktop/windows/`](desktop/windows) has an experimental installer that builds **Slack (RTL)**, a patched copy of your installed Slack with the same fix built in:

- Your installed Slack is never modified, and the copy opens already signed in.
- No extra software is needed: double-click `slack-rtl-desktop.cmd`.
- You re-run it after each Slack update.

**[Step-by-step instructions →](desktop/windows/README.md)**

The web app [installed as an app window](#use-it-like-a-desktop-app) is still the simpler option. macOS and Linux desktop apps are not supported. On macOS, patching means re-signing the app, which signs you out.

## Optional add-on: copy list numbers

Slack drops the `1.`, `2.` … when you copy a numbered list out of a message. [`extras/copy-list-numbers/`](extras/copy-list-numbers) is a separate, **opt-in** extension that puts them back. Unlike the main extension it contains a small script (it only rewrites the copied plain text, only on `app.slack.com`, and sends nothing anywhere). It isn't in the store; install it [manually](#manual-install-from-this-repo) (**Load unpacked** → `extras/copy-list-numbers`).

## Limitations

- Slack desktop app: Windows only, experimental, and must be rebuilt after each Slack update ([details](desktop/windows/README.md)). Otherwise use the web app [installed as an app window](#use-it-like-a-desktop-app).
- Slack changes its markup from time to time; if something breaks, please open an issue (or a PR!).
- When you copy a numbered list out of Slack, the numbers are dropped (Slack's copy behaviour); install the optional add-on above to keep them.

## Contributing

PRs are welcome: bug fixes, coverage for parts of Slack that still render RTL badly (channel topics, huddle chat, …), Firefox support, Firefox Add-ons packaging, testing the Windows desktop installer ([#22](../../issues/22)), macOS desktop support.

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
