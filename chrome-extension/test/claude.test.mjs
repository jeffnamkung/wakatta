import { test } from "node:test";
import assert from "node:assert/strict";
import { analyze, SCHEMA } from "../src/lib/claude.js";

function mockFetch(capture, body) {
  return async (url, init) => {
    capture.push({ url: String(url), headers: Object.fromEntries(new Headers(init.headers)), body: JSON.parse(init.body) });
    return new Response(JSON.stringify(body), { status: 200, headers: { "content-type": "application/json", "request-id": "req_test" } });
  };
}

const payload = { selection: {}, sentence: {}, vocabulary: [], grammar_points: [], notes: "" };
const okMessage = (model) => ({
  id: "msg_1", type: "message", role: "assistant", model, stop_reason: "end_turn",
  content: [{ type: "text", text: JSON.stringify(payload) }],
  usage: { input_tokens: 1, output_tokens: 1 },
});

function walk(node, fn) {
  if (node && typeof node === "object") {
    fn(node);
    Object.values(node).forEach((v) => walk(v, fn));
  }
}

test("schema objects are closed and fully required (structured outputs rules)", () => {
  walk(SCHEMA, (n) => {
    if (n.type === "object") {
      assert.equal(n.additionalProperties, false);
      assert.deepEqual([...n.required].sort(), Object.keys(n.properties).sort());
    }
  });
});

for (const [model, expectBeta, expectEffort] of [
  ["claude-opus-5", true, true],
  ["claude-sonnet-5", false, true],
  ["claude-haiku-4-5", false, false],
]) {
  test(`request shape for ${model}`, async () => {
    const calls = [];
    const realFetch = globalThis.fetch;
    globalThis.fetch = mockFetch(calls, okMessage(model));
    try {
      const out = await analyze({
        settings: { apiKey: "sk-ant-test", model, effort: "low" },
        plan: { studyLanguage: "ja", direction: "explain" },
        selection: "美味しかった",
        sentence: "料理はとても美味しかったので。",
        paragraph: "",
        pageTitle: "t",
      });
      assert.deepEqual(out, payload);
    } finally {
      globalThis.fetch = realFetch;
    }
    const { url, headers, body } = calls[0];
    assert.match(url, /api\.anthropic\.com\/v1\/messages/);
    assert.equal(headers["x-api-key"], "sk-ant-test");
    assert.equal(headers["anthropic-dangerous-direct-browser-access"], "true");
    assert.equal(body.model, model);
    assert.equal(body.output_config.format.type, "json_schema");
    assert.equal("effort" in body.output_config, expectEffort);
    assert.equal(body.fallbacks === "default", expectBeta);
    assert.equal((headers["anthropic-beta"] || "").includes("server-side-fallback-2026-07-01"), expectBeta);
    assert.match(body.messages[0].content, /<selection>美味しかった<\/selection>/);
  });
}

test("refusal surfaces a friendly error", async () => {
  const realFetch = globalThis.fetch;
  globalThis.fetch = mockFetch([], { ...okMessage("claude-opus-5"), stop_reason: "refusal", content: [] });
  try {
    await assert.rejects(
      analyze({ settings: { apiKey: "k", model: "claude-opus-5", effort: "low" }, plan: { studyLanguage: "ko", direction: "translate" }, selection: "x" }),
      (e) => e.code === "refusal"
    );
  } finally {
    globalThis.fetch = realFetch;
  }
});
