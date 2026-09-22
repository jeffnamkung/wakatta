import { test } from "node:test";
import assert from "node:assert/strict";
import { planRequest, detectScript } from "../src/lib/lang.js";
import { schedule, previewInterval } from "../src/lib/cards.js";

// render.js touches `document` only inside functions, so a bare import is fine.
const { splitFurigana } = await import("../src/lib/render.js");

test("detectScript", () => {
  assert.equal(detectScript("안녕하세요"), "ko");
  assert.equal(detectScript("食べる"), "ja");
  assert.equal(detectScript("hello"), "other");
});

test("planRequest", () => {
  assert.deepEqual(planRequest("食べる", "en"), { studyLanguage: "ja", direction: "explain" });
  assert.deepEqual(planRequest("hello", "ko"), { studyLanguage: "ko", direction: "translate" });
  assert.deepEqual(planRequest("안녕", "ko"), { studyLanguage: "ko", direction: "explain" });
  assert.deepEqual(planRequest("hello", "en", "ko"), { studyLanguage: "ko", direction: "translate" });
});

test("splitFurigana keeps okurigana out of the ruby", () => {
  assert.deepEqual(splitFurigana("食べる", "たべる"), [
    { text: "食", reading: "た" },
    { text: "べる", reading: "" },
  ]);
  assert.deepEqual(splitFurigana("お茶", "おちゃ"), [
    { text: "お", reading: "" },
    { text: "茶", reading: "ちゃ" },
  ]);
  assert.deepEqual(splitFurigana("日本語", "にほんご"), [{ text: "日本語", reading: "にほんご" }]);
  assert.deepEqual(splitFurigana("すごい", ""), [{ text: "すごい", reading: "" }]);
});

test("schedule grows intervals and resets on Again", () => {
  let s = { due: 0, interval: 0, ease: 2.5, reps: 0, lapses: 0 };
  s = schedule(s, 2, 0);
  assert.equal(s.interval, 1);
  s = schedule(s, 2, 0);
  assert.equal(s.interval, 3);
  s = schedule(s, 2, 0);
  assert.equal(s.interval, 8);
  const lapsed = schedule(s, 0, 0);
  assert.equal(lapsed.reps, 0);
  assert.equal(lapsed.lapses, 1);
  assert.equal(previewInterval(lapsed, 0), "10m");
});
