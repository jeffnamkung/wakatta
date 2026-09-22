// Minimal chrome.* stub so extension pages can be previewed in a normal tab (dev only).
(() => {
  const now = Date.now();
  const mk = (front, segments, romanization, meaning, pos, due) => ({
    id: crypto.randomUUID(), lang: "ja", front, segments, romanization, meaning, pos, created: now,
    example: { text: "料理はとても美味しかったので、また行きたいと思っています。", segments: [{ text: "料理", reading: "りょうり" }, { text: "はとても", reading: "" }, { text: "美味", reading: "おい" }, { text: "しかったので、また", reading: "" }, { text: "行", reading: "い" }, { text: "きたいと", reading: "" }, { text: "思", reading: "おも" }, { text: "っています。", reading: "" }], english: "The food was so delicious that I'm thinking I'd like to go again." },
    source: { url: "https://example.com", title: "Example article" },
    srs: { due, interval: 0, ease: 2.5, reps: 0, lapses: 0 },
  });
  const data = {
    cards: [
      mk("美味しい", [{ text: "美味", reading: "おい" }, { text: "しい", reading: "" }], "oishii", "delicious", "i-adjective", now - 1000),
      mk("料理", [{ text: "料理", reading: "りょうり" }], "ryōri", "cooking; cuisine", "noun", now - 1000),
      mk("思う", [{ text: "思", reading: "おも" }, { text: "う", reading: "" }], "omou", "to think", "godan verb", now + 3 * 864e5),
    ],
  };
  const area = (o) => ({ async get(d) { return typeof d === "object" ? { ...d, ...o } : { [d]: o[d] }; }, async set(v) { Object.assign(o, v); } });
  window.chrome = {
    runtime: { id: "stub", async sendMessage(m) { console.log("sendMessage", m); return { ok: true }; }, onMessage: { addListener() {} }, getURL: (p) => "/" + p, openOptionsPage() {} },
    storage: { local: area(data), sync: area({}), session: area({}) },
    tabs: { create() {} },
    tts: { getVoices(cb) { cb([{ voiceName: "Kyoko", lang: "ja-JP" }, { voiceName: "Yuna", lang: "ko-KR" }]); } },
  };
})();
