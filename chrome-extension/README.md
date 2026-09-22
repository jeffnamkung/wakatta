# KotoLens: Japanese & Korean Reader (Chrome extension)

Highlight text on any web page, right-click, and KotoLens will:

- **Translate English → Japanese or Korean** in context
- **Explain Japanese or Korean in English**, with the full sentence it came from
- Show **furigana** over kanji (toggle with あ) and **romanization** (toggle with Aa)
- Read it aloud with Chrome's built-in **text-to-speech** (🔊 on every line and word)
- Break down **vocabulary** and **grammar points** using the surrounding sentence/paragraph
- Save words or phrases to **flashcards** (＋) and review them with spaced repetition
- Export cards to **Anki** (CSV with furigana HTML) or back up/restore as JSON

The translations come from Claude via the Anthropic API. Each user brings their own API key, which is stored only in their browser.

## Develop

```bash
npm install
npm run icons     # regenerate icons (needs Python + Pillow)
npm run build     # outputs the unpacked extension to dist/
npm test
```

Load it in Chrome: open `chrome://extensions`, turn on **Developer mode**, click **Load unpacked**, and pick the `dist/` folder. Then open the extension's settings and paste your key from https://console.anthropic.com/settings/keys.

`npm run watch` rebuilds on save; click the reload icon on the extension card afterwards.

## How it works

| Piece | File |
|---|---|
| Context menu, API calls, text-to-speech, badge | `src/background.js` |
| Selection + sentence/paragraph capture | `src/lib/context.js` |
| In-page popup (Shadow DOM, injected on click via `activeTab`) | `src/content.js` |
| Result view (furigana ruby, audio, vocab, grammar, ＋ card) | `src/lib/render.js`, `src/lib/view.css` |
| Prompt + JSON schema (structured outputs) | `src/lib/claude.js` |
| Flashcards + SM-2-style scheduler | `src/lib/cards.js`, `src/pages/review.*` |
| Toolbar popup, settings, standalone panel | `src/pages/` |

Design choices:
- **No `<all_urls>` permission.** The content script is injected only when you click a KotoLens menu item (`activeTab` + `scripting`). This makes the Web Store review simpler, and users see no "read all your data" warning.
- **Structured outputs.** Claude returns JSON that matches `SCHEMA`: segments with readings (so furigana sits only over kanji), romanization, English, vocabulary, and grammar points. Model output is inserted with DOM text nodes, never `innerHTML`.
- **Default model is Claude Opus 5 at low effort**, with server-side refusal fallbacks enabled. Users can switch to Sonnet 5 or Haiku 4.5 in settings for faster, cheaper lookups.
- Pages where scripts can't run (chrome://, the Web Store, the PDF viewer) open the result in a small standalone window instead.

## Publish

See [store/PUBLISHING.md](store/PUBLISHING.md).
