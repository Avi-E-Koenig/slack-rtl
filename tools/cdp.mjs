// Attach to the browser from browser.sh and run an inspection module against the Slack tab.
// Usage: NPM_GLOBAL=$(npm root -g) node tools/cdp.mjs <script.mjs> [url]
// The script's default export receives (page) and its return value is printed as JSON.
import { createRequire } from 'node:module';
import path from 'node:path';
const require = createRequire(import.meta.url);
const { chromium } = require(path.join(process.env.NPM_GLOBAL, 'playwright'));

const [script, url] = process.argv.slice(2);
const browser = await chromium.connectOverCDP('http://localhost:9222');
const pages = browser.contexts()[0].pages();
const page = pages.find(p => p.url().includes('app.slack.com')) ?? pages[0];
if (url) {
  await page.goto(url);
  await page.waitForTimeout(5000);
}
const run = (await import(path.resolve(script))).default;
console.log(JSON.stringify(await run(page), null, 2));
await browser.close(); // detaches CDP only; the browser keeps running
