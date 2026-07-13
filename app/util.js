// Pure helpers with no app-state dependency.

const LS = window.localStorage;

export const esc = (s) =>
  String(s == null ? "" : s).replace(/[&<>"']/g, (m) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[m]));

export const katToHira = (s) =>
  (s || "").replace(/[ァ-ヶ]/g, (c) => String.fromCharCode(c.charCodeAt(0) - 0x60));

export const lsGet = (k, f) => { try { const v = LS.getItem(k); return v == null ? f : JSON.parse(v); } catch (e) { return f; } };
export const lsSet = (k, v) => { try { LS.setItem(k, JSON.stringify(v)); } catch (e) {} };

export const attrIcon = (a) =>
  `https://www.db.yugioh-card.com/yugiohdb/external/image/parts/attribute/attribute_icon_${a}.png`;

// Authentic Spell / Trap card-type symbol (the 魔 / 罠 corner medallion), the
// matched set to the monster attribute icons. On every spell/trap card.
export const ST_TYPE_ICON = {
  spell: "https://ms.yugipedia.com/1/1a/SPELL-JP.svg",
  trap: "https://ms.yugipedia.com/a/aa/TRAP-JP.svg",
};

// Sub-type symbol shown inline in the type line (【魔法カード ✚】). Normal has none.
export const ST_SUBTYPE_ICON = {
  "Quick-Play": "https://ms.yugipedia.com/0/05/Quick-Play.svg",
  "Continuous": "https://ms.yugipedia.com/7/7c/Continuous.svg",
  "Equip": "https://ms.yugipedia.com/9/90/Equip.svg",
  "Field": "https://ms.yugipedia.com/1/14/Field.svg",
  "Ritual": "https://ms.yugipedia.com/f/f5/Ritual.svg",
  "Counter": "https://ms.yugipedia.com/0/06/Counter.svg",
};

export const FRAMEVAR = { normal: "--f-normal", effect: "--f-effect", ritual: "--f-ritual", fusion: "--f-fusion", synchro: "--f-synchro", xyz: "--f-xyz", link: "--f-link", spell: "--f-spell", trap: "--f-trap" };
export const FRAME = { normal: "#c9a44b", effect: "#c07a3a", ritual: "#4a74b0", fusion: "#8a5aa8", synchro: "#c0bfbe", xyz: "#555", link: "#3a7a9a", spell: "#1d9e75", trap: "#c2185b" };

export function frameColor(c) {
  const v = FRAMEVAR[c && c.frame] || (c.cardType === "spell" ? "--f-spell" : c.cardType === "trap" ? "--f-trap" : "--f-normal");
  return `var(${v})`;
}
export function frameHex(c) {
  return FRAME[c && c.frame] || (c.cardType === "spell" ? FRAME.spell : c.cardType === "trap" ? FRAME.trap : FRAME.normal);
}

export function typeLineJa(c) {
  if (c.cardType !== "monster") return (c.cardType === "spell" ? "魔法" : c.cardType === "trap" ? "罠" : "") + "カード";
  const r = c.raceJa || c.race || "", cat = c.categoryJa || c.category || "";
  return "【" + r + (cat ? "／" + cat : "") + "】";
}
export function typeLineEn(c) {
  if (c.cardType !== "monster") return (c.cardType || "").charAt(0).toUpperCase() + (c.cardType || "").slice(1) + " Card";
  return [c.race, c.category].filter(Boolean).join(" / ") + " Monster";
}

// あいうえお row header for a reading (dictionary grouping / potential sorting).
const HIRA_ROW = {};
(() => {
  const rows = ["あいうえお", "かきくけこがぎぐげご", "さしすせそざじずぜぞ", "たちつてとだぢづでど", "なにぬねの", "はひふへほばびぶべぼぱぴぷぺぽ", "まみむめも", "やゆよ", "らりるれろ", "わをん"];
  const heads = ["あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ"];
  rows.forEach((row, i) => { for (let j = 0; j < row.length; j++) HIRA_ROW[row[j]] = heads[i]; });
})();
export function rowOf(reading) { const h = katToHira(reading || ""); return HIRA_ROW[h.charAt(0)] || "他"; }

// Anchored regex from a query that uses * as a wildcard (e.g. "*の" = ends with の).
export function wildcardRe(s) {
  try { return new RegExp("^" + s.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*") + "$"); } catch (e) { return null; }
}
