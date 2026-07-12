// Packs tab — booster-pack gallery and per-pack cards grouped by rarity.
import { state } from "./state.js";
import { esc } from "./util.js";
import { makeTile } from "./browse.js";

let PACKCARDS = null;
function packCardsMap() {
  if (PACKCARDS) return PACKCARDS;
  PACKCARDS = {};
  state.CARDS.forEach((c) => { (c.packs || []).forEach((p) => { (PACKCARDS[p.pack] = PACKCARDS[p.pack] || []).push(c); }); });
  return PACKCARDS;
}

export function renderPacks() {
  const host = document.getElementById("packsList");
  document.getElementById("packDetail").style.display = "none";
  host.style.display = "";
  const pc = packCardsMap();
  let html = '<div class="pack-intro">The game\'s 23 booster packs. Tap one to see its cards by rarity.</div><div class="pack-grid">';
  state.PACKS.forEach((p) => {
    if (!p.name) return;
    const n = (pc[p.name] || []).length;
    html += '<button class="pack-tile" type="button" data-pack="' + esc(p.name) + '">' +
      (p.img ? '<img class="pt-img" src="' + esc(p.img) + '" alt="" loading="lazy">' : '<div class="pt-img ph">❖</div>') +
      '<div class="pt-text">' +
        '<div class="pt-ja">' + esc(p.ja || p.name) + '</div>' +
        '<div class="pt-en">' + esc(p.name) + '</div>' +
        '<div class="pt-count">' + n + ' cards</div>' +
      '</div>' +
    '</button>';
  });
  html += '</div>';
  host.innerHTML = html;
  host.querySelectorAll(".pack-tile").forEach((b) => { b.addEventListener("click", () => renderPackCards(b.dataset.pack)); });
}

const RARITY_ORDER = ["Ultra Rare", "Super Rare", "Rare", "Common"];
export function renderPackCards(packName) {
  const list = document.getElementById("packsList");
  list.style.display = "none";
  const host = document.getElementById("packDetail");
  host.style.display = "";
  const pj = state.PACKJA[packName], ja = (pj && pj.ja) ? pj.ja : "";
  const cards = packCardsMap()[packName] || [];
  const byRar = {};
  cards.forEach((c) => {
    const pe = (c.packs || []).filter((p) => p.pack === packName)[0];
    const rar = (pe && pe.rarity) || "Common";
    (byRar[rar] = byRar[rar] || []).push(c);
  });
  const rars = Object.keys(byRar).sort((a, b) => { const ia = RARITY_ORDER.indexOf(a), ib = RARITY_ORDER.indexOf(b); return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib); });
  const pimg = (pj && pj.img) ? pj.img : "";
  host.innerHTML = '<button class="d-back" id="packsBack" type="button">← All packs</button>' +
    '<div class="pack-head">' +
      (pimg ? '<img class="ph-img" src="' + esc(pimg) + '" alt="" loading="lazy">' : '') +
      '<div class="pack-head-txt"><div class="ph-ja">' + esc(ja || packName) + '</div><div class="ph-en">' + esc(packName) + ' · ' + cards.length + ' cards</div></div>' +
    '</div>';
  rars.forEach((rar) => {
    const g = document.createElement("div");
    g.innerHTML = '<div class="pack-rar-hdr">' + esc(rar) + '<span>' + byRar[rar].length + '</span></div>';
    const grid = document.createElement("div");
    grid.className = "card-grid";
    byRar[rar].forEach((c) => grid.appendChild(makeTile(c)));
    g.appendChild(grid);
    host.appendChild(g);
  });
  document.getElementById("packsBack").addEventListener("click", () => { renderPacks(); window.scrollTo({ top: 0, behavior: "smooth" }); });
  window.scrollTo({ top: 0, behavior: "smooth" });
}
