// Furigana show/hide toggle + tap-to-define popup.
import { state } from "./state.js";
import { lsSet } from "./util.js";

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
  document.querySelectorAll(".vocab.active").forEach((a) => a.classList.remove("active"));
}

function showVocabPop(el) {
  const w = vocabMap()[el.getAttribute("data-w")];
  if (!w) return;
  if (!vocabPop) {
    vocabPop = document.createElement("div");
    vocabPop.className = "vocab-pop";
    vocabPop.innerHTML = '<div class="vp-ja"></div><div class="vp-reading"></div><div class="vp-en"></div>';
    document.body.appendChild(vocabPop);
  }
  hideVocabPop();
  vocabPop.querySelector(".vp-ja").textContent = el.getAttribute("data-w");
  vocabPop.querySelector(".vp-reading").textContent = w.reading || "";
  vocabPop.querySelector(".vp-en").textContent = w.en || "—";
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

export function initVocabPopup() {
  document.addEventListener("click", (e) => {
    const v = e.target && e.target.closest ? e.target.closest(".vocab") : null;
    if (v) { showVocabPop(v); return; }
    hideVocabPop();
  });
}
