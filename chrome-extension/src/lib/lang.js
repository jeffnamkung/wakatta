const HANGUL = /[ᄀ-ᇿ㄰-㆏가-힯]/;
const KANA = /[぀-ヿㇰ-ㇿｦ-ﾟ]/;
const KANJI = /[㐀-䶿一-鿿豈-﫿]/;

export const LANG_NAME = { ja: "Japanese", ko: "Korean", en: "English" };
export const TTS_LANG = { ja: "ja-JP", ko: "ko-KR", en: "en-US" };

/** Best-effort script detection: "ko", "ja", or "other". */
export function detectScript(text) {
  if (HANGUL.test(text)) return "ko";
  if (KANA.test(text) || KANJI.test(text)) return "ja";
  return "other";
}

/**
 * Decide what we're studying and in which direction.
 *  - studyLanguage: the Japanese/Korean side we show readings, audio, and grammar for.
 *  - direction: "explain" when the selection is already in that language, "translate" otherwise.
 */
export function planRequest(selection, target, defaultStudy = "ja") {
  const script = detectScript(selection);
  if (target === "en") {
    if (script === "ja" || script === "ko") return { studyLanguage: script, direction: "explain" };
    return { studyLanguage: defaultStudy, direction: "translate" };
  }
  return { studyLanguage: target, direction: script === target ? "explain" : "translate" };
}
