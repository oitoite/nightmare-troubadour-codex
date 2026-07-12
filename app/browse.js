// Cards tab: search, filters, sorting, and the card grid.
import { state } from "./state.js";
import { esc, katToHira, frameHex, attrIcon, wildcardRe } from "./util.js";
import { showDetail } from "./detail.js";

export const ATTRS = ["dark", "light", "earth", "water", "fire", "wind", "divine"];
export const CAT_ORDER = ["Normal", "Effect", "Ritual", "Fusion", "Synchro", "Xyz", "Pendulum", "Link", "Toon", "Spirit", "Union", "Gemini", "Tuner", "Flip"];

export function setStatus(h) {
  const el = document.getElementById("status");
  if (!h) { el.style.display = "none"; el.innerHTML = ""; return; }
  el.style.display = ""; el.innerHTML = h;
}

const mkBtn = (html) => { const b = document.createElement("button"); b.className = "kbtn"; b.innerHTML = html; return b; };

function toggle(map, key, btn) {
  if (map[key]) { delete map[key]; btn.classList.remove("on"); }
  else { map[key] = 1; btn.classList.add("on"); }
  apply();
}

function syncRows() {
  const showMon = (state.typeSel === "" || state.typeSel === "monster");
  document.getElementById("row-race").style.display = showMon ? "" : "none";
  document.getElementById("row-cat").style.display = showMon ? "" : "none";
}

function clearSection(which) {
  if (which === "attr") state.activeAttrs = {};
  else if (which === "race") state.activeRaces = {};
  else if (which === "cat") state.activeCats = {};
  else if (which === "lvl") state.activeLevels = {};
  else if (which === "stat") ["f-atk-min", "f-atk-max", "f-def-min", "f-def-max"].forEach((id) => { document.getElementById(id).value = ""; });
  else if (which === "pack") document.getElementById("f-pack").value = "";
  refreshOn();
  apply();
}

function refreshOn() {
  const af = document.getElementById("f-attrs").children;
  for (let i = 0; i < af.length; i++) af[i].classList.toggle("on", !!state.activeAttrs[ATTRS[i]]);
  const rf = document.getElementById("f-races").children;
  for (let j = 0; j < rf.length; j++) rf[j].classList.toggle("on", !!state.activeRaces[state.RACES[j]]);
  const cf = document.getElementById("f-cats").children;
  for (let k = 0; k < cf.length; k++) cf[k].classList.toggle("on", !!state.activeCats[state.CATS[k]]);
  const lf = document.getElementById("f-levels").children;
  for (let m = 0; m < lf.length; m++) lf[m].classList.toggle("on", !!state.activeLevels[m]);
}

export function buildControls() {
  const ps = document.getElementById("f-pack");
  state.PACKS.forEach((p) => { const o = document.createElement("option"); o.value = p.name; o.textContent = p.ja ? (p.name + " — " + p.ja) : p.name; ps.appendChild(o); });
  const af = document.getElementById("f-attrs");
  ATTRS.forEach((a) => { const b = mkBtn('<img src="' + attrIcon(a) + '" alt="">' + a.toUpperCase()); b.addEventListener("click", () => toggle(state.activeAttrs, a, b)); af.appendChild(b); });
  const rf = document.getElementById("f-races");
  state.RACES.forEach((r) => { const b = mkBtn(esc(r)); b.addEventListener("click", () => toggle(state.activeRaces, r, b)); rf.appendChild(b); });
  const cf = document.getElementById("f-cats");
  state.CATS.forEach((c) => { const b = mkBtn(esc(c)); b.addEventListener("click", () => toggle(state.activeCats, c, b)); cf.appendChild(b); });
  const lf = document.getElementById("f-levels");
  for (let i = 0; i <= 12; i++) { const n = i; const b = mkBtn(String(n)); b.addEventListener("click", () => toggle(state.activeLevels, n, b)); lf.appendChild(b); }
  document.getElementById("f-pack").addEventListener("change", apply);
  ["f-atk-min", "f-atk-max", "f-def-min", "f-def-max"].forEach((id) => { document.getElementById(id).addEventListener("input", debounced); });
  document.querySelectorAll(".typetab").forEach((t) => { t.addEventListener("click", () => { state.typeSel = t.dataset.type; document.querySelectorAll(".typetab").forEach((x) => x.classList.toggle("active", x === t)); syncRows(); apply(); }); });
  document.querySelectorAll("[data-clear]").forEach((x) => { x.addEventListener("click", () => clearSection(x.dataset.clear)); });
  document.getElementById("mode").addEventListener("change", (e) => { state.mode = e.target.value; apply(); });
  document.getElementById("sortSel").addEventListener("change", (e) => { state.sortMode = e.target.value; apply(); });
  document.getElementById("filtersToggle").addEventListener("click", function () {
    const fp = document.getElementById("filterPanel"), show = !this.classList.contains("open");
    fp.style.display = show ? "block" : "none";
    this.classList.toggle("open", show);
  });
  document.getElementById("qclr").addEventListener("click", () => { document.getElementById("q").value = ""; apply(); });
  document.getElementById("q").addEventListener("input", debounced);
  document.getElementById("q").addEventListener("keydown", (e) => { if (e.key === "Enter") { clearTimeout(dbt); apply(); } });
  syncRows();
}

let dbt;
function debounced() { clearTimeout(dbt); dbt = setTimeout(apply, 220); }
const num = (id) => { const v = document.getElementById(id).value.trim(); return v === "" ? null : parseInt(v, 10); };

