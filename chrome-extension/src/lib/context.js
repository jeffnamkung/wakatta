// Capture the highlighted text plus the sentence and paragraph around it.
import { detectScript } from "./lang.js";

const SKIP = new Set(["RT", "RP", "SCRIPT", "STYLE", "NOSCRIPT", "TEMPLATE"]);
const WINDOW = 700; // characters of paragraph context on each side
const norm = (s) => s.replace(/\s+/g, " ");

function blockAncestor(node) {
  let el = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement;
  while (el && el !== document.body && /^inline/.test(getComputedStyle(el).display)) el = el.parentElement;
  return el || document.body;
}

function textNodesIn(root) {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(n) {
      for (let p = n.parentElement; p && p !== root.parentElement; p = p.parentElement) {
        if (SKIP.has(p.tagName)) return NodeFilter.FILTER_REJECT; // drop existing furigana (<rt>) and code
      }
      return NodeFilter.FILTER_ACCEPT;
    },
  });
  const nodes = [];
  while (walker.nextNode()) nodes.push(walker.currentNode);
  return nodes;
}

function sentenceAround(before, selection, after) {
  const full = before + selection + after;
  const start = before.length;
  const end = start + selection.length;
  const lang = detectScript(selection) === "other" ? detectScript(full) : detectScript(selection);
  let segments;
  try {
    segments = [...new Intl.Segmenter(lang === "other" ? "en" : lang, { granularity: "sentence" }).segment(full)];
  } catch {
    return selection;
  }
  const hit = segments.filter((s) => s.index < end && s.index + s.segment.length > start);
  return hit.map((s) => s.segment).join("").trim() || selection;
}

function fromInput(el) {
  const value = el.value || "";
  const s = el.selectionStart ?? 0;
  const e = el.selectionEnd ?? 0;
  if (s === e) return null;
  const before = norm(value.slice(Math.max(0, s - WINDOW), s));
  const selection = norm(value.slice(s, e)).trim();
  const after = norm(value.slice(e, e + WINDOW));
  return { selection, sentence: sentenceAround(before, selection, after), paragraph: (before + selection + after).trim(), rect: el.getBoundingClientRect() };
}

export function captureSelection(fallbackText = "") {
  const active = document.activeElement;
  if (active && (active.tagName === "TEXTAREA" || (active.tagName === "INPUT" && /^(text|search|url)?$/i.test(active.type)))) {
    const r = fromInput(active);
    if (r) return r;
  }

  const sel = window.getSelection();
  if (!sel || sel.rangeCount === 0 || sel.isCollapsed) {
    return fallbackText ? { selection: fallbackText, sentence: fallbackText, paragraph: "", rect: null } : null;
  }
  const range = sel.getRangeAt(0);
  const block = blockAncestor(range.commonAncestorContainer);

  let before = "";
  let selected = "";
  let after = "";
  let phase = "before";
  let tail = "";
  for (const t of textNodesIn(block)) {
    const text = t.data;
    if (range.intersectsNode(t)) {
      const s = t === range.startContainer ? range.startOffset : 0;
      const e = t === range.endContainer ? range.endOffset : text.length;
      if (phase === "before") before += text.slice(0, s);
      phase = "in";
      selected += text.slice(s, e);
      tail = text.slice(e);
    } else if (phase === "before") {
      before += text;
    } else {
      after += tail + text;
      tail = "";
      phase = "after";
    }
  }
  after = tail + after;

  let selection = norm(selected).trim() || norm(sel.toString()).trim() || fallbackText;
  before = norm(before).slice(-WINDOW);
  after = norm(after).slice(0, WINDOW);
  const rect = range.getBoundingClientRect();
  return {
    selection,
    sentence: sentenceAround(before, norm(selected) || selection, after),
    paragraph: (before + norm(selected) + after).trim(),
    rect: rect.width || rect.height ? rect : null,
  };
}
