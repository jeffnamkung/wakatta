import { MODELS, getSettings, saveSettings } from "../lib/settings.js";

const $ = (id) => document.getElementById(id);
const SAMPLES = { ja: "今日はいい天気ですね。", ko: "오늘 날씨가 정말 좋네요." };

(async () => {
  const s = await getSettings();
  $("model").append(...MODELS.map((m) => new Option(m.label, m.id)));

  $("apiKey").value = s.apiKey;
  $("model").value = s.model;
  $("effort").value = s.effort;
  $("defaultStudyLanguage").value = s.defaultStudyLanguage;
  $("showFurigana").checked = s.showFurigana;
  $("showRomanization").checked = s.showRomanization;
  $("speechRate").value = s.speechRate;
  $("rateLabel").textContent = `${s.speechRate}×`;

  $("apiKey").addEventListener("change", () => saveSettings({ apiKey: $("apiKey").value.trim() }).then(() => status("Saved.", "ok")));
  for (const id of ["model", "effort", "defaultStudyLanguage"]) {
    $(id).addEventListener("change", () => saveSettings({ [id]: $(id).value }));
  }
  for (const id of ["showFurigana", "showRomanization"]) {
    $(id).addEventListener("change", () => saveSettings({ [id]: $(id).checked }));
  }
  $("speechRate").addEventListener("input", () => {
    $("rateLabel").textContent = `${$("speechRate").value}×`;
    saveSettings({ speechRate: Number($("speechRate").value) });
  });

  $("toggleKey").onclick = () => {
    const show = $("apiKey").type === "password";
    $("apiKey").type = show ? "text" : "password";
    $("toggleKey").textContent = show ? "Hide" : "Show";
  };

  $("testKey").onclick = async () => {
    await saveSettings({ apiKey: $("apiKey").value.trim() });
    status("Testing…", "");
    $("testKey").disabled = true;
    const res = await chrome.runtime.sendMessage({
      type: "kotolens:translate",
      request: { target: "en", selection: "猫", sentence: "猫が好きです。", paragraph: "", pageTitle: "KotoLens test" },
    });
    $("testKey").disabled = false;
    if (res?.error) status(res.error, "err");
    else status(`Works! 猫 → ${res.result.vocabulary?.[0]?.meaning || res.result.selection.english}`, "ok");
  };

  chrome.tts.getVoices((voices) => {
    for (const lang of ["ja", "ko"]) {
      const sel = $(`voice-${lang}`);
      const matching = voices.filter((v) => v.lang?.toLowerCase().startsWith(lang));
      sel.append(new Option("System default", ""), ...matching.map((v) => new Option(`${v.voiceName}${v.remote ? " (online)" : ""}`, v.voiceName)));
      sel.value = s.voices?.[lang] || "";
      sel.addEventListener("change", async () => {
        const cur = (await getSettings()).voices || {};
        saveSettings({ voices: { ...cur, [lang]: sel.value } });
      });
    }
  });

  document.querySelectorAll("[data-preview]").forEach((btn) => {
    btn.onclick = () => chrome.runtime.sendMessage({ type: "kotolens:speak", text: SAMPLES[btn.dataset.preview], lang: btn.dataset.preview });
  });
})();

function status(text, cls) {
  $("keyStatus").textContent = text;
  $("keyStatus").className = `status ${cls}`;
}
