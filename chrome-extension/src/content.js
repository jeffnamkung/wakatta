// Injected on demand (activeTab) when the user picks a KotoLens context-menu item.
import css from "./lib/view.css";
import { captureSelection } from "./lib/context.js";
import { createView } from "./lib/render.js";
import { getDisplaySettings, saveSettings } from "./lib/settings.js";

const alive = () => {
  try {
    return !!chrome.runtime?.id;
  } catch {
    return false;
  }
};

// Re-injection into the same page is a no-op unless the previous copy was orphaned by an extension reload.
if (!window.__kotolens?.alive()) {
  window.__kotolens = { alive };
  chrome.runtime.onMessage.addListener((msg) => {
    if (msg?.type === "kotolens:open") open(msg.target, msg.selectionText);
  });
}

let popup = null;

function send(msg) {
  return chrome.runtime.sendMessage(msg).catch((e) => ({ error: e.message }));
}

async function open(target, selectionText) {
  const captured = captureSelection(selectionText);
  if (!captured?.selection) return;
  const settings = await getDisplaySettings();
  close();

  const host = document.createElement("div");
  host.id = "kotolens-host";
  host.style.cssText = "position:fixed;z-index:2147483647;top:0;left:0;width:0;height:0;";
  const shadow = host.attachShadow({ mode: "closed" });
  const style = document.createElement("style");
  style.textContent = css;
  const root = document.createElement("div");
  root.className = "kl-root";
  root.setAttribute("role", "dialog");
  root.setAttribute("aria-label", "KotoLens translation");
  root.style.position = "fixed";
  shadow.append(style, root);
  document.documentElement.append(host);
  place(root, captured.rect);

  const request = {
    target,
    selection: captured.selection,
    sentence: captured.sentence,
    paragraph: captured.paragraph,
    pageTitle: document.title,
    url: location.href,
  };

  const view = createView(root, {
    send,
    settings,
    saveSettings,
    source: { url: location.href, title: document.title },
    onClose: close,
    rerun: (t) => run(t ?? request.target),
  });

  async function run(t) {
    request.target = t;
    view.showLoading(request);
    const res = await send({ type: "kotolens:translate", request });
    if (popup?.root !== root) return; // closed or replaced while waiting
    if (res?.error) view.showError(res.error, res.code);
    else view.showResult(res.result, res.plan);
  }

  const onKey = (e) => e.key === "Escape" && close();
  const onDown = (e) => !e.composedPath().includes(host) && close();
  window.addEventListener("keydown", onKey, true);
  window.addEventListener("mousedown", onDown, true);
  enableDrag(root);

  popup = {
    root,
    teardown() {
      window.removeEventListener("keydown", onKey, true);
      window.removeEventListener("mousedown", onDown, true);
      send({ type: "kotolens:stopSpeaking" });
      host.remove();
    },
  };
  run(target);
}

function close() {
  popup?.teardown();
  popup = null;
}

function place(root, rect) {
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  const width = Math.min(440, vw - 16);
  root.style.width = `${width}px`;
  if (!rect) {
    root.style.top = "16px";
    root.style.left = `${Math.max(8, vw - width - 16)}px`;
    root.style.maxHeight = `${Math.min(640, vh - 32)}px`;
    return;
  }
  root.style.left = `${Math.min(Math.max(8, rect.left), vw - width - 8)}px`;
  const below = vh - rect.bottom - 16;
  const above = rect.top - 16;
  if (below >= 320 || below >= above) {
    root.style.top = `${rect.bottom + 8}px`;
    root.style.maxHeight = `${Math.min(640, Math.max(below, 200))}px`;
  } else {
    root.style.bottom = `${vh - rect.top + 8}px`;
    root.style.maxHeight = `${Math.min(640, above)}px`;
  }
}

function enableDrag(root) {
  const header = root.querySelector(".kl-header");
  header.addEventListener("mousedown", (e) => {
    if (e.button !== 0 || e.target.closest("button")) return;
    e.preventDefault();
    const start = root.getBoundingClientRect();
    const dx = e.clientX - start.left;
    const dy = e.clientY - start.top;
    root.style.bottom = "";
    const move = (ev) => {
      root.style.left = `${Math.min(Math.max(0, ev.clientX - dx), window.innerWidth - 60)}px`;
      root.style.top = `${Math.min(Math.max(0, ev.clientY - dy), window.innerHeight - 40)}px`;
    };
    const up = () => {
      window.removeEventListener("mousemove", move, true);
      window.removeEventListener("mouseup", up, true);
    };
    window.addEventListener("mousemove", move, true);
    window.addEventListener("mouseup", up, true);
  });
}
