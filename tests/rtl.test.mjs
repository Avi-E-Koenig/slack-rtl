// Offline regression tests: render Slack-shaped fixtures with rtl.css injected
// *before* the Slack base rules (as Chrome does for content scripts) and assert
// on rendered geometry, not just computed styles.
import { describe, test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { chromium, firefox } from 'playwright';

const read = p => fs.readFileSync(new URL(p, import.meta.url), 'utf8');
const RTL_CSS = read('../extension/rtl.css');
const SLACK_CSS = read('./fixtures/slack-base.css');
const FIXTURE = read('./fixtures/slack.html');

// Same suite in Blink (Chrome) and Gecko (Firefox).
for (const engine of [chromium, firefox]) describe(engine.name(), () => {
  let browser, fixed, stock;

  async function render(withExtension) {
    const page = await browser.newPage();
    const ext = withExtension ? `<style>${RTL_CSS}</style>` : '';
    await page.setContent(`<!doctype html><meta charset="utf-8">${ext}<style>${SLACK_CSS}</style><body>${FIXTURE}</body>`);
    // Geometry helpers: rect of a whole element's text, or of one character.
    await page.evaluate(() => {
      window.textRect = el => { const r = document.createRange(); r.selectNodeContents(el); return r.getBoundingClientRect(); };
      window.charX = (el, ch) => {
        const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
        for (let n; (n = walker.nextNode());) {
          const i = n.data.indexOf(ch);
          if (i >= 0) { const r = document.createRange(); r.setStart(n, i); r.setEnd(n, i + ch.length); return r.getBoundingClientRect().left; }
        }
        throw new Error(`"${ch}" not found`);
      };
      window.edges = sel => {
        const el = document.querySelector(sel), box = el.getBoundingClientRect(), t = textRect(el);
        return { gapLeft: t.left - box.left, gapRight: box.right - t.right };
      };
    });
    return page;
  }

  const NEAR = 2; // px tolerance for "flush against the edge"

  before(async () => {
    browser = await engine.launch();
    [fixed, stock] = await Promise.all([render(true), render(false)]);
  });
  after(() => browser?.close());

  test('fixtures reproduce the stock Slack bugs (control)', async () => {
    const he = await stock.evaluate(() => edges('#he .p-rich_text_section'));
    assert.ok(he.gapLeft < NEAR, 'stock Slack left-aligns Hebrew');
    const order = await stock.evaluate(() => { const c = document.querySelectorAll('#code code')[1]; return charX(c, '1') > charX(c, 't'); });
    assert.ok(order, 'stock Slack renders `1 to add` as "to add 1"');
  });

  test('Hebrew-only message aligns right', async () => {
    const e = await fixed.evaluate(() => edges('#he .p-rich_text_section'));
    assert.ok(e.gapRight < NEAR && e.gapLeft > NEAR, JSON.stringify(e));
  });

  test('English-only message stays left-aligned', async () => {
    const e = await fixed.evaluate(() => edges('#en .p-rich_text_section'));
    assert.ok(e.gapLeft < NEAR && e.gapRight > NEAR, JSON.stringify(e));
  });

  test('<br>-separated lines align independently', async () => {
    const [l1, l2, l3] = await fixed.evaluate(() => {
      const box = document.querySelector('#mixed .p-rich_text_section').getBoundingClientRect();
      return [...document.querySelectorAll('#mixed .l')].map(s => { const r = s.getBoundingClientRect(); return { gapLeft: r.left - box.left, gapRight: box.right - r.right }; });
    });
    assert.ok(l1.gapRight < NEAR, `Hebrew line 1 right: ${JSON.stringify(l1)}`);
    assert.ok(l2.gapLeft < NEAR, `English line 2 left: ${JSON.stringify(l2)}`);
    assert.ok(l3.gapRight < NEAR, `Hebrew line 3 right: ${JSON.stringify(l3)}`);
  });

  test('inline code keeps its internal order inside Hebrew', async () => {
    const ok = await fixed.evaluate(() => { const c = document.querySelectorAll('#code code')[1]; return charX(c, '1') < charX(c, 't') && charX(c, 't') < charX(c, 'a'); });
    assert.ok(ok, '`1 to add` must read left-to-right');
  });

  test('@mention keeps the @ before the name', async () => {
    const ok = await fixed.evaluate(() => { const m = document.querySelector('#mention a'); return charX(m, '@') < charX(m, 'T'); });
    assert.ok(ok);
  });

  test('link text keeps its internal order', async () => {
    const ok = await fixed.evaluate(() => { const a = document.querySelector('#link a'); return charX(a, 'PR') < charX(a, '#') && charX(a, '#') < charX(a, '822'); });
    assert.ok(ok, '"PR #822" must read left-to-right');
  });

  test('bulleted list: items and bullets on the right', async () => {
    const r = await fixed.evaluate(() => ({
      dir: getComputedStyle(document.querySelector('#bullets li')).direction,
      gaps: [...document.querySelectorAll('#bullets li')].map(li => { const b = li.getBoundingClientRect(), t = textRect(li); return { gapLeft: t.left - b.left, gapRight: b.right - t.right }; }),
    }));
    assert.equal(r.dir, 'rtl');
    for (const g of r.gaps) assert.ok(g.gapLeft > g.gapRight, `item pushed right: ${JSON.stringify(g)}`);
  });

  test('numbered list: items on the right next to their numbers', async () => {
    const gaps = await fixed.evaluate(() => [...document.querySelectorAll('#ordered li')].map(li => { const b = li.getBoundingClientRect(), t = textRect(li); return { gapLeft: t.left - b.left, gapRight: b.right - t.right }; }));
    for (const g of gaps) assert.ok(g.gapRight < 12 && g.gapLeft > g.gapRight, JSON.stringify(g));
  });

  test('quote bar sits on the text-start (right) side', async () => {
    const r = await fixed.evaluate(() => {
      const q = document.querySelector('#quote blockquote'), b = getComputedStyle(q, '::before');
      return { right: b.right, padStart: getComputedStyle(q).paddingRight, padEnd: getComputedStyle(q).paddingLeft };
    });
    assert.equal(r.right, '0px');
    assert.equal(r.padStart, '16px');
    assert.equal(r.padEnd, '0px', 'Slack\'s padding-left must be cleared');
  });

  test('code block stays LTR', async () => {
    const r = await fixed.evaluate(() => ({ dir: getComputedStyle(document.querySelector('#pre pre')).direction, ...edges('#pre pre') }));
    assert.equal(r.dir, 'ltr');
  });

  test('composer: each paragraph takes its own direction', async () => {
    const r = await fixed.evaluate(() => {
      const [p1, p2, p3] = document.querySelectorAll('#composer p');
      const g = p => { const b = p.getBoundingClientRect(), t = textRect(p); return { gapLeft: t.left - b.left, gapRight: b.right - t.right }; };
      return { p1: g(p1), p2: g(p2), p3: g(p3), periodLast: charX(p2, '.') > charX(p2, 'E') };
    });
    assert.ok(r.p1.gapRight < NEAR, JSON.stringify(r.p1));
    assert.ok(r.p2.gapLeft < NEAR, JSON.stringify(r.p2));
    assert.ok(r.p3.gapRight < NEAR, JSON.stringify(r.p3));
    assert.ok(r.periodLast, 'English period stays at the end');
  });

  test('canvas: paragraphs take their own direction', async () => {
    const r = await fixed.evaluate(() => ({ he: edges('#cv-he .content'), en: edges('#cv-en .content') }));
    assert.ok(r.he.gapRight < NEAR && r.he.gapLeft > NEAR, `Hebrew right: ${JSON.stringify(r.he)}`);
    assert.ok(r.en.gapLeft < NEAR, `English left: ${JSON.stringify(r.en)}`);
  });

  test('canvas: list marker on the text-start side, with a gap', async () => {
    const side = await fixed.evaluate(() => Object.fromEntries(['he', 'en'].map(k => {
      const li = document.getElementById(`cv-li-${k}`);
      const box = li.querySelector('.list-item-marker-container').getBoundingClientRect();
      const glyph = li.querySelector('.pseudo-before').getBoundingClientRect(); // the bullet itself, excluding padding
      const t = textRect(li.querySelector('.content'));
      return [k, { markerRight: (box.left + box.right) / 2 > (t.left + t.right) / 2, gap: Math.max(t.left - glyph.right, glyph.left - t.right), textGapRight: li.getBoundingClientRect().right - box.right }];
    })));
    assert.ok(side.he.markerRight, 'Hebrew item: marker on the right');
    assert.ok(side.he.textGapRight < NEAR, 'Hebrew item flush right');
    assert.ok(side.he.gap >= 3, `gap between marker and Hebrew text: ${side.he.gap}`);
    assert.ok(!side.en.markerRight, 'English item: marker on the left');
  });

  test('sidebar: guest label follows the Hebrew name', async () => {
    const r = await fixed.evaluate(() => {
      const [name, label] = document.querySelectorAll('#sidebar .p-channel_sidebar__name > span');
      return { name: name.getBoundingClientRect(), label: label.getBoundingClientRect() };
    });
    assert.ok(r.label.left > r.name.right, 'label right of the name, with its gap');
  });
});
