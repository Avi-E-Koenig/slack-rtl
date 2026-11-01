# Slack RTL for the Slack desktop app (Windows), experimental

Browser extensions can't run inside the Slack desktop app. This folder has a small installer that builds **Slack (RTL)**: a separate copy of your installed Slack desktop app with the same Hebrew/RTL fix built in.

Slack RTL is an independent community project, not affiliated with or endorsed by Slack Technologies. The installer only modifies a local copy of the Slack app you already installed; it does not redistribute Slack.

> **Easier and safer:** use the [Chrome extension](../../README.md#install-in-chrome) with the Slack web app [installed as an app window](../../README.md#use-it-like-a-desktop-app). It looks and behaves almost like the desktop app and needs none of the steps below. Use this installer only if you specifically want the desktop app.

## Before you start

- **Windows 10 or 11** with the Slack desktop app installed, either from the **Microsoft Store** or from **slack.com**.
- **Sign in to Slack** in your normal Slack app first. Slack (RTL) starts with a copy of that sign-in, so you don't have to sign in again.
- **No extra software is needed.** The installer uses the PowerShell that comes with Windows.
- About **400 MB** of free disk space for the copy.

Tested with Slack **4.53** from the **Microsoft Store**. The slack.com version is detected and should work the same way, but it hasn't been tested yet. Please [report how it goes](https://github.com/Avi-E-Koenig/slack-rtl/issues).

## Install

1. **Download this repo:** on the [main page](https://github.com/Avi-E-Koenig/slack-rtl) ([direct ZIP link](https://github.com/Avi-E-Koenig/slack-rtl/archive/refs/heads/main.zip)) click **Code → Download ZIP**, then extract the ZIP. You get a folder named `slack-rtl-main`. Keep the whole folder: the installer reads `extension\rtl.css` from it.
2. **Quit Slack completely.** Closing the window isn't enough, because Slack keeps running in the tray. Click the **^** arrow next to the clock, right-click the **Slack** icon, then click **Quit**.
3. **Run the installer:** open `slack-rtl-main\desktop\windows` and double-click **`slack-rtl-desktop.cmd`**.
   - If Windows shows *"Windows protected your PC"*, click **More info → Run anyway**. Windows shows this for any script downloaded from the internet.
   - A black window shows 5 steps and ends with **Done**. It takes about a minute. Press any key to close it.
4. **Open Slack (RTL):** double-click the **Slack (RTL)** icon on your desktop, or press the Windows key and type **Slack (RTL)**. Hebrew messages now align right.

   Slack (RTL) has its own purple **א** icon, on the desktop, in the Start menu and on the taskbar. That tells it apart from the normal Slack.

**Use Slack (RTL) instead of your normal Slack.** You can pin it to the taskbar: right-click its taskbar icon while it's open, then click **Pin to taskbar**. Unpin the normal Slack so you don't open both. Running both is safe, but you get every notification twice.

### Start it automatically

Slack (RTL) doesn't start when you sign in to Windows unless you ask for it:

1. Turn off the normal Slack's autostart: **Settings → Apps → Startup → Slack → Off**.
2. Open a Command Prompt in the `desktop\windows` folder and run:
   ```
   slack-rtl-desktop.cmd -Startup
   ```

## After Slack updates

Slack updates your normal Slack, not the copy, so Slack (RTL) stays on the version it was built from. When Slack updates (or about once a month), quit Slack (RTL) and double-click **`slack-rtl-desktop.cmd`** again. It rebuilds the copy from the new version and keeps your Slack (RTL) sign-in and settings.

To check whether a rebuild is needed, run this in the `desktop\windows` folder:
```
slack-rtl-desktop.cmd -Status
```

## Uninstall

Quit Slack (RTL), then run this in the `desktop\windows` folder:
```
slack-rtl-desktop.cmd -Uninstall
```
This removes the copy, its profile and its shortcuts (desktop, Start menu and startup) (everything in `%LOCALAPPDATA%\SlackRTL`). Your normal Slack is untouched.

## Troubleshooting

| Problem | Fix |
|---|---|
| `ERROR: Slack is running` | Quit every Slack window from the tray (see step 2), then run the installer again. |
| `ERROR: Your Slack profile was not found` | Open your normal Slack, sign in, quit it, then run the installer again. |
| Slack (RTL) asks you to sign in | Sign in normally. If that fails, quit it and run `slack-rtl-desktop.cmd -RefreshProfile` to copy your sign-in again. |
| Hebrew is not right-aligned | Check that you opened **Slack (RTL)**, not the normal Slack. Then run `-Status`; if it says Slack has updated, run the installer again. |
| Slack (RTL) doesn't start at all | Run `-Status`. If `Integrity check` says `ON`, run the installer again. If it still fails, [open an issue](https://github.com/Avi-E-Koenig/slack-rtl/issues) with the `-Status` output. |
| Clicking a `slack://` link opens the normal Slack | Expected: Windows sends those links to the installed Slack. |

## How it works

1. It copies your installed Slack app to `%LOCALAPPDATA%\SlackRTL\app`. **Your installed Slack is never modified.** The Microsoft Store version is read-only anyway.
2. It adds a few lines to the copy's startup code (inside `resources\app.asar`). They insert [`extension/rtl.css`](../../extension/rtl.css) into every `app.slack.com` page, the same CSS the Chrome extension uses.
3. Slack checks at startup that `app.asar` is unmodified, so the copy would refuse to start. The installer turns that check off in the copy's `slack.exe` only (Electron's `EnableEmbeddedAsarIntegrityValidation` fuse). Nothing else in Slack's security settings changes.
4. On first install it copies your Slack profile to `%LOCALAPPDATA%\SlackRTL\profile`. Windows encrypts the saved sign-in per Windows user, not per app, so the copy can use it. From then on the two profiles are separate, so the normal Slack and Slack (RTL) never write to the same files.
5. It creates **Slack (RTL)** shortcuts on the desktop and in the Start menu that start the copy with that profile. The shortcuts and the window use this project's own icon ([`slack-rtl.ico`](slack-rtl.ico), made from [`icon.svg`](../../extension/icons/icon.svg) by `npm run icons`), not Slack's logo. The notification-area (tray) icon is still Slack's own.

### What to know

- **The copy is no longer the exact program Slack shipped.** Its `slack.exe` doesn't match Slack's original signature, and its integrity check is off. The code it runs is Slack's own plus the CSS injection above. The installer downloads nothing and sends nothing anywhere.
- **The two Slacks have separate settings.** A workspace you add or a preference you change in one doesn't appear in the other.
- **Not covered yet:** notifications, huddles, screen sharing and file transfers *should* work as in the normal app, but haven't been fully tested ([#22](https://github.com/Avi-E-Koenig/slack-rtl/issues/22)).
- **macOS and Linux:** not supported by this installer. macOS needs the app re-signed, which signs you out of Slack.
