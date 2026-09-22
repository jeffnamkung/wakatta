// Shared result view used by the in-page popup (content script) and the standalone panel page.
// All model output is inserted with textContent / DOM nodes — never innerHTML.
import { LANG_NAME } from "./lang.js";

export function h(tag, attrs = {}, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v == null || v === false) continue;
    if (k.startsWith("on")) el.addEventListener(k.slice(2).toLowerCase(), v);
    else if (k === "class") el.className = v;
    else el.setAttribute(k, v === true ? "" : v);
  }
  for (const c of children.flat()) {
    if (c == null || c === false) continue;
    el.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return el;
}

const KANA_ONLY = /^[぀-ヿー\s]*$/;
const toHiragana = (s) => s.replace(/[ァ-ヶ]/g, (c) => String.fromCharCode(c.charCodeAt(0) - 0x60));

/** Turn a word + whole-word reading into segments so furigana sits only over the kanji (食べる/たべる → 食[た]べる). */
export function splitFurigana(word, reading) {
  if (!reading || KANA_ONLY.test(word)) return [{ text: word, reading: "" }];
  let head = 0;
  while (head < word.length && head < reading.length && toHiragana(word[head]) === toHiragana(reading[head])) head++;
  let tail = 0;
  while (
    tail < word.length - head &&
    tail < reading.length - head &&
    toHiragana(word[word.length - 1 - tail]) === toHiragana(reading[reading.length - 1 - tail])
  )
    tail++;
  const segs = [];
  if (head) segs.push({ text: word.slice(0, head), reading: "" });
  segs.push({ text: word.slice(head, word.length - tail), reading: reading.slice(head, reading.length - tail) });
  if (tail) segs.push({ text: word.slice(word.length - tail), reading: "" });
  return segs;
}

export function rubyNodes(segments, showFurigana) {
  return (segments || []).map((s) =>
    showFurigana && s.reading && s.reading !== s.text ? h("ruby", {}, s.text, h("rt", {}, s.reading)) : document.createTextNode(s.text)
  );
}

/** Fallback when segments don't reproduce the text (so we never show mangled text). */
function safeSegments(passage) {
  const joined = (passage.segments || []).map((s) => s.text).join("");
  return joined.replace(/\s/g, "") === (passage.text || "").replace(/\s/g, "") ? passage.segments : [{ text: passage.text, reading: "" }];
}

const ICON = {
  speak: "🔊",
  add: "＋",
  added: "✓",
  close: "×",
};

/**
 * ctx: {
 *   send(msg): Promise<any>         — chrome.runtime.sendMessage
 *   settings: {...}                  — current settings
 *   saveSettings(patch): Promise
 *   rerun(target): void              — re-run with a different target language
 *   onClose?(): void                 — present in the in-page popup
 *   source: { url, title }
 * }
 */
