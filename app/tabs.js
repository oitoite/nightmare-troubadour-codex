// Top/bottom nav and the global card-detail overlay's tab model.
import { state } from "./state.js";
import { hideVocabPop } from "./furigana.js";
import { renderMyCards } from "./mycards.js";
import { renderDict } from "./dictionary.js";
import { renderPacks } from "./packs.js";

export const TABS = ["browse", "packs", "mycards", "dict"];

export function showTabSection(name) {
  hideVocabPop();
  const d = document.getElementById("detail");
  d.style.display = "none";
  d.innerHTML = "";
  TABS.forEach((t) => { const el = document.getElementById("tab-" + t); if (el) el.style.display = (t === name) ? "" : "none"; });
}

export function switchTab(name) {
  state.activeTab = name;
  document.querySelectorAll(".tab").forEach((t) => t.classList.toggle("active", t.dataset.tab === name));
  showTabSection(name);
  window.scrollTo({ top: 0, behavior: "smooth" });
  if (name === "mycards") renderMyCards();
  if (name === "dict") renderDict();
  if (name === "packs") renderPacks();
}

export function initTabs() {
  document.querySelectorAll(".tab").forEach((t) => { t.addEventListener("click", () => switchTab(t.dataset.tab)); });
}
