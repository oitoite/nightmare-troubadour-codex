// Dictionary tab — effect-text words (あいうえお) and game/menu terms (by category).
import { state } from "./state.js";
import { esc, katToHira, rowOf } from "./util.js";

let dictWired = false, dictMode = "words", dictEntries = [];

function buildDictEntries() {
  const out = [];
  if (dictMode === "game") {
    state.GAMETERMS.forEach((t) => out.push({ ja: t.ja, reading: t.reading || "", en: t.en || "", group: t.cat || "—" }));
  } else {
    const src = [];
    if (state.VOCAB.length) {
      state.VOCAB.forEach((w) => src.push({ ja: w.ja, reading: w.reading || "", en: w.en || "", sortKey: w.reading || w.ja || "" }));
    } else {
      const seen = {};
      state.CARDS.forEach((c) => { const k = c.ja || ""; if (!k || seen[k]) return; seen[k] = 1; src.push({ ja: c.ja, reading: c.reading || "", en: c.en || "", sortKey: katToHira(c.reading || c.ja || "") }); });
    }
    src.sort((a, b) => (a.sortKey < b.sortKey ? -1 : a.sortKey > b.sortKey ? 1 : 0));
    src.forEach((e) => { e.group = rowOf(e.reading || e.ja || "") + "行"; out.push(e); });
  }
  return out;
}

function dictHintText() {
  return dictMode === "game"
    ? state.GAMETERMS.length + " common game & menu terms — grouped by where you'll see them"
    : dictEntries.length + " words from card effect text — sorted by reading (あいうえお)";
}

function dictRender(filter) {
  dictEntries = buildDictEntries();
  document.getElementById("dictHint").textContent = dictHintText();
  const q = (filter || "").trim();
  let list = dictEntries;
  if (q) {
    const qL = q.toLowerCase(), qH = katToHira(q);
    list = dictEntries.filter((e) => e.ja.indexOf(q) >= 0 || katToHira(e.ja).indexOf(qH) >= 0 || e.reading.indexOf(q) >= 0 || e.en.toLowerCase().indexOf(qL) >= 0);
  }
  renderDictRows(list);
}

export function renderDict() {
  if (!state.CARDS.length) { document.getElementById("dictBody").innerHTML = '<div class="empty"><span class="big">Loading…</span></div>'; return; }
  if (!dictWired) {
    dictWired = true;
    document.getElementById("dictQ").addEventListener("input", (e) => dictRender(e.target.value));
    document.querySelectorAll(".dict-mode").forEach((b) => {
      b.addEventListener("click", () => {
        dictMode = b.dataset.dmode;
        document.querySelectorAll(".dict-mode").forEach((x) => x.classList.toggle("active", x === b));
        document.getElementById("dictQ").value = "";
        dictRender("");
      });
    });
  }
  dictRender(document.getElementById("dictQ").value);
}

function renderDictRows(entries) {
  const body = document.getElementById("dictBody");
  if (!entries.length) { body.innerHTML = '<div class="empty"><span class="big">No results</span></div>'; return; }
  let html = '<table class="dict-table"><thead><tr><th>日本語</th><th>読み方</th><th>English</th></tr></thead><tbody>';
  let curG = "";
  entries.forEach((e) => {
    if (e.group !== curG) { curG = e.group; html += '<tr class="dict-group-hdr"><td colspan="3">' + esc(curG) + '</td></tr>'; }
    const hira = katToHira(e.reading || "");
    const showReading = (e.reading && e.reading !== e.ja) ? hira : "";
    html += '<tr class="dict-row"><td>' + esc(e.ja) + '</td><td>' + esc(showReading) + '</td><td>' + esc(e.en) + '</td></tr>';
  });
  html += '</tbody></table>';
  body.innerHTML = html;
}
