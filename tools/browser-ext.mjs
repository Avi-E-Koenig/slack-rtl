// Launches Chromium with the unpacked extension (plus extras/ when EXTRAS=1) loaded (the bare binary ignores
// --load-extension). Reuses the login.mjs profile. CDP on 127.0.0.1:9222.
import { chromium } from 'playwright';
import { PROFILE_DIR, EXTENSION_DIR, EXTRAS_DIRS, CDP_ARGS } from './config.mjs';

const dirs = [EXTENSION_DIR, ...(process.env.EXTRAS === '1' ? EXTRAS_DIRS : [])].join(',');

const ctx = await chromium.launchPersistentContext(PROFILE_DIR, {
  headless: false,
  viewport: null,
  ignoreDefaultArgs: ['--enable-automation', '--disable-extensions'],
  args: [...CDP_ARGS, `--disable-extensions-except=${dirs}`, `--load-extension=${dirs}`],
});
const page = ctx.pages()[0] ?? (await ctx.newPage());
await page.goto('https://app.slack.com/client');
console.log('browser up with extension, CDP 127.0.0.1:9222');
ctx.on('close', () => process.exit(0));
