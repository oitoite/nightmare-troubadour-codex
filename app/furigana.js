// Furigana show/hide toggle + tap-to-define popup.
import { state } from "./state.js";
import { lsSet } from "./util.js";
import { symbolInfo } from "./symbols.js";

export function furiToggleHtml() {
  return `<button type="button" class="furi-toggle${state.currentFurigana ? " active" : ""}" aria-pressed="${state.currentFurigana ? "true" : "false"}"><span class="fdot"></span>ふりがな</button>`;
}

export function applyFurigana() {
  document.body.classList.toggle("furigana-off", !state.currentFurigana);
  document.querySelectorAll(".furi-toggle").forEach((b) => {
    b.classList.toggle("active", state.currentFurigana);
    b.setAttribute("aria-pressed", state.currentFurigana ? "true" : "false");
  });
}

export function initFurigana() {
  document.addEventListener("click", (e) => {
    const b = e.target && e.target.closest ? e.target.closest(".furi-toggle") : null;
    if (!b) return;
    state.currentFurigana = !state.currentFurigana;
    lsSet("nt-furigana", state.currentFurigana);
    applyFurigana();
  });
  applyFurigana();
}

// ---- tap-to-define ----
let VOCABMAP = null;
function vocabMap() {
  if (!VOCABMAP) {
    VOCABMAP = {};
    for (const w of state.VOCAB) if (w && w.ja && !VOCABMAP[w.ja]) VOCABMAP[w.ja] = w;
  }
  return VOCABMAP;
}

let vocabPop = null;
export function hideVocabPop() {
  if (vocabPop) vocabPop.classList.remove("show");
  document.querySelectorAll(".vocab.active, .symdef.active").forEach((a) => a.classList.remove("active"));
}

function ensurePop() {
  if (!vocabPop) {
    vocabPop = document.createElement("div");
    vocabPop.className = "vocab-pop";
    vocabPop.innerHTML = '<div class="vp-ja"></div><div class="vp-reading"></div><div class="vp-en"></div>';
    document.body.appendChild(vocabPop);
  }
  return vocabPop;
}

// Shared: fill the popup, mark the trigger active, position it under the trigger.
function openPop(el, ja, reading, en) {
  ensurePop();
  hideVocabPop();
  vocabPop.querySelector(".vp-ja").textContent = ja;
  vocabPop.querySelector(".vp-reading").textContent = reading || "";
  vocabPop.querySelector(".vp-en").textContent = en || "—";
  el.classList.add("active");
  vocabPop.classList.add("show");
  const r = el.getBoundingClientRect(), pw = vocabPop.offsetWidth;
  let left = r.left + window.pageXOffset;
  const top = r.bottom + window.pageYOffset + 6;
  const maxL = window.pageXOffset + document.documentElement.clientWidth - pw - 8;
  if (left > maxL) left = maxL;
  if (left < window.pageXOffset + 8) left = window.pageXOffset + 8;
  vocabPop.style.left = left + "px";
  vocabPop.style.top = top + "px";
}

function showVocabPop(el) {
  const w = vocabMap()[el.getAttribute("data-w")];
  if (!w) return;
  openPop(el, el.getAttribute("data-w"), w.reading, w.en);
}

function showSymbolPop(el) {
  const info = symbolInfo(el.getAttribute("data-symkind"), el.getAttribute("data-symkey"));
  if (!info) return;
  openPop(el, info.label, info.ja, info.meaning);
}

export function initVocabPopup() {
  document.addEventListener("click", (e) => {
    if (!e.target || !e.target.closest) return;
    const sym = e.target.closest(".symdef");
    if (sym) { showSymbolPop(sym); return; }
    const v = e.target.closest(".vocab");
    if (v) { showVocabPop(v); return; }
    hideVocabPop();
  });
}
