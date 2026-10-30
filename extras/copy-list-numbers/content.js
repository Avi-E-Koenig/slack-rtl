// Slack's own copy handler writes the selection as plain text but drops the
// numbers of ordered lists. Runs after it (window, bubble phase) and puts
// "1. ", "2. ", … back in front of each selected numbered item.
'use strict';

function selectedOrderedItems(selection) {
  const items = [];
  for (let i = 0; i < selection.rangeCount; i++) {
    const range = selection.getRangeAt(i);
    const root = range.commonAncestorContainer.nodeType === Node.ELEMENT_NODE
      ? range.commonAncestorContainer
      : range.commonAncestorContainer.parentElement;
    const scope = root.closest('ol') ? [root.closest('ol')] : [...root.querySelectorAll('ol')];
    for (const ol of scope) {
      const start = ol.start || 1;
      [...ol.children].filter(li => li.tagName === 'LI').forEach((li, idx) => {
        if (range.intersectsNode(li)) items.push({ li, number: start + idx });
      });
    }
  }
  return items;
}

function numberItems(text, items) {
  let from = 0;
  for (const { li, number } of items) {
    const itemText = li.textContent.trim();
    if (!itemText) continue;
    const at = text.indexOf(itemText, from);
    if (at < 0) continue;
    const lineStart = text.lastIndexOf('\n', at) + 1;
    const prefix = `${number}. `;
    if (text.slice(lineStart, at).trim() === '' && !text.startsWith(prefix, at)) {
      text = text.slice(0, at) + prefix + text.slice(at);
      from = at + prefix.length + itemText.length;
    } else {
      from = at + itemText.length;
    }
  }
  return text;
}

window.addEventListener('copy', event => {
  const selection = document.getSelection();
  if (!selection || selection.isCollapsed || !event.clipboardData) return;
  const items = selectedOrderedItems(selection);
  if (!items.length) return;
  const original = event.clipboardData.getData('text/plain') || selection.toString();
  const numbered = numberItems(original, items);
  if (numbered === original) return;
  event.clipboardData.setData('text/plain', numbered);
  event.preventDefault();
});
