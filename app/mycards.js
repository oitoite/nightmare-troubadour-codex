// My Cards — saved cards (localStorage nt-cards-v2) with personal notes.
import { state } from "./state.js";
import { esc, frameColor, attrIcon, lsGet, lsSet } from "./util.js";
import { furiToggleHtml } from "./furigana.js";

export function myCards() { return lsGet("nt-cards-v2", []); }
export function isSaved(id) { return id != null && myCards().some((c) => c.id === id); }
export function saveCard(c) {
  const l = myCards();
  if (c.id != null && l.some((x) => x.id === c.id)) return;
  const cp = JSON.parse(JSON.stringify(c));
  cp.savedAt = Date.now();
  l.unshift(cp);
  lsSet("nt-cards-v2", l);
}
function removeCard(i) { const l = myCards(); l.splice(i, 1); lsSet("nt-cards-v2", l); renderMyCards(); }
function updateNote(i, t) { const l = myCards(); if (l[i]) { l[i].userNote = t; lsSet("nt-cards-v2", l); } }

export function renderMyCards() {
  const host = document.getElementById("mycardsList"), list = myCards();
  if (!list.length) {
    host.innerHTML = '<div class="frame"><div class="empty"><div class="big">No saved cards</div><br>Save cards from Card Search to collect them here.</div></div>';
    return;
  }
  host.innerHTML = "";
  list.forEach((c, i) => {
    const isMon = c.cardType === "monster";
    const fc = frameColor(c);
    const art = c.img
      ? '<img class="d-art" src="' + esc(c.img) + '" onerror="this.outerHTML=\'<div class=&quot;d-art ph&quot;>No image</div>\'">'
      : '<div class="d-art ph">No image</div>';
    const nameHtml = (c.reading && c.reading !== c.ja && c.ja)
      ? '<ruby class="d-ruby-name" style="font-size:20px">' + esc(c.ja) + '<rt>' + esc(c.reading) + '</rt></ruby>'
      : '<span class="d-ruby-name" style="font-size:20px">' + esc(c.ja || c.en || "—") + '</span>';
    const attrRow = isMon && (c.attribute || c.level != null)
      ? '<div class="d-attr-row">' +
          (c.attribute ? '<img class="d-attr-icon" src="' + attrIcon(c.attribute) + '" alt="">' : "") +
          (c.level != null ? '<span class="d-level" style="font-size:14px">' + (c.level > 0 ? new Array(c.level + 1).join("★") : "0") + '</span>' : "") +
        '</div>' : "";
    const mcJp = !!c.jpEff, mcEn = !!c.enEff, mcLang = state.currentLang || "jp";
    let effHtml = "";
    if (mcJp || mcEn) {
      effHtml += '<div class="d-eff-label" style="margin-top:10px">効果テキスト · Card Text</div>';
      if (mcJp) {
        effHtml += '<div class="eff-controls">';
        if (mcJp && mcEn) {
          effHtml += '<div class="lang-toggle">' +
            '<button class="lang-btn' + (mcLang === "jp" ? " active" : "") + '" data-mylang="jp">日本語</button>' +
            '<button class="lang-btn' + (mcLang === "en" ? " active" : "") + '" data-mylang="en">English</button>' +
            '</div>';
        } else { effHtml += '<span></span>'; }
        effHtml += furiToggleHtml() + '</div>';
      }
      if (mcJp) effHtml += '<div class="d-eff-jp mc-jp' + ((mcEn && mcLang !== "jp") ? " hidden" : "") + '" style="font-size:13px">' + (c.jpEffHtml || esc(c.jpEff)) + '</div>';
      if (mcEn) effHtml += '<div class="d-eff-en mc-en' + ((mcJp && mcLang !== "en") ? " hidden" : "") + '" style="font-size:13px">' + esc(c.enEff) + '</div>';
    }
    const stats = (isMon && (c.atk != null || c.def != null))
      ? '<div class="d-stats" style="font-size:14px">' +
          '<div class="d-stat"><small>ATK</small><span style="font-size:18px">' + (c.atk == null ? "?" : c.atk) + '</span></div>' +
          '<div class="d-stat"><small>DEF</small><span style="font-size:18px">' + (c.def == null ? "?" : c.def) + '</span></div>' +
        '</div>' : "";
    const d = document.createElement("div");
    d.className = "detail";
    d.innerHTML =
      '<div class="detail-h" style="--frameCol:' + fc + '"></div>' +
      '<div class="detail-b">' +
        '<div class="d-art-col">' + art + '</div>' +
        '<div class="d-info">' +
          '<div class="d-frame-stripe" style="background:' + fc + '"></div>' +
          '<div class="d-name-block">' + nameHtml + '<div class="d-en-name" style="font-size:13px">' + esc(c.en || "") + '</div></div>' +
          attrRow + effHtml + stats +
          '<div style="margin-top:12px">' +
            '<div class="d-eff-label">My note</div>' +
            '<textarea data-note="' + i + '" style="width:100%;background:var(--panel-2);border:1px solid var(--line);border-radius:5px;color:var(--ink);padding:8px 10px;font-family:inherit;font-size:13px;resize:vertical;min-height:44px;outline:none;" placeholder="Add your own note…">' + esc(c.userNote || "") + '</textarea>' +
          '</div>' +
          '<div class="d-actions" style="margin-top:10px"><button class="pchip" data-del="' + i + '" style="cursor:pointer">Remove</button></div>' +
        '</div>' +
      '</div>';
    d.querySelectorAll(".lang-btn[data-mylang]").forEach((btn) => {
      btn.addEventListener("click", () => {
        state.currentLang = btn.dataset.mylang;
        d.querySelectorAll(".lang-btn[data-mylang]").forEach((b) => b.classList.toggle("active", b === btn));
        const jp = d.querySelector(".mc-jp"), en = d.querySelector(".mc-en");
        if (jp) jp.classList.toggle("hidden", state.currentLang !== "jp");
        if (en) en.classList.toggle("hidden", state.currentLang !== "en");
      });
    });
    host.appendChild(d);
  });
  host.querySelectorAll("[data-del]").forEach((b) => { b.addEventListener("click", () => removeCard(parseInt(b.dataset.del, 10))); });
  host.querySelectorAll("[data-note]").forEach((t) => { t.addEventListener("change", () => updateNote(parseInt(t.dataset.note, 10), t.value)); });
}
