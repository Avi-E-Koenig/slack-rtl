// Offline test for the opt-in extras/copy-list-numbers add-on: a stand-in for
// Slack's copy handler writes the list without numbers; the add-on must restore them.
import { describe, test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { chromium, firefox } from 'playwright';

const SCRIPT = fs.readFileSync(new URL('../extras/copy-list-numbers/content.js', import.meta.url), 'utf8');
const PAGE = `<!doctype html><meta charset="utf-8"><body>
<div class="p-rich_text_section" id="intro">מה אני צריך ממך:</div>
<ol class="p-rich_text_list p-rich_text_list__ordered"><li>ריוויו מהיר ל-PR</li><li>מפתח ישן</li><li>third item</li></ol>
<div class="p-rich_text_section" id="outro">סוף</div>
<script>
  // Stand-in for Slack's handler (document, bubble): plain text, one line per block, no numbers.
  document.addEventListener('copy', e => {
    const s = document.getSelection(), r = s.getRangeAt(0), lines = [];
    for (const el of document.querySelectorAll('#intro, li, #outro')) if (r.intersectsNode(el)) lines.push(el.textContent);
    e.clipboardData.setData('text/plain', lines.join('\\n'));
    e.preventDefault();
  });
  window.copySelection = (startSel, endSel) => {
    const r = document.createRange();
    r.setStartBefore(document.querySelector(startSel)); r.setEndAfter(document.querySelector(endSel));
    const s = document.getSelection(); s.removeAllRanges(); s.addRange(r);
    // Read inside the event: Firefox protects the DataTransfer once dispatch ends.
    let out = null;
    const grab = e => { out = e.clipboardData.getData('text/plain'); };
    window.addEventListener('copy', grab); // registered after the add-on's listener, so it runs last
    document.body.dispatchEvent(new ClipboardEvent('copy', { clipboardData: new DataTransfer(), bubbles: true, cancelable: true }));
    window.removeEventListener('copy', grab);
    return out;
  };
</script>`;

for (const engine of [chromium, firefox]) describe(engine.name(), () => {
  let browser, page;
  before(async () => {
    browser = await engine.launch();
    page = await browser.newPage();
    await page.setContent(PAGE);
    await page.addScriptTag({ content: SCRIPT });
  });
  after(() => browser?.close());

  test('whole message: numbers restored on list lines only', async () => {
    const text = await page.evaluate(() => copySelection('#intro', '#outro'));
    assert.equal(text, 'מה אני צריך ממך:\n1. ריוויו מהיר ל-PR\n2. מפתח ישן\n3. third item\nסוף');
  });

  test('partial selection keeps each item\'s real number', async () => {
    const text = await page.evaluate(() => copySelection('li:nth-child(2)', 'li:nth-child(3)'));
    assert.equal(text, '2. מפתח ישן\n3. third item');
  });

  test('no ordered list selected: Slack\'s text untouched', async () => {
    const text = await page.evaluate(() => copySelection('#outro', '#outro'));
    assert.equal(text, 'סוף');
  });
});
