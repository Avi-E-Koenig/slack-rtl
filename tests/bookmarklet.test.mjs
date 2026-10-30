// The desktop sign-in bookmarklet must pull appUrl out of Slack's
// /ssb/signin_redirect page (shape captured 2026-10) and copy it.
import { describe, test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { chromium, firefox } from 'playwright';

const BOOKMARKLET = fs.readFileSync(new URL('../desktop/windows/copy-slack-link.bookmarklet.js', import.meta.url), 'utf8').trim();
const LINK = 'slack://T00000000/magic-login/123-abc?id=1';
const props = JSON.stringify({ teamName: 'TEST', appUrl: LINK, webUrl: '' }).replace(/\//g, '\\/'); // Slack escapes slashes
const PAGE = `<!doctype html><meta charset="utf-8"><div id="page_contents"><div id="props_node" data-props="${props.replace(/"/g, '&quot;')}"></div></div>`;

for (const engine of [chromium, firefox]) describe(engine.name(), () => {
  let browser, page;
  before(async () => { browser = await engine.launch(); page = await browser.newPage(); });
  after(() => browser?.close());

  async function run(html) {
    await page.setContent(html);
    return page.evaluate(code => new Promise(resolve => {
      const out = { copied: null, alert: null };
      Object.defineProperty(navigator, 'clipboard', { value: { writeText: t => { out.copied = t; return Promise.resolve(); } }, configurable: true });
      window.alert = m => { out.alert = m; resolve(out); };
      window.prompt = () => resolve(out);
      new Function(decodeURIComponent(code.replace(/^javascript:/, '')))();
    }), BOOKMARKLET);
  }

  test('copies the magic-login appUrl from the signin_redirect page', async () => {
    const r = await run(PAGE);
    assert.equal(r.copied, LINK);
  });

  test('refuses on other pages', async () => {
    const r = await run('<!doctype html><p>not slack</p>');
    assert.equal(r.copied, null);
    assert.match(r.alert, /No Slack sign-in link/);
  });
});
