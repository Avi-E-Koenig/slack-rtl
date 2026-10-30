// Selector-drift check: counts matches for every selector in rtl.css on the
// current Slack page. A 0 means either the UI isn't on screen (e.g. no quotes in
// view) or Slack renamed it; open a view that has that element to tell which.
// Usage: npm run smoke
import fs from 'node:fs';
import path from 'node:path';
import { EXTENSION_DIR } from './config.mjs';

const css = fs.readFileSync(path.join(EXTENSION_DIR, 'rtl.css'), 'utf8').replace(/\/\*[\s\S]*?\*\//g, '');
const selectors = [...new Set([...css.matchAll(/([^{}]+)\{/g)]
  .flatMap(m => m[1].split(','))
  .map(s => s.trim().replace(/::?(before|after|marker)$/, ''))
  .filter(Boolean))];

export default page => page.evaluate(sels => Object.fromEntries(sels.map(s => [s, document.querySelectorAll(s).length])), selectors);
