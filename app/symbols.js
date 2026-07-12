// Static meanings for card symbols (attribute / level / spell-trap type).
// Surfaced contextually via the tap-to-define popup, not as a standing legend.

export const SYMBOL_INFO = {
  attr: {
    light:  { label: "LIGHT",  ja: "光", meaning: "Light attribute — Fairy and other bright monsters; opposes DARK." },
    dark:   { label: "DARK",   ja: "闇", meaning: "Dark attribute — Fiend, undead and shadow monsters; opposes LIGHT." },
    water:  { label: "WATER",  ja: "水", meaning: "Water attribute — aquatic and ice monsters; opposes FIRE." },
    fire:   { label: "FIRE",   ja: "炎", meaning: "Fire attribute — flame monsters; opposes WATER." },
    earth:  { label: "EARTH",  ja: "地", meaning: "Earth attribute — ground-dwelling monsters; opposes WIND." },
    wind:   { label: "WIND",   ja: "風", meaning: "Wind attribute — flying and air monsters; opposes EARTH." },
    divine: { label: "DIVINE", ja: "神", meaning: "Divine attribute — the Egyptian God cards." },
  },
  spell: {
    "Normal":     { label: "Normal Spell",     ja: "通常魔法",     meaning: "Resolves once, then goes to the Graveyard." },
    "Quick-Play": { label: "Quick-Play Spell", ja: "速攻魔法",     meaning: "Can be played from the hand at fast timing, even on the opponent's turn." },
    "Continuous": { label: "Continuous Spell", ja: "永続魔法",     meaning: "Stays on the field and keeps its effect active." },
    "Equip":      { label: "Equip Spell",      ja: "装備魔法",     meaning: "Attaches to a monster to change its stats or grant an effect." },
    "Field":      { label: "Field Spell",      ja: "フィールド魔法", meaning: "Fills the field zone and affects the whole board." },
    "Ritual":     { label: "Ritual Spell",     ja: "儀式魔法",     meaning: "Used to Ritual Summon a Ritual Monster." },
  },
  trap: {
    "Normal":     { label: "Normal Trap",     ja: "通常罠",     meaning: "Set first, then activated on a later turn." },
    "Continuous": { label: "Continuous Trap", ja: "永続罠",     meaning: "Stays on the field and keeps its effect active." },
    "Counter":    { label: "Counter Trap",    ja: "カウンター罠", meaning: "A fast trap that negates or responds to other cards." },
  },
};

// Resolve a symbol to { label, ja, meaning } or null.
export function symbolInfo(kind, key) {
  if (kind === "level") {
    return {
      label: "Level " + key,
      ja: "レベル" + key,
      meaning: "Higher level = stronger, but harder to Summon (Levels 5–6 need 1 Tribute, 7+ need 2).",
    };
  }
  const table = SYMBOL_INFO[kind];
  if (!table) return null;
  const k = kind === "attr" ? String(key || "").toLowerCase() : key;
  return table[k] || null;
}
