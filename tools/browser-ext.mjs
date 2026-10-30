// Launches Chromium with the unpacked extension loaded (the bare binary ignores
// --load-extension). Reuses the login.mjs profile. CDP on 127.0.0.1:9222.
import { chromium } from 'playwright';
import { PROFILE_DIR, EXTENSION_DIR, CDP_ARGS } from './config.mjs';

const ctx = await chromium.launchPersistentContext(PROFILE_DIR, {
  headless: false,
  viewport: null,
  ignoreDefaultArgs: ['--enable-automation', '--disable-extensions'],
  args: [...CDP_ARGS, `--disable-extensions-except=${EXTENSION_DIR}`, `--load-extension=${EXTENSION_DIR}`],
});
const page = ctx.pages()[0] ?? (await ctx.newPage());
await page.goto('https://app.slack.com/client');
console.log('browser up with extension, CDP 127.0.0.1:9222');
ctx.on('close', () => process.exit(0));
