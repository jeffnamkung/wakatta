// Standalone result window: used for the toolbar lookup box and pages where content scripts can't run.
import css from "../lib/view.css";
import { createView } from "../lib/render.js";
import { getDisplaySettings, saveSettings } from "../lib/settings.js";

const style = document.createElement("style");
style.textContent = css;
document.head.append(style);

(async () => {
  const { pendingPanel: request } = await chrome.storage.session.get("pendingPanel");
  const root = document.getElementById("root");
  if (!request) {
    root.textContent = "Nothing to translate.";
    return;
  }
  const send = (msg) => chrome.runtime.sendMessage(msg).catch((e) => ({ error: e.message }));
  const view = createView(root, {
    send,
    settings: await getDisplaySettings(),
    saveSettings,
    source: { url: request.url, title: request.pageTitle },
    rerun: (t) => run(t ?? request.target),
  });
  async function run(target) {
    request.target = target;
    view.showLoading(request);
    const res = await send({ type: "kotolens:translate", request });
    if (res?.error) view.showError(res.error, res.code);
    else view.showResult(res.result, res.plan);
  }
  run(request.target);
})();
