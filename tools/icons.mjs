// Renders extension/icons/icon.svg to the PNG sizes the stores require, and to
// desktop/windows/slack-rtl.ico for the Windows desktop shortcuts.
// Usage: npm run icons
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const dir = new URL('../extension/icons/', import.meta.url).pathname;
const icoPath = new URL('../desktop/windows/slack-rtl.ico', import.meta.url).pathname;
const svg = fs.readFileSync(path.join(dir, 'icon.svg'), 'utf8');
const browser = await chromium.launch();

async function render(size) {
  const page = await browser.newPage({ viewport: { width: size, height: size } });
  await page.setContent(`<style>*{margin:0}svg{width:${size}px;height:${size}px;display:block}</style>${svg}`);
  const png = await page.screenshot({ omitBackground: true });
  await page.close();
  return png;
}

for (const size of [16, 32, 48, 128]) {
  fs.writeFileSync(path.join(dir, `icon-${size}.png`), await render(size));
}

// ICO with embedded PNG images (supported since Windows Vista).
const icoSizes = [16, 24, 32, 48, 64, 128, 256];
const images = [];
for (const size of icoSizes) images.push(await render(size));
const header = Buffer.alloc(6 + 16 * images.length);
header.writeUInt16LE(0, 0); // reserved
header.writeUInt16LE(1, 2); // type: icon
header.writeUInt16LE(images.length, 4);
let offset = header.length;
images.forEach((png, i) => {
  const e = 6 + 16 * i;
  const size = icoSizes[i];
  header.writeUInt8(size >= 256 ? 0 : size, e); // width (0 = 256)
  header.writeUInt8(size >= 256 ? 0 : size, e + 1); // height
  header.writeUInt8(0, e + 2); // palette colors
  header.writeUInt8(0, e + 3); // reserved
  header.writeUInt16LE(1, e + 4); // color planes
  header.writeUInt16LE(32, e + 6); // bits per pixel
  header.writeUInt32LE(png.length, e + 8);
  header.writeUInt32LE(offset, e + 12);
  offset += png.length;
});
fs.writeFileSync(icoPath, Buffer.concat([header, ...images]));

await browser.close();
console.log('icons written to', dir, 'and', icoPath);
