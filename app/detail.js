// Card detail view — a global overlay shown from any tab.
import { state } from "./state.js";
import { esc, frameColor, frameHex, attrIcon, ST_TYPE_ICON, ST_SUBTYPE_ICON, typeLineJa, typeLineEn } from "./util.js";
import { furiToggleHtml, hideVocabPop } from "./furigana.js";
import { saveCard, isSaved } from "./mycards.js";
import { showTabSection, switchTab, TABS } from "./tabs.js";
import { renderPackCards } from "./packs.js";

// JP effect inner HTML. When JP sentences (split on 。) align 1:1 with English
// sentences, each JP sentence is tappable to peek its English inline. Otherwise
// falls back to a single "Show English translation" toggle for the full text.
function buildJpEffInner(c, hasEn) {
  const rawHtml = c.jpEffHtml || esc(c.jpEff);
  if (!hasEn) return rawHtml;
  const jpChunks = rawHtml.split(/(?<=。)/).filter((s) => s.trim());
  const enParts = String(c.enEff).split(/(?<=[.;])\s+/).map((s) => s.trim()).filter(Boolean);
  if (jpChunks.length > 1 && jpChunks.length === enParts.length) {
    return jpChunks.map((ch, i) => '<span class="jp-sent" data-en="' + esc(enParts[i]) + '">' + ch + '</span>').join("");
  }
  // Sentences don't split 1:1 — no inline peek; the JP/EN toggle covers full translation.
  return rawHtml;
}

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
  // Top-right badge: monsters show the attribute icon; spells/traps show the
  // 魔/罠 card-type medallion (on every spell/trap, matching real cards). Below
  // the name: level stars (monsters) or the sub-type tag (spells/traps).
  let badgeHtml = "", starsHtml = "";
  if (isMon) {
    if (c.attribute) badgeHtml = '<img class="d-attr-icon symdef" data-symkind="attr" data-symkey="' + esc(c.attribute) + '" src="' + attrIcon(c.attribute) + '" alt="' + esc(c.attribute.toUpperCase()) + '" title="' + esc(c.attribute.toUpperCase()) + ' — tap for meaning">';
    if (c.level != null) {
      starsHtml = '<div class="cf-stars"><span class="d-level symdef" data-symkind="level" data-symkey="' + c.level + '" title="Tap for meaning">' +
        (c.level > 0 ? new Array(c.level + 1).join("★") : "0") +
        '<em class="d-level-num">Lv.' + c.level + '</em></span></div>';
    }
  } else {
    const kind = c.cardType === "spell" ? "魔法" : "罠";
    const propLabel = c.spellTrapTypeJa ? (c.spellTrapTypeJa + kind) : (kind + "カード");
    const propEn = c.spellTrapType ? (c.spellTrapType + " " + (c.cardType === "spell" ? "Spell" : "Trap")) : ((c.cardType === "spell" ? "Spell" : "Trap") + " Card");
    const stImg = ST_TYPE_ICON[c.cardType];
    badgeHtml = '<img class="d-attr-icon symdef" data-symkind="' + c.cardType + '" data-symkey="' + esc(c.spellTrapType || "Normal") + '" src="' + stImg + '" alt="' + esc(propEn) + '" title="' + esc(propEn) + ' — tap for meaning">';
  }

  // 4. Type line. Monsters carry their own bracketed line; spells/traps get
  // bracketed here plus the sub-type symbol inline, e.g. 【魔法カード ✚】.
  const typeJa = typeLineJa(c);
  const typeEn = typeLineEn(c);
  let typeJaHtml;
  if (isMon) {
    typeJaHtml = c.typeLineJaHtml || esc(typeJa);
  } else {
    const inner = c.typeLineJaHtml || esc(typeJa);
    const subIcon = ST_SUBTYPE_ICON[c.spellTrapType];
    let iconHtml = "";
    if (subIcon) {
      const subEn = c.spellTrapType + " " + (c.cardType === "spell" ? "Spell" : "Trap");
      iconHtml = ' <img class="cf-subicon symdef" data-symkind="' + c.cardType + '" data-symkey="' + esc(c.spellTrapType) + '" src="' + subIcon + '" alt="' + esc(subEn) + '" title="' + esc(subEn) + ' — tap for meaning">';
    }
    typeJaHtml = "【" + inner + iconHtml + "】";
  }

  // 5. Effect text with JP/EN toggle. Controls and body are kept separate so the
  // type line can be positioned between them (monsters) or above them (spells).
  const hasJp = !!c.jpEff, hasEn = !!c.enEff;
  const langInit = state.currentLang || "jp";
  let effControls = "", effBody = "";
  if (hasJp || hasEn) {
    effControls = '<div class="eff-controls"><div class="lang-toggle">' +
      '<button class="lang-btn' + (langInit === "jp" ? " active" : "") + '" data-lang="jp">日本語</button>' +
      '<button class="lang-btn' + (langInit === "en" ? " active" : "") + '" data-lang="en">English</button>' +
      '</div>' + (hasJp ? furiToggleHtml() : '') + '</div>';
    if (hasJp) effBody += '<div class="d-eff-jp' + (langInit !== "jp" ? " hidden" : "") + '" id="effJp">' + buildJpEffInner(c, hasEn) + '</div>';
    if (hasEn) effBody += '<div class="d-eff-en' + (langInit !== "en" ? " hidden" : "") + '" id="effEn">' + esc(c.enEff) + '</div>';
  }
  const typeLineBlock = '<div class="cf-typeline' + (isMon ? '' : ' cf-typeline-top') + '"><div class="jp">' + typeJaHtml + '</div><div class="en">' + esc(typeEn) + '</div></div>';

  // 6. ATK / DEF
  let statsHtml = "";
  if (isMon && (c.atk != null || c.def != null)) {
    statsHtml = '<div class="cf-footer">' +
      '<span class="cf-ad">ATK<b>/</b> ' + (c.atk == null ? "?" : c.atk) + '</span>' +
      '<span class="cf-ad">DEF<b>/</b> ' + (c.def == null ? "?" : c.def) + '</span>' +
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

  // Card-face body, laid out to mimic the real card:
  //  Spell/Trap: centered type line under the name, then the effect.
  //  Monster: type line sits just above the effect, with ATK/DEF as the footer.
  const cfTop = '<div class="cf-top">' +
    '<div class="cf-name">' + nameHtml + '<div class="cf-en">' + esc(c.en || "") + '</div></div>' +
    (badgeHtml ? '<div class="cf-badge">' + badgeHtml + '</div>' : '') +
    '</div>';
  const hasText = !!(effControls || effBody);
  let cardInner;
  if (isMon) {
    const textbox = hasText
      ? '<div class="cf-textbox">' + effControls + typeLineBlock + effBody + '</div>'
      : typeLineBlock;
    cardInner = cfTop + starsHtml + textbox + statsHtml;
  } else {
    cardInner = cfTop + typeLineBlock +
      (hasText ? '<div class="cf-textbox">' + effControls + effBody + '</div>' : '');
  }

  host.innerHTML =
    '<div class="detail"><div class="detail-h" style="--frameCol:' + fc + '"></div>' +
    '<div class="d-backbar"><button class="d-back" id="backTop" type="button">← Back to cards</button></div>' +
    '<div class="detail-b">' +
      '<div class="d-art-col">' + artHtml + '</div>' +
      '<div class="d-info">' +
        '<div class="cardface" style="--frameCol:' + frameHex(c) + '">' + cardInner + '</div>' +
        '<div class="d-extra">' +
          passcodeHtml +
          packChips +
          linksHtml +
          '<div class="d-actions">' +
            '<button class="search-btn" id="saveBtn" style="font-size:13px;padding:8px 18px;">✦ Save to My Cards</button>' +
            '<button class="pchip" id="backBtn" style="cursor:pointer;margin-left:8px;">← Back</button>' +
          '</div>' +
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

  // EN peek: tap a JP sentence to reveal its English inline; or the fallback toggle.
  const effJpEl = document.getElementById("effJp");
  if (effJpEl) {
    effJpEl.addEventListener("click", (e) => {
      if (e.target.closest(".vocab") || e.target.closest(".symdef")) return;
      const btn = e.target.closest(".jp-peek-btn");
      if (btn) { const box = btn.nextElementSibling; if (box) box.classList.toggle("hidden"); return; }
      const sent = e.target.closest(".jp-sent");
      if (!sent) return;
      const next = sent.nextElementSibling;
      if (next && next.classList.contains("jp-sent-en")) { next.remove(); }
      else {
        const en = document.createElement("div");
        en.className = "jp-sent-en";
        en.textContent = sent.getAttribute("data-en");
        sent.after(en);
      }
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
