import { analyze } from "./lib/claude.js";
import { getSettings } from "./lib/settings.js";
import { addCard, countDue } from "./lib/cards.js";
import { planRequest, TTS_LANG } from "./lib/lang.js";

const MENU = {
  ja: "kotolens-to-ja",
  ko: "kotolens-to-ko",
  en: "kotolens-to-en",
};

chrome.runtime.onInstalled.addListener(async ({ reason }) => {
  chrome.contextMenus.removeAll(() => {
    chrome.contextMenus.create({ id: MENU.ja, title: "Translate to Japanese 日本語", contexts: ["selection"] });
    chrome.contextMenus.create({ id: MENU.ko, title: "Translate to Korean 한국어", contexts: ["selection"] });
    chrome.contextMenus.create({ id: MENU.en, title: "Explain in English (JA/KO → EN)", contexts: ["selection"] });
  });
  chrome.alarms.create("kotolens-badge", { periodInMinutes: 30 });
  updateBadge();
  if (reason === "install") {
    const { apiKey } = await getSettings();
    if (!apiKey) chrome.runtime.openOptionsPage();
  }
});

chrome.runtime.onStartup.addListener(updateBadge);
chrome.alarms.onAlarm.addListener((a) => a.name === "kotolens-badge" && updateBadge());
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.cards) updateBadge();
});

async function updateBadge() {
  const n = await countDue();
  chrome.action.setBadgeText({ text: n ? String(n > 99 ? "99+" : n) : "" });
  chrome.action.setBadgeBackgroundColor({ color: "#c2410c" });
}

chrome.contextMenus.onClicked.addListener((info, tab) => {
  const target = Object.keys(MENU).find((k) => MENU[k] === info.menuItemId);
  if (!target || !tab) return;
  openInTab(tab, info.frameId ?? 0, target, info.selectionText || "");
});

chrome.commands.onCommand.addListener(async (command, tab) => {
  if (command !== "explain-selection" || !tab) return;
  openInTab(tab, 0, "en", "");
});

// Inject the content script on demand (activeTab) so we never need access to every site.
async function openInTab(tab, frameId, target, selectionText) {
  try {
    await chrome.scripting.executeScript({
      target: { tabId: tab.id, frameIds: [frameId] },
      files: ["content.js"],
    });
    await chrome.tabs.sendMessage(tab.id, { type: "kotolens:open", target, selectionText }, { frameId });
  } catch (err) {
    // Pages we can't script (chrome://, the Web Store, the PDF viewer...) get a standalone panel instead.
    if (!selectionText) return;
    await openPanel({ target, selection: selectionText, sentence: selectionText, paragraph: "", pageTitle: tab.title || "", url: tab.url || "" });
  }
}

async function openPanel(request) {
  await chrome.storage.session.set({ pendingPanel: request });
  await chrome.windows.create({ url: chrome.runtime.getURL("pages/panel.html"), type: "popup", width: 480, height: 720 });
}

// Small in-memory cache so re-opening the same selection is instant.
const cache = new Map();
const CACHE_MAX = 50;

async function handleTranslate(req) {
  const settings = await getSettings();
  if (!settings.apiKey) {
    return { error: "Add your Anthropic API key in KotoLens settings to start translating.", code: "no_key" };
  }
  const plan = planRequest(req.selection, req.target, settings.defaultStudyLanguage);
  const key = JSON.stringify([settings.model, settings.effort, plan, req.selection, req.sentence]);
  if (cache.has(key)) return { result: cache.get(key), plan };
  try {
    const result = await analyze({ settings, plan, ...req });
    cache.set(key, result);
    if (cache.size > CACHE_MAX) cache.delete(cache.keys().next().value);
    return { result, plan };
  } catch (err) {
    return { error: err.message || String(err), code: err.code || "error" };
  }
}

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  const reply = (p) => p.then(sendResponse, (e) => sendResponse({ error: e.message || String(e) }));
  switch (msg?.type) {
    case "kotolens:translate":
      reply(handleTranslate(msg.request));
      return true;
    case "kotolens:speak":
      reply(speak(msg.text, msg.lang));
      return true;
    case "kotolens:stopSpeaking":
      chrome.tts.stop();
      return false;
    case "kotolens:addCard":
      reply(addCard(msg.card));
      return true;
    case "kotolens:dueCount":
      reply(countDue().then((n) => ({ due: n })));
      return true;
    case "kotolens:openPage":
      chrome.tabs.create({ url: chrome.runtime.getURL(`pages/${msg.page}.html`) });
      return false;
    case "kotolens:openPanel":
      reply(openPanel(msg.request).then(() => ({ ok: true })));
      return true;
  }
  return false;
});

async function speak(text, lang) {
  const { speechRate, voices } = await getSettings();
  const voiceName = voices?.[lang] || undefined;
  return new Promise((resolve) => {
    chrome.tts.speak(text, {
      lang: TTS_LANG[lang] || lang,
      voiceName,
      rate: speechRate,
      onEvent: (e) => {
        if (["end", "interrupted", "cancelled"].includes(e.type)) resolve({ ok: true });
        if (e.type === "error") resolve({ error: e.errorMessage || "Speech failed" });
      },
    });
  });
}
