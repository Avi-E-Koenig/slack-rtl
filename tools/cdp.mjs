// Attach to the running dev browser and run an inspection module against the Slack tab.
// Usage: npm run cdp -- <script.mjs> [url]
// The script's default export receives (page) and its return value is printed as JSON.
import path from 'node:path';
import { chromium } from 'playwright';
import { CDP_URL } from './config.mjs';

const [script, url] = process.argv.slice(2);
const browser = await chromium.connectOverCDP(CDP_URL);
const pages = browser.contexts()[0].pages();
const page = pages.find(p => p.url().includes('app.slack.com')) ?? pages[0];
if (url) {
  await page.goto(url);
  await page.waitForTimeout(5000);
}
const run = (await import(path.resolve(script))).default;
console.log(JSON.stringify(await run(page), null, 2));
await browser.close(); // detaches CDP only; the browser keeps running
