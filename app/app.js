// Entry point: registers the service worker, wires the app, loads data.
import { state } from "./state.js";
import { buildControls, apply, setStatus, CAT_ORDER } from "./browse.js";
import { initFurigana, initVocabPopup } from "./furigana.js";
import { initTabs } from "./tabs.js";

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => { navigator.serviceWorker.register("sw.js").catch(() => {}); });
}

initFurigana();
initVocabPopup();
initTabs();

const json = (url, fallback) => fetch(url).then((r) => (r.ok ? r.json() : fallback)).catch(() => fallback);

Promise.all([
  fetch("cards.json").then((r) => { if (!r.ok) throw 0; return r.json(); }),
  json("packs.json", { packs: [] }),
  json("vocabulary.json", { words: [] }),
  json("game-terms.json", { terms: [] }),
]).then((res) => {
  state.CARDS = res[0].cards || [];
  state.PACKS = res[1].packs || [];
  state.VOCAB = res[2].words || [];
  state.GAMETERMS = res[3].terms || [];
  state.PACKS.forEach((p) => { state.PACKJA[p.name] = p; });
  const rs = {}, cs = {}, ps = {};
  state.CARDS.forEach((c) => { if (c.race) rs[c.race] = 1; if (c.category) cs[c.category] = 1; (c.packs || []).forEach((p) => { ps[p.pack] = 1; }); });
  state.RACES = Object.keys(rs).sort();
  state.CATS = CAT_ORDER.filter((x) => cs[x]);
  if (!state.PACKS.length) state.PACKS = Object.keys(ps).sort().map((n) => ({ name: n }));
  buildControls();
  setStatus("");
  apply();
}).catch(() => {
  setStatus("");
  document.getElementById("cardGrid").innerHTML = '<div class="frame"><div class="setup"><h3>Card data unavailable</h3>Could not load <code>cards.json</code>. Make sure you are opening this page from a web server, not directly from the filesystem.</div></div>';
});
