// Shared, mutable app state. Modules read/write fields on this single object so
// live values are visible everywhere without fighting ES-module binding rules.
import { lsGet } from "./util.js";

export const state = {
  // data (populated by app.js on load)
  CARDS: [],
  PACKS: [],
  PACKJA: {},
  RACES: [],
  CATS: [],
  VOCAB: [],
  GAMETERMS: [],

  // view/preference state
  currentLang: "jp",
  currentFurigana: lsGet("nt-furigana", true),
  activeTab: "browse",

  // browse/filter state
  activeAttrs: {},
  activeRaces: {},
  activeCats: {},
  activeLevels: {},
  typeSel: "",
  mode: "name",
  sortMode: "reading",
};
