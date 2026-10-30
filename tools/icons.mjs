// Renders extension/icons/icon.svg to the PNG sizes the stores require.
// Usage: NPM_GLOBAL=$(npm root -g) node tools/icons.mjs
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require = createRequire(import.meta.url);
const { chromium } = require(path.join(process.env.NPM_GLOBAL, 'playwright'));

const dir = new URL('../extension/icons/', import.meta.url).pathname;
const svg = fs.readFileSync(path.join(dir, 'icon.svg'), 'utf8');
const browser = await chromium.launch();
for (const size of [16, 32, 48, 128]) {
  const page = await browser.newPage({ viewport: { width: size, height: size } });
  await page.setContent(`<style>*{margin:0}svg{width:${size}px;height:${size}px;display:block}</style>${svg}`);
  await page.screenshot({ path: path.join(dir, `icon-${size}.png`), omitBackground: true });
  await page.close();
}
await browser.close();
console.log('icons written to', dir);
