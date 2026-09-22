import { getCards, updateCard, deleteCard, replaceAll, isDue, schedule, previewInterval } from "../lib/cards.js";
import { h, rubyNodes } from "../lib/render.js";
import { getDisplaySettings, saveSettings } from "../lib/settings.js";

const $ = (id) => document.getElementById(id);
const speak = (text, lang) => chrome.runtime.sendMessage({ type: "kotolens:speak", text, lang });
const GRADES = [
  ["Again", "g0"],
  ["Hard", "g1"],
  ["Good", "g2"],
  ["Easy", "g3"],
];

let settings;
let queue = [];
let done = 0;
let current = null;
let flipped = false;

(async () => {
  settings = await getDisplaySettings();
  $("direction").value = settings.reviewDirection;
  $("frontFurigana").checked = !!settings.frontFurigana;
  $("direction").onchange = () => {
    settings.reviewDirection = $("direction").value;
    saveSettings({ reviewDirection: settings.reviewDirection });
    renderCard();
  };
  $("frontFurigana").onchange = () => {
    settings.frontFurigana = $("frontFurigana").checked;
    saveSettings({ frontFurigana: settings.frontFurigana });
    renderCard();
  };
  selectTab(location.hash === "#cards" ? "cards" : "review");
  await startSession();
})();

$("tab-review").onclick = () => selectTab("review");
$("tab-cards").onclick = () => selectTab("cards");

function selectTab(name) {
  $("tab-review").setAttribute("aria-selected", String(name === "review"));
  $("tab-cards").setAttribute("aria-selected", String(name === "cards"));
  $("panel-review").hidden = name !== "review";
  $("panel-cards").hidden = name !== "cards";
  history.replaceState(null, "", name === "cards" ? "#cards" : "#");
  if (name === "cards") renderTable();
}

async function startSession() {
  const cards = await getCards();
  queue = shuffle(cards.filter((c) => isDue(c)));
  done = 0;
  next();
}

function next() {
  current = queue.shift() || null;
  flipped = false;
  renderCard();
}

function renderCard() {
  const total = done + queue.length + (current ? 1 : 0);
  $("counter").textContent = current ? `${queue.length + 1} left` : "";
  $("bar").style.width = total ? `${(done / total) * 100}%` : "0";
  const flash = $("flash");

  if (!current) {
    flash.replaceChildren(
      h("div", { class: "empty" }, h("div", { style: "font-size:40px" }, "🎉"), h("p", {}, done ? `Session complete: ${done} review${done === 1 ? "" : "s"}.` : "Nothing due right now."), h("button", { onClick: () => selectTab("cards") }, "Browse all cards"))
    );
    return;
  }

  const c = current;
  const foreignFirst = settings.reviewDirection !== "english-first";
  const foreign = (withFurigana) => h("div", { class: "front", lang: c.lang }, rubyNodes(c.segments || [{ text: c.front, reading: "" }], withFurigana));
  const parts = [];

  if (foreignFirst) parts.push(foreign(!!settings.frontFurigana || flipped));
  else parts.push(h("div", { class: "front english" }, c.meaning));

  if (foreignFirst && !flipped) parts.push(h("button", { class: "ghost", onClick: () => speak(c.front, c.lang) }, "🔊 Listen"));

  if (!flipped) {
    parts.push(h("button", { class: "primary", onClick: flip }, "Show answer ", h("kbd", {}, "Space")));
  } else {
    parts.push(
      h(
        "div",
        { class: "back" },
        !foreignFirst && foreign(true),
        c.romanization && h("div", { class: "roman" }, c.romanization),
        foreignFirst && h("div", { class: "meaning" }, c.meaning),
        c.pos && h("span", { class: "pos" }, c.pos),
        h("button", { class: "ghost", onClick: () => speak(c.front, c.lang) }, "🔊 Listen ", h("kbd", {}, "P")),
        c.example?.text &&
          c.example.text !== c.front &&
          h(
            "div",
            { class: "example" },
            h("div", { class: "row", style: "flex-wrap:nowrap;align-items:flex-start" }, h("div", { class: "jp", lang: c.lang, style: "flex:1" }, rubyNodes(c.example.segments || [{ text: c.example.text, reading: "" }], true)), h("button", { class: "ghost", onClick: () => speak(c.example.text, c.lang), "aria-label": "Listen to example" }, "🔊")),
            h("div", { class: "muted" }, c.example.english),
            c.source?.url && h("div", { class: "small" }, h("a", { href: c.source.url, target: "_blank", rel: "noopener" }, c.source.title || c.source.url))
          ),
        h(
          "div",
          { class: "grades", style: "width:100%" },
          GRADES.map(([label, cls], g) => h("button", { class: cls, onClick: () => grade(g) }, h("span", {}, label), h("small", {}, `${previewInterval(c.srs, g)} · `, h("kbd", {}, String(g + 1)))))
        )
      )
    );
  }
  flash.replaceChildren(...parts.filter(Boolean));
}

