# Store listing (Chrome Web Store / Firefox Add-ons)

Copy-paste source for both stores. Keep it in sync with the README.

## Name
Slack RTL: Hebrew support | תמיכה בעברית

## Summary (≤ 132 chars, one language)
HE: מתקן עברית וטקסט מימין לשמאל ב-Slack בדפדפן. CSS בלבד: בלי הרשאות, בלי סקריפטים, בלי איסוף מידע.

EN: Fixes Hebrew and other right-to-left text in the Slack web app. CSS only: no permissions, no scripts, no data collection.

## Category
Chrome: Productivity (Workflow & Planning). AMO: Language Support.

## Description
Without `_locales` in the manifest the stores show a single description, so paste both languages into one field, Hebrew first. Plain text only (no Markdown).

```
מתקן את התצוגה של עברית (וכל שפה שנכתבת מימין לשמאל) ב-Slack בדפדפן (app.slack.com).

Slack מזהה טקסט מימין לשמאל, ובכל זאת מצמיד אותו לשמאל. התוסף מתקן את זה:

• הודעות בעברית מיושרות לימין, וכל שורה מקבלת כיוון משלה, כך שהודעות שמשלבות עברית ואנגלית נקראות נכון
• ברשימות (תבליטים ומספרים) ובציטוטים, הסימונים מופיעים בצד הנכון
• קוד, קישורים ותיוגי @ שומרים על הסדר שלהם בתוך טקסט בעברית
• בלוקים של קוד נשארים משמאל לימין
• בתיבת ההודעה, בתגובות בשרשור ובעריכת הודעה, כל שורה מקבלת את הכיוון הנכון תוך כדי הקלדה
• ב-Canvas: פסקאות, סימוני רשימות ותיבות סימון לפי שפת הפריט
• בסרגל הצד: התווית "guest" כבר לא קופצת לפני שמות בעברית
• עובד בשרשורים, בתוצאות חיפוש, ובערכת נושא בהירה וכהה

פרטיות: התוסף הוא גיליון סגנונות (CSS) אחד בלבד. הוא לא מבקש הרשאות, לא מריץ סקריפטים, ולא אוסף או שולח שום מידע.

עובד ב-Slack בדפדפן בלבד. אפליקציית הדסקטופ של Slack לא תומכת בתוספים, אבל אפשר להתקין את Slack מ-Chrome כחלון אפליקציה (בתפריט ⋮ בוחרים "Cast, save and share" ואז "Install page as app"), והתוסף עובד שם.

קוד פתוח (MIT), ונשמח ל-PRs: https://github.com/Avi-E-Koenig/slack-rtl

לא קשור ל-Slack Technologies ולא מאושר על ידה.

────────────

Fixes Hebrew (and other right-to-left) text in the Slack web app (app.slack.com).

Slack detects right-to-left text, then forces it to the left anyway. This extension fixes that:

• Hebrew messages align right; each line picks its own direction, so mixed Hebrew/English messages read correctly
• Bulleted and numbered lists and quotes put their markers on the correct side
• Inline code, links and @mentions keep their order inside Hebrew text
• Code blocks stay left-to-right
• The message box, thread replies and message editing get the right direction per line as you type
• Canvases: paragraphs and list/checklist markers follow each item's language
• Sidebar: the "guest" label no longer jumps in front of Hebrew names
• Works in threads, search results, light and dark themes

Privacy: the extension is a single stylesheet. It requests no permissions, runs no scripts, and collects or sends no data.

Web app only. The Slack desktop app can't load extensions, but you can install Slack from Chrome as an app window (⋮ → "Cast, save and share" → "Install page as app") and the extension works there.

Open source (MIT), and PRs are welcome: https://github.com/Avi-E-Koenig/slack-rtl

Not affiliated with or endorsed by Slack Technologies.
```

## Privacy / data-use answers
- Single purpose: improve display of right-to-left text on app.slack.com.
- Permissions requested: none. Host access: content-script match `https://app.slack.com/*` only (to apply the stylesheet).
- Remote code: none.
- Data collected: none (Chrome "data usage" form: tick nothing; certify compliance). AMO: `data_collection_permissions: none` is declared in the manifest.

## Assets
- Icon: `extension/icons/icon-128.png`
- Screenshots (1280×800 or 640×400): **test content only**. No real workspace names, people or messages. Suggested shots: before/after of a Hebrew message with a list; composer with mixed lines; canvas with a Hebrew checklist.
- Small promo tile (440×280): optional.

## Release checklist
- [ ] Chrome Web Store developer account (one-time $5) — owner
- [ ] Firefox Add-ons (AMO) account (free) — owner
- [ ] Screenshots from a test workspace
- [ ] `npm run package` → upload `dist/slack-rtl-<version>.zip` (AMO: same zip; source is the repo)
- [ ] Optional add-on `extras/copy-list-numbers` as a second listing (declares a content script; same privacy answers, "no data collected")
- [ ] Add store links to the README install section
