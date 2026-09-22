import { getCards, isDue } from "../lib/cards.js";

const $ = (id) => document.getElementById(id);
const openPage = (page, hash = "") => chrome.tabs.create({ url: chrome.runtime.getURL(`pages/${page}.html${hash}`) });

(async () => {
  const [{ apiKey }, cards] = await Promise.all([chrome.storage.local.get({ apiKey: "" }), getCards()]);
  const due = cards.filter((c) => isDue(c)).length;
  $("nokey").hidden = !!apiKey;
  $("dueCount").textContent = due;
  $("total").textContent = `${cards.length} card${cards.length === 1 ? "" : "s"}`;
  $("review").disabled = due === 0;
  $("review").textContent = due ? "Review now" : "All caught up 🎉";
})();

$("review").onclick = () => openPage("review");
$("cards").onclick = () => openPage("review", "#cards");
$("settings").onclick = $("setup").onclick = (e) => {
  e.preventDefault();
  chrome.runtime.openOptionsPage();
};

document.querySelectorAll("[data-target]").forEach((btn) => {
  btn.onclick = async () => {
    const text = $("text").value.trim();
    if (!text) return $("text").focus();
    await chrome.runtime.sendMessage({
      type: "kotolens:openPanel",
      request: { target: btn.dataset.target, selection: text, sentence: text, paragraph: "", pageTitle: "", url: "" },
    });
    window.close();
  };
});