function matchPacks(query) {
  const q = query.toLowerCase(), o = {};
  state.PACKS.forEach((p) => { if ((p.name && p.name.toLowerCase().indexOf(q) >= 0) || (p.ja && p.ja.indexOf(query) >= 0) || (p.romaji && p.romaji.toLowerCase().indexOf(q) >= 0)) o[p.name] = 1; });
  return o;
}

// Card-name match: kana-insensitive (hiragana↔katakana) + * wildcards; falls back to substring.
function nameMatch(c, q) {
  const qH = katToHira(q), qL = q.toLowerCase();
  const jaH = katToHira(c.ja || ""), rdH = katToHira(c.reading || ""), en = (c.en || "").toLowerCase();
  if (q.indexOf("*") >= 0) {
    const reH = wildcardRe(qH), reL = wildcardRe(qL);
    return !!((reH && (reH.test(jaH) || reH.test(rdH))) || (reL && reL.test(en)));
  }
  return jaH.indexOf(qH) >= 0 || rdH.indexOf(qH) >= 0 || en.indexOf(qL) >= 0;
}

function sortCards(list) {
  const m = state.sortMode;
  if (m === "atk") return list.sort((a, b) => (b.atk == null ? -1 : b.atk) - (a.atk == null ? -1 : a.atk));
  if (m === "def") return list.sort((a, b) => (b.def == null ? -1 : b.def) - (a.def == null ? -1 : a.def));
  if (m === "level") return list.sort((a, b) => (b.level == null ? -1 : b.level) - (a.level == null ? -1 : a.level));
  if (m === "en") return list.sort((a, b) => (a.en || "").localeCompare(b.en || ""));
  return list.sort((a, b) => { const ka = katToHira(a.reading || a.ja || ""), kb = katToHira(b.reading || b.ja || ""); return ka < kb ? -1 : ka > kb ? 1 : 0; });
}

export function apply() {
  const q = document.getElementById("q").value.trim(), qL = q.toLowerCase();
  const pack = document.getElementById("f-pack").value;
  const amin = num("f-atk-min"), amax = num("f-atk-max"), dmin = num("f-def-min"), dmax = num("f-def-max");
  const attrs = Object.keys(state.activeAttrs), races = Object.keys(state.activeRaces), cats = Object.keys(state.activeCats), levels = Object.keys(state.activeLevels).map(Number);
  const packMatch = q && state.mode === "name" ? matchPacks(q) : {};
  const res = state.CARDS.filter((c) => {
    if (state.typeSel && c.cardType !== state.typeSel) return false;
    if (pack && !(c.packs || []).some((p) => p.pack === pack)) return false;
    if (races.length && (!c.race || races.indexOf(c.race) < 0)) return false;
    if (cats.length && (!c.category || cats.indexOf(c.category) < 0)) return false;
    if (attrs.length && (!c.attribute || attrs.indexOf(c.attribute) < 0)) return false;
    if (levels.length && (c.level == null || levels.indexOf(c.level) < 0)) return false;
    if (amin != null && (c.atk == null || c.atk < amin)) return false;
    if (amax != null && (c.atk == null || c.atk > amax)) return false;
    if (dmin != null && (c.def == null || c.def < dmin)) return false;
    if (dmax != null && (c.def == null || c.def > dmax)) return false;
    if (q) {
      if (state.mode === "text") { const qH = katToHira(q); if (!(katToHira(c.jpEff || "").indexOf(qH) >= 0 || (c.enEff && c.enEff.toLowerCase().indexOf(qL) >= 0))) return false; }
      else { const inCard = nameMatch(c, q); const inPack = (c.packs || []).some((p) => packMatch[p.pack]); if (!inCard && !inPack) return false; }
    }
    return true;
  });
  sortCards(res);
  document.getElementById("count").innerHTML = "<b>" + res.length + "</b> of " + state.CARDS.length + " cards";
  renderGrid(res);
}

export function makeTile(c) {
  const fc = frameHex(c);
  const imgHtml = c.img
    ? '<img class="tile-img" loading="lazy" src="' + esc(c.img) + '" alt="' + esc(c.en) + '" onerror="this.className=\'tile-img ph\';this.removeAttribute(\'src\');this.textContent=\'No image\';">'
    : '<div class="tile-img ph">No image</div>';
  const tile = document.createElement("div");
  tile.className = "card-tile";
  tile.style.borderColor = fc;
  tile.style.setProperty("--tile-glow", fc);
  tile.innerHTML = imgHtml +
    '<div class="tile-en-overlay">' + esc(c.en || "") + '</div>' +
    '<div class="tile-body">' +
      (c.reading && c.reading !== c.ja ? '<span class="tile-ruby">' + esc(c.reading) + '</span>' : '') +
      '<div class="tile-jp">' + esc(c.ja || c.en || "—") + '</div>' +
    '</div>';
  tile.addEventListener("click", () => showDetail(c));
  return tile;
}

export function renderGrid(list) {
  const host = document.getElementById("cardGrid");
  if (!list.length) {
    host.innerHTML = '<div class="empty" style="grid-column:1/-1"><div class="big">No cards found</div><br>Try fewer filters or a shorter search.</div>';
    return;
  }
  host.innerHTML = "";
  list.slice(0, 400).forEach((c) => host.appendChild(makeTile(c)));
  if (list.length > 400) {
    const hint = document.createElement("div");
    hint.className = "hint";
    hint.style.gridColumn = "1 / -1";
    hint.textContent = "Showing first 400 of " + list.length + ". Narrow your search to see more.";
    host.appendChild(hint);
  }
}
