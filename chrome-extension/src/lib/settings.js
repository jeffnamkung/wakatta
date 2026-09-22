export const MODELS = [
  { id: "claude-opus-5", label: "Claude Opus 5 (best quality)" },
  { id: "claude-sonnet-5", label: "Claude Sonnet 5 (faster, cheaper)" },
  { id: "claude-haiku-4-5", label: "Claude Haiku 4.5 (fastest, cheapest)" },
];

export const DEFAULTS = {
  apiKey: "",
  model: "claude-opus-5",
  effort: "low",
  defaultStudyLanguage: "ja",
  showFurigana: true,
  showRomanization: true,
  speechRate: 0.9,
  voices: { ja: "", ko: "" },
  reviewDirection: "foreign-first",
  frontFurigana: false,
};

// The API key lives in storage.local (never synced to Google); everything else syncs.
export async function getSettings() {
  const [synced, local] = await Promise.all([
    chrome.storage.sync.get(DEFAULTS),
    chrome.storage.local.get({ apiKey: "" }),
  ]);
  return { ...DEFAULTS, ...synced, apiKey: local.apiKey };
}

export async function saveSettings(patch) {
  const { apiKey, ...rest } = patch;
  if (apiKey !== undefined) await chrome.storage.local.set({ apiKey });
  if (Object.keys(rest).length) await chrome.storage.sync.set(rest);
}

/** Everything except the API key — safe to read from content scripts and pages. */
export async function getDisplaySettings() {
  const { apiKey, ...rest } = DEFAULTS;
  return { ...rest, ...(await chrome.storage.sync.get(rest)) };
}
