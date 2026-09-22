import Anthropic from "@anthropic-ai/sdk";
import { LANG_NAME } from "./lang.js";

// Every object must list all its keys in `required` and set additionalProperties: false.
const obj = (properties) => ({
  type: "object",
  additionalProperties: false,
  required: Object.keys(properties),
  properties,
});
const str = (description) => ({ type: "string", description });

const SEGMENTS = {
  type: "array",
  description:
    "The study-language text split into pieces. Concatenating every `text` must reproduce the text exactly. " +
    "For Japanese, each piece containing kanji gets its hiragana reading (okurigana split off into its own piece); kana, Latin, and punctuation pieces get an empty reading. " +
    "For Korean, use an empty reading unless the piece is hanja, in which case give the hangul reading.",
  items: obj({ text: str("Surface text"), reading: str("Hiragana/hangul reading, or empty string") }),
};

const PASSAGE = obj({
  text: str("The text in the study language (Japanese or Korean)"),
  segments: SEGMENTS,
  romanization: str("Modified Hepburn for Japanese, Revised Romanization for Korean"),
  english: str("Natural English meaning"),
});

export const SCHEMA = obj({
  selection: PASSAGE,
  sentence: PASSAGE,
  vocabulary: {
    type: "array",
    description: "Key words, up to 8, most useful first. Selection words first, then notable words from the sentence.",
    items: obj({
      word: str("Dictionary/base form in the study language"),
      as_used: str("The form as it appears in the text (same as word if unchanged)"),
      reading: str("Hiragana reading of `word` for Japanese (empty if `word` is all kana); for Korean empty unless `word` contains hanja"),
      romanization: str("Romanization of `word`"),
      meaning: str("Concise English gloss"),
      part_of_speech: str("e.g. noun, godan verb, i-adjective, particle, 하다 verb"),
    }),
  },
  grammar_points: {
    type: "array",
    description: "1–4 grammar points that actually appear in the sentence, most important first.",
    items: obj({
      pattern: str("The pattern as learners would look it up, e.g. 〜ている, -(으)니까"),
      explanation: str("1–3 sentence English explanation of what it does here"),
      example: str("The excerpt from the sentence that uses it"),
    }),
  },
  notes: str("Optional: nuance, politeness level, alternatives, cultural notes. Empty string if nothing useful."),
});

const SYSTEM = `You are KotoLens, a precise Japanese and Korean tutor embedded in a browser extension.
The learner highlighted text on a web page. You receive the highlighted selection plus the sentence and paragraph around it so you can resolve ambiguity (word sense, omitted subjects, politeness, homographs) the way a native speaker reading the page would.

Always answer in the JSON schema provided. Fields named "text" and "segments" are always in the study language; "english" is always English.
- Readings must fit the context (e.g. 今日 → きょう vs こんにち, 行った → いった/おこなった). Use hiragana for Japanese readings, even for katakana-origin words that contain kanji.
- Keep segments tight: one segment per kanji compound with its reading, okurigana as a separate reading-less segment, so furigana sits only over kanji.
- Grammar points and vocabulary must come from the actual text, pitched at an intermediate learner. Explanations are in English.
- If the selection is only part of a word, explain the whole word.
- Never add commentary outside the JSON.`;

function userPrompt({ plan, selection, sentence, paragraph, pageTitle }) {
  const study = LANG_NAME[plan.studyLanguage];
  const task =
    plan.direction === "explain"
      ? `The selection is ${study}. Explain it: selection.text is the selection itself, sentence.text is the full ${study} sentence containing it, and both get English meanings.`
      : `The selection is not ${study}. Translate it into natural ${study} that fits the context: selection.text is your ${study} translation of the selection, sentence.text is your ${study} translation of the whole sentence, and each "english" field restates the original meaning in English. Choose politeness to match the source's register.`;
  return [
    `Study language: ${study}`,
    `Task: ${task}`,
    pageTitle ? `Page title: ${pageTitle}` : "",
    `<selection>${selection}</selection>`,
    `<sentence>${sentence || selection}</sentence>`,
    paragraph && paragraph !== sentence ? `<paragraph>${paragraph}</paragraph>` : "",
  ]
    .filter(Boolean)
    .join("\n\n");
}

class KotoLensError extends Error {
  constructor(message, code) {
    super(message);
    this.code = code;
  }
}

export async function analyze({ settings, plan, selection, sentence, paragraph, pageTitle }) {
  const client = new Anthropic({
    apiKey: settings.apiKey,
    // Keys are user-supplied and stored locally; calls go straight from the extension to Anthropic.
    dangerouslyAllowBrowser: true,
    maxRetries: 2,
  });

  const params = {
    model: settings.model,
    max_tokens: 16000,
    system: SYSTEM,
    messages: [{ role: "user", content: userPrompt({ plan, selection, sentence, paragraph, pageTitle }) }],
    output_config: { format: { type: "json_schema", schema: SCHEMA } },
  };
  // Haiku 4.5 doesn't accept effort; the others do.
  if (settings.model !== "claude-haiku-4-5") params.output_config.effort = settings.effort;

  let response;
  try {
    response =
      settings.model === "claude-opus-5"
        ? await client.beta.messages.create({
            ...params,
            betas: ["server-side-fallback-2026-07-01"],
            fallbacks: "default",
          })
        : await client.messages.create(params);
  } catch (err) {
    throw toFriendlyError(err);
  }

  if (response.stop_reason === "refusal") {
    throw new KotoLensError("Claude declined to analyze this text.", "refusal");
  }
  if (response.stop_reason === "max_tokens") {
    throw new KotoLensError("The selection is too long — try highlighting a shorter passage.", "too_long");
  }
  const text = response.content
    .filter((b) => b.type === "text")
    .map((b) => b.text)
    .join("");
  try {
    return JSON.parse(text);
  } catch {
    throw new KotoLensError("Got an unexpected response from Claude. Please try again.", "bad_json");
  }
}

function toFriendlyError(err) {
  if (err instanceof Anthropic.AuthenticationError) {
    return new KotoLensError("Your Anthropic API key was rejected. Check it in KotoLens settings.", "bad_key");
  }
  if (err instanceof Anthropic.PermissionDeniedError) {
    return new KotoLensError("This API key doesn't have access to the selected model. Try another model in settings.", "forbidden");
  }
  if (err instanceof Anthropic.NotFoundError) {
    return new KotoLensError("The selected model isn't available on your account. Pick another model in settings.", "not_found");
  }
  if (err instanceof Anthropic.RateLimitError) {
    return new KotoLensError("Rate limited by the Anthropic API — wait a moment and try again.", "rate_limit");
  }
  if (err instanceof Anthropic.APIConnectionError) {
    return new KotoLensError("Couldn't reach the Anthropic API. Check your connection.", "network");
  }
  if (err instanceof Anthropic.APIError) {
    return new KotoLensError(`Anthropic API error (${err.status ?? "?"}): ${err.message}`, "api");
  }
  return err;
}
