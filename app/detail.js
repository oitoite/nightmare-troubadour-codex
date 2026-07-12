// Card detail view — a global overlay shown from any tab.
import { state } from "./state.js";
import { esc, frameColor, attrIcon, typeLineJa, typeLineEn } from "./util.js";
import { furiToggleHtml, hideVocabPop } from "./furigana.js";
import { saveCard, isSaved } from "./mycards.js";
import { showTabSection, switchTab, TABS } from "./tabs.js";
import { renderPackCards } from "./packs.js";

export function showDetail(c) {
  hideVocabPop();
  const host = document.getElementById("detail");
  TABS.forEach((t) => { const el = document.getElementById("tab-" + t); if (el) el.style.display = "none"; });
  host.style.display = "";

  const isMon = c.cardType === "monster";
  const fc = frameColor(c);

  // 1. Art column
  const artHtml = c.img
    ? '<img class="d-art" src="' + esc(c.img) + '" alt="' + esc(c.en) + '" onerror="this.outerHTML=\'<div class=&quot;d-art ph&quot;>No image</div>\'">'
    : '<div class="d-art ph">No image</div>';

  // 2. Name with ruby
  const nameHtml = (c.reading && c.reading !== c.ja && c.ja)
    ? '<ruby class="d-ruby-name">' + esc(c.ja) + '<rt>' + esc(c.reading) + '</rt></ruby>'
    : '<span class="d-ruby-name">' + esc(c.ja || c.en || "—") + '</span>';

  // 3. Attribute + level / property row
  let attrRow = "";
  if (isMon) {
    if (c.attribute) attrRow += '<img class="d-attr-icon" src="' + attrIcon(c.attribute) + '" alt="' + esc(c.attribute.toUpperCase()) + '" title="' + esc(c.attribute.toUpperCase()) + '">';
    if (c.level != null) {
      attrRow += '<span class="d-level">' + (c.level > 0 ? new Array(c.level + 1).join("★") : "0") + '</span>';
      attrRow += '<span style="font-family:\'Cinzel\',serif;font-size:11px;color:var(--ink-3);letter-spacing:.06em;margin-left:2px">Lv.' + c.level + '</span>';
    }
  } else {
    const kind = c.cardType === "spell" ? "魔法" : "罠";
    const propLabel = c.spellTrapTypeJa ? (c.spellTrapTypeJa + kind) : (kind + "カード");
    const propEn = c.spellTrapType ? (c.spellTrapType + " " + (c.cardType === "spell" ? "Spell" : "Trap")) : ((c.cardType === "spell" ? "Spell" : "Trap") + " Card");
    attrRow += '<span class="d-prop-tag" title="' + esc(propEn) + '">' + esc(propLabel) + '</span>';
  }

  // 4. Type line
  const typeJa = typeLineJa(c);
  const typeEn = typeLineEn(c);

  // 5. Effect text with JP/EN toggle
  const hasJp = !!c.jpEff, hasEn = !!c.enEff;
  const langInit = state.currentLang || "jp";
  let effHtml = "";
  if (hasJp || hasEn) {
    effHtml = '<div class="eff-controls"><div class="lang-toggle">' +
      '<button class="lang-btn' + (langInit === "jp" ? " active" : "") + '" data-lang="jp">日本語</button>' +
      '<button class="lang-btn' + (langInit === "en" ? " active" : "") + '" data-lang="en">English</button>' +
      '</div>' + (hasJp ? furiToggleHtml() : '') + '</div>';
    if (hasJp) effHtml += '<div class="d-eff-jp' + (langInit !== "jp" ? " hidden" : "") + '" id="effJp">' + (c.jpEffHtml || esc(c.jpEff)) + '</div>';
    if (hasEn) effHtml += '<div class="d-eff-en' + (langInit !== "en" ? " hidden" : "") + '" id="effEn">' + esc(c.enEff) + '</div>';
  }

  // 6. ATK / DEF
  let statsHtml = "";
  if (isMon && (c.atk != null || c.def != null)) {
    statsHtml = '<div class="d-stats">' +
      '<div class="d-stat"><small>ATK</small><span>' + (c.atk == null ? "?" : c.atk) + '</span></div>' +
      '<div class="d-stat"><small>DEF</small><span>' + (c.def == null ? "?" : c.def) + '</span></div>' +
      '</div>';
  }

  // 7. Passcode
  const passcodeHtml = c.passcode ? '<div class="d-passcode">✦ ' + esc(c.passcode) + '</div>' : '';

  // 8. Pack filter chips
  let packChips = "";
  if (c.packs && c.packs.length) {
    packChips = '<div class="d-packs"><div class="d-eff-label">収録パック · In packs</div>';
    c.packs.forEach((p) => {
      const ja = state.PACKJA[p.pack] && state.PACKJA[p.pack].ja;
      packChips += '<span class="pchip" data-pack="' + esc(p.pack) + '">' + esc(p.pack) + (ja ? ' <b>' + esc(ja) + '</b>' : '') + (p.rarity ? ' <em class="pchip-rar">' + esc(p.rarity) + '</em>' : '') + '</span>';
    });
    packChips += "</div>";
  }

  // 9. External links
  let linksHtml = '<div class="d-links">';
  if (c.id) {
    const cid = encodeURIComponent(c.id);
    linksHtml += '<a class="ext-link" href="https://db.ygoresources.com/card#' + cid + ':ja" target="_blank" rel="noopener">YGOResources 日本語</a>';
    linksHtml += '<a class="ext-link" href="https://db.ygoresources.com/card#' + cid + '" target="_blank" rel="noopener">YGOResources EN</a>';
  }
  if (c.en) {
    linksHtml += '<a class="ext-link" href="https://yugipedia.com/wiki/' + encodeURIComponent(c.en.replace(/ /g, "_")) + '" target="_blank" rel="noopener">Yugipedia</a>';
  }
  linksHtml += "</div>";

  host.innerHTML =
    '<div class="detail"><div class="detail-h" style="--frameCol:' + fc + '"></div>' +
    '<div class="d-backbar"><button class="d-back" id="backTop" type="button">← Back to cards</button></div>' +
    '<div class="detail-b">' +
      '<div class="d-art-col">' + artHtml + '</div>' +
      '<div class="d-info">' +
        '<div class="d-frame-stripe" style="background:' + fc + '"></div>' +
        '<div class="d-name-block">' + nameHtml + '<div class="d-en-name">' + esc(c.en || "") + '</div></div>' +
        (attrRow ? '<div class="d-attr-row">' + attrRow + '</div>' : '') +
        '<div class="d-typeline"><div class="jp">' + (c.typeLineJaHtml || esc(typeJa)) + '</div><div class="en">' + esc(typeEn) + '</div></div>' +
        (effHtml ? '<div class="d-eff-wrap">' + effHtml + '</div>' : '') +
        statsHtml +
        passcodeHtml +
        packChips +
        linksHtml +
        '<div class="d-actions">' +
          '<button class="search-btn" id="saveBtn" style="font-size:13px;padding:8px 18px;">✦ Save to My Cards</button>' +
          '<button class="pchip" id="backBtn" style="cursor:pointer;margin-left:8px;">← Back</button>' +
        '</div>' +
      '</div>' +
    '</div></div>';

  // JP/EN toggle
  if (hasJp || hasEn) {
    host.querySelectorAll(".lang-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        state.currentLang = btn.dataset.lang;
        host.querySelectorAll(".lang-btn").forEach((b) => b.classList.toggle("active", b === btn));
        const jpEl = document.getElementById("effJp");
        const enEl = document.getElementById("effEn");
        if (jpEl) jpEl.classList.toggle("hidden", state.currentLang !== "jp");
        if (enEl) enEl.classList.toggle("hidden", state.currentLang !== "en");
      });
    });
  }

  const closeDetail = () => { showTabSection(state.activeTab); window.scrollTo({ top: 0, behavior: "smooth" }); };
  document.getElementById("backBtn").addEventListener("click", closeDetail);
  const backTop = document.getElementById("backTop");
  if (backTop) backTop.addEventListener("click", closeDetail);
  const sb = document.getElementById("saveBtn");
  sb.addEventListener("click", () => { saveCard(c); sb.textContent = "✓ Saved"; sb.disabled = true; });
  if (isSaved(c.id)) { sb.textContent = "✓ In My Cards"; sb.disabled = true; }
  host.querySelectorAll(".pchip[data-pack]").forEach((ch) => { ch.addEventListener("click", () => { switchTab("packs"); renderPackCards(ch.dataset.pack); }); });
  window.scrollTo({ top: 0, behavior: "smooth" });
}