export function createView(container, ctx) {
  const state = { result: null, plan: null, request: null };
  const body = h("div", { class: "kl-body" });
  const header = h(
    "div",
    { class: "kl-header" },
    h("span", { class: "kl-brand" }, "KotoLens"),
    h("span", { class: "kl-mode" }),
    h("span", { class: "kl-spacer" }),
    toggle("あ", "Furigana", "showFurigana"),
    toggle("Aa", "Romanization", "showRomanization"),
    ctx.onClose && h("button", { class: "kl-icon", title: "Close (Esc)", "aria-label": "Close", onClick: ctx.onClose }, ICON.close)
  );
  const footer = h("div", { class: "kl-footer" });
  container.replaceChildren(header, body, footer);

  function toggle(label, title, key) {
    const btn = h("button", { class: "kl-toggle", title: `Show ${title.toLowerCase()}`, "aria-pressed": String(!!ctx.settings[key]) }, label);
    btn.addEventListener("click", async () => {
      ctx.settings[key] = !ctx.settings[key];
      btn.setAttribute("aria-pressed", String(ctx.settings[key]));
      await ctx.saveSettings({ [key]: ctx.settings[key] });
      if (state.result) renderResult();
    });
    return btn;
  }

  function setMode(text) {
    header.querySelector(".kl-mode").textContent = text;
  }

  function speakBtn(text, lang) {
    const btn = h("button", { class: "kl-icon", title: "Listen", "aria-label": `Listen to ${text}` }, ICON.speak);
    btn.addEventListener("click", async () => {
      btn.classList.add("kl-busy");
      const res = await ctx.send({ type: "kotolens:speak", text, lang });
      btn.classList.remove("kl-busy");
      if (res?.error) btn.title = res.error;
    });
    return btn;
  }

  function addBtn(card) {
    const btn = h("button", { class: "kl-icon kl-add", title: "Add to flashcards", "aria-label": "Add to flashcards" }, ICON.add);
    btn.addEventListener("click", async () => {
      const res = await ctx.send({ type: "kotolens:addCard", card });
      if (res?.ok) {
        btn.textContent = ICON.added;
        btn.title = res.duplicate ? "Already in your flashcards" : "Added to flashcards";
        btn.classList.add("kl-done");
        btn.disabled = true;
      }
    });
    return btn;
  }

  function passageBlock(passage, lang, { big = false, card = null } = {}) {
    const segs = safeSegments(passage);
    return h(
      "div",
      { class: "kl-passage" },
      h(
        "div",
        { class: "kl-line" },
        h("div", { class: big ? "kl-foreign kl-big" : "kl-foreign", lang }, rubyNodes(segs, ctx.settings.showFurigana)),
        h("div", { class: "kl-actions" }, speakBtn(passage.text, lang), card && addBtn(card))
      ),
      ctx.settings.showRomanization && passage.romanization && h("div", { class: "kl-roman" }, passage.romanization),
      h("div", { class: "kl-english" }, passage.english)
    );
  }

  function exampleFor(r) {
    const s = r.sentence;
    return { text: s.text, segments: safeSegments(s), romanization: s.romanization, english: s.english };
  }

  function renderResult() {
    const { result: r, plan } = state;
    const lang = plan.studyLanguage;
    const langName = LANG_NAME[lang];
    setMode(plan.direction === "explain" ? `${langName} → English` : `→ ${langName}`);

    const selectionCard = {
      lang,
      front: r.selection.text,
      segments: safeSegments(r.selection),
      romanization: r.selection.romanization,
      meaning: r.selection.english,
      pos: "",
      example: exampleFor(r),
      source: ctx.source,
    };

    const sameAsSentence = r.selection.text.trim() === r.sentence.text.trim();
    const parts = [passageBlock(r.selection, lang, { big: true, card: selectionCard })];

    if (!sameAsSentence) {
      parts.push(h("h3", {}, "In context"), passageBlock(r.sentence, lang));
    }

    if (r.vocabulary?.length) {
      parts.push(
        h("h3", {}, "Vocabulary"),
        h(
          "ul",
          { class: "kl-vocab" },
          r.vocabulary.map((v) => {
            const segs = lang === "ja" ? splitFurigana(v.word, v.reading) : [{ text: v.word, reading: v.reading && v.reading !== v.word ? v.reading : "" }];
            const card = {
              lang,
              front: v.word,
              segments: segs,
              romanization: v.romanization,
              meaning: v.meaning,
              pos: v.part_of_speech,
              example: exampleFor(r),
              source: ctx.source,
            };
            return h(
              "li",
              {},
              h(
                "div",
                { class: "kl-vocab-main" },
                h("span", { class: "kl-foreign", lang }, rubyNodes(segs, ctx.settings.showFurigana)),
                v.as_used && v.as_used !== v.word && h("span", { class: "kl-asused", lang }, `(${v.as_used})`),
                ctx.settings.showRomanization && h("span", { class: "kl-roman" }, v.romanization),
                h("div", { class: "kl-gloss" }, v.meaning, v.part_of_speech && h("span", { class: "kl-pos" }, v.part_of_speech))
              ),
              h("div", { class: "kl-actions" }, speakBtn(v.word, lang), addBtn(card))
            );
          })
        )
      );
    }

    if (r.grammar_points?.length) {
      parts.push(
        h("h3", {}, "Grammar"),
        h(
          "ul",
          { class: "kl-grammar" },
          r.grammar_points.map((g) =>
            h(
              "li",
              {},
              h("div", { class: "kl-pattern", lang }, g.pattern),
              h("div", {}, g.explanation),
              g.example && h("div", { class: "kl-example", lang }, g.example)
            )
          )
        )
      );
    }

    if (r.notes) parts.push(h("h3", {}, "Notes"), h("p", { class: "kl-notes" }, r.notes));
    body.replaceChildren(...parts);
    renderFooter();
  }

  function renderFooter() {
    const current = state.plan?.direction === "explain" ? "en" : state.plan?.studyLanguage;
    const targets = [
      ["ja", "日本語"],
      ["ko", "한국어"],
      ["en", "English"],
    ];
    footer.replaceChildren(
      h("span", { class: "kl-footer-label" }, "Redo as"),
      ...targets.map(([t, label]) =>
        h("button", { class: "kl-chip", disabled: t === current, onClick: () => ctx.rerun(t) }, label)
      ),
      h("span", { class: "kl-spacer" }),
      h("button", { class: "kl-link", onClick: () => ctx.send({ type: "kotolens:openPage", page: "review" }) }, "Review cards")
    );
  }

  return {
    showLoading(request) {
      state.request = request;
      setMode("");
      body.replaceChildren(
        h(
          "div",
          { class: "kl-loading" },
          h("div", { class: "kl-spinner", "aria-hidden": "true" }),
          h("div", {}, "Reading in context…"),
          h("div", { class: "kl-quote" }, request.selection.length > 120 ? request.selection.slice(0, 120) + "…" : request.selection)
        )
      );
      footer.replaceChildren();
    },
    showResult(result, plan) {
      state.result = result;
      state.plan = plan;
      renderResult();
    },
    showError(message, code) {
      body.replaceChildren(
        h(
          "div",
          { class: "kl-error" },
          h("p", {}, message),
          ["no_key", "bad_key", "not_found", "forbidden"].includes(code)
            ? h("button", { class: "kl-primary", onClick: () => ctx.send({ type: "kotolens:openPage", page: "options" }) }, "Open settings")
            : h("button", { class: "kl-primary", onClick: () => ctx.rerun(null) }, "Try again")
        )
      );
      renderFooter();
    },
  };
}
