// Launches Chromium via Playwright with the unpacked extension loaded (the bare
// binary ignores --load-extension). Reuses the browser.sh profile, so log in via
// browser.sh first if Google SSO is needed. CDP on :9222 for tools/cdp.mjs.
import { createRequire } from 'node:module';
import path from 'node:path';
const require = createRequire(import.meta.url);
const { chromium } = require(path.join(process.env.NPM_GLOBAL, 'playwright'));

const root = new URL('..', import.meta.url).pathname;
const ext = path.join(root, 'extension');
const ctx = await chromium.launchPersistentContext(path.join(root, '.pw-profile'), {
  headless: false,
  viewport: null,
  ignoreDefaultArgs: ['--enable-automation', '--disable-extensions'],
  args: ['--remote-debugging-port=9222', `--disable-extensions-except=${ext}`, `--load-extension=${ext}`],
});
const page = ctx.pages()[0] ?? (await ctx.newPage());
await page.goto('https://app.slack.com/client');
console.log('browser up with extension, CDP :9222');
ctx.on('close', () => process.exit(0));
