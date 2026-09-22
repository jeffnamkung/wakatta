# KotoLens Privacy Policy

_Last updated: September 22, 2026_

KotoLens is a browser extension that helps you read and learn Japanese and Korean. This policy explains what data it handles.

## What KotoLens sends, and when

KotoLens sends data only when you choose a KotoLens menu item, press its keyboard shortcut, or use the lookup box in its toolbar popup. It then sends the following directly from your browser to Anthropic's API (`api.anthropic.com`):

- the text you highlighted or typed
- the sentence and up to about 1,400 characters of the paragraph around it, so the translation fits the context
- the title of the page

Anthropic processes this data under its own terms and privacy policy, which apply to your API key: https://www.anthropic.com/legal/privacy

KotoLens has no servers. It does not collect analytics, track your browsing, or read pages you haven't asked it to translate.

## What KotoLens stores on your device

- **Your Anthropic API key**, in `chrome.storage.local`. It stays on this device and is sent only to `api.anthropic.com`.
- **Your flashcards**, in `chrome.storage.local`. Each card holds the word, its reading, meaning, example sentence, and the URL and title of the page you saved it from.
- **Your preferences** (model, furigana and romanization toggles, speaking speed, voices), in `chrome.storage.sync`. If Chrome sync is on, Google syncs these to your other Chrome browsers. Your API key and flashcards are never synced.

To delete all of this, remove the extension or delete your cards on its flashcards page.

## Text-to-speech

The 🔊 buttons use Chrome's built-in `chrome.tts` API. Depending on the voice you pick, your operating system or Google may process the spoken text.

## Sharing

KotoLens does not sell or share your data, and does not use it for anything other than the features described above.

## Contact

Questions or bug reports: [jeffnamkung@gmail.com](mailto:jeffnamkung@gmail.com)
