// Renders extension/icons/icon.svg to the PNG sizes the stores require.
// Usage: npm run icons
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

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