function flip() {
  if (!current || flipped) return;
  flipped = true;
  renderCard();
  if (settings.reviewDirection === "english-first") speak(current.front, current.lang);
}

async function grade(g) {
  if (!current || !flipped) return;
  const srs = schedule(current.srs, g);
  await updateCard(current.id, { srs });
  if (g === 0) queue.push({ ...current, srs }); // see it again this session
  else done += 1;
  next();
}

document.addEventListener("keydown", (e) => {
  if ($("panel-review").hidden || e.target.matches("input, select, textarea")) return;
  if (e.key === " " || e.code === "Space" || e.key === "Enter") {
    e.preventDefault();
    flip();
  } else if (/^[1-4]$/.test(e.key)) grade(Number(e.key) - 1);
  else if (e.key.toLowerCase() === "p" && current) speak(current.front, current.lang);
});

// ---- All cards ----
$("search").oninput = renderTable;
$("langFilter").onchange = renderTable;

async function renderTable() {
  const q = $("search").value.trim().toLowerCase();
  const lang = $("langFilter").value;
  const cards = (await getCards())
    .filter((c) => !lang || c.lang === lang)
    .filter((c) => !q || [c.front, c.meaning, c.romanization].some((f) => f?.toLowerCase().includes(q)))
    .sort((a, b) => b.created - a.created);
  $("noCards").hidden = cards.length > 0;
  $("rows").replaceChildren(
    ...cards.map((c) =>
      h(
        "tr",
        {},
        h("td", { class: "word", lang: c.lang }, rubyNodes(c.segments || [{ text: c.front, reading: "" }], true)),
        h("td", {}, c.meaning, c.romanization && h("div", { class: "muted small" }, c.romanization)),
        h("td", { class: "hide-sm muted small" }, isDue(c) ? "Due now" : new Date(c.srs.due).toLocaleDateString()),
        h(
          "td",
          { style: "white-space:nowrap;text-align:right" },
          h("button", { class: "ghost", title: "Listen", "aria-label": `Listen to ${c.front}`, onClick: () => speak(c.front, c.lang) }, "🔊"),
          h(
            "button",
            {
              class: "ghost danger",
              title: "Delete",
              "aria-label": `Delete ${c.front}`,
              onClick: async () => {
                if (!confirm(`Delete “${c.front}”?`)) return;
                await deleteCard(c.id);
                queue = queue.filter((x) => x.id !== c.id);
                renderTable();
              },
            },
            "🗑"
          )
        )
      )
    )
  );
}

function download(name, text, type) {
  const url = URL.createObjectURL(new Blob([text], { type }));
  h("a", { href: url, download: name }).click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

const csvCell = (s = "") => `"${String(s).replace(/"/g, '""')}"`;
const furiganaHtml = (segs) =>
  (segs || []).map((s) => (s.reading && s.reading !== s.text ? `<ruby>${esc(s.text)}<rt>${esc(s.reading)}</rt></ruby>` : esc(s.text))).join("");
const esc = (s) => s.replace(/[&<>"]/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[ch]);

$("exportCsv").onclick = async () => {
  // Front, Back, Reading, Romanization, Example, Example translation, Tags — importable into Anki with HTML enabled.
  const rows = (await getCards()).map((c) =>
    [furiganaHtml(c.segments) || esc(c.front), esc(c.meaning || ""), (c.segments || []).map((s) => s.reading || s.text).join(""), c.romanization, furiganaHtml(c.example?.segments), c.example?.english, `kotolens ${c.lang}`]
      .map(csvCell)
      .join(",")
  );
  download("kotolens-cards.csv", "﻿" + rows.join("\n"), "text/csv");
};

$("exportJson").onclick = async () => {
  download(`kotolens-backup-${new Date().toISOString().slice(0, 10)}.json`, JSON.stringify({ version: 1, cards: await getCards() }, null, 2), "application/json");
};

$("importJson").onclick = () => $("importFile").click();
$("importFile").onchange = async () => {
  const file = $("importFile").files[0];
  if (!file) return;
  try {
    const data = JSON.parse(await file.text());
    const incoming = Array.isArray(data) ? data : data.cards;
    if (!Array.isArray(incoming) || !incoming.every((c) => c.id && c.front && c.srs)) throw new Error("Not a KotoLens backup file.");
    const existing = await getCards();
    const byId = new Map(existing.map((c) => [c.id, c]));
    for (const c of incoming) byId.set(c.id, c);
    await replaceAll([...byId.values()]);
    alert(`Restored ${incoming.length} cards.`);
    renderTable();
    startSession();
  } catch (e) {
    alert(`Couldn't import: ${e.message}`);
  }
  $("importFile").value = "";
};

function shuffle(a) {
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
