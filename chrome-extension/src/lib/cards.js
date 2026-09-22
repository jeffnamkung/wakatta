// Flashcards live in chrome.storage.local under "cards". Scheduling is a light SM-2 variant.
const DAY = 24 * 60 * 60 * 1000;
const MIN = 60 * 1000;

export async function getCards() {
  const { cards } = await chrome.storage.local.get({ cards: [] });
  return cards;
}

async function setCards(cards) {
  await chrome.storage.local.set({ cards });
}

function newSrs(now = Date.now()) {
  return { due: now, interval: 0, ease: 2.5, reps: 0, lapses: 0 };
}

export async function addCard(card) {
  const cards = await getCards();
  const dup = cards.find((c) => c.lang === card.lang && c.front === card.front);
  if (dup) return { ok: true, duplicate: true, id: dup.id };
  const id = crypto.randomUUID();
  cards.push({ ...card, id, created: Date.now(), srs: newSrs() });
  await setCards(cards);
  return { ok: true, id };
}

export async function updateCard(id, patch) {
  const cards = await getCards();
  const i = cards.findIndex((c) => c.id === id);
  if (i < 0) return;
  cards[i] = { ...cards[i], ...patch };
  await setCards(cards);
}

export async function deleteCard(id) {
  await setCards((await getCards()).filter((c) => c.id !== id));
}

export async function replaceAll(cards) {
  await setCards(cards);
}

export function isDue(card, now = Date.now()) {
  return card.srs.due <= now;
}

export async function countDue() {
  const now = Date.now();
  return (await getCards()).filter((c) => isDue(c, now)).length;
}

/** grade: 0 = again, 1 = hard, 2 = good, 3 = easy. Returns the new srs object. */
export function schedule(srs, grade, now = Date.now()) {
  let { interval, ease, reps, lapses } = srs;
  if (grade === 0) {
    lapses += 1;
    reps = 0;
    ease = Math.max(1.3, ease - 0.2);
    interval = 0;
    return { due: now + 10 * MIN, interval, ease, reps, lapses };
  }
  if (grade === 1) {
    ease = Math.max(1.3, ease - 0.15);
    interval = reps === 0 ? 1 : Math.max(1, Math.round(interval * 1.2));
  } else if (grade === 2) {
    interval = reps === 0 ? 1 : reps === 1 ? 3 : Math.round(interval * ease);
  } else {
    ease += 0.15;
    interval = reps === 0 ? 4 : Math.round(Math.max(interval, 1) * ease * 1.3);
  }
  reps += 1;
  return { due: now + interval * DAY, interval, ease, reps, lapses };
}

/** Human label for the next interval a grade would produce, e.g. "10m", "3d". */
export function previewInterval(srs, grade) {
  const next = schedule(srs, grade, 0);
  if (next.due < DAY) return `${Math.round(next.due / MIN)}m`;
  const d = next.interval;
  return d >= 365 ? `${(d / 365).toFixed(1)}y` : d >= 30 ? `${Math.round(d / 30)}mo` : `${d}d`;
}
