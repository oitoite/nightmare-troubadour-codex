/* Nightmare Troubadour Card Codex — offline service worker.
   Bump CACHE when the app shell or data changes to force a refresh. */
var CACHE = "nt-codex-v31";
var SHELL = [
  "./", "./index.html",
  "./app/styles.css",
  "./app/app.js", "./app/state.js", "./app/util.js", "./app/furigana.js", "./app/symbols.js",
  "./app/browse.js", "./app/detail.js", "./app/mycards.js", "./app/dictionary.js",
  "./app/packs.js", "./app/tabs.js",
  "./cards.json", "./packs.json", "./vocabulary.json", "./game-terms.json",
  "./manifest.webmanifest",
  "./icon-192.png", "./icon-512.png", "./apple-touch-icon.png", "./favicon-32.png"
];

self.addEventListener("install", function (e) {
  e.waitUntil(
    caches.open(CACHE).then(function (c) { return c.addAll(SHELL); }).then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener("activate", function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.map(function (k) { return k === CACHE ? null : caches.delete(k); }));
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener("fetch", function (e) {
  var req = e.request;
  if (req.method !== "GET") return;
  var sameOrigin = new URL(req.url).origin === self.location.origin;

  if (sameOrigin) {
    // App shell + data: network-first so updates land online, cache fallback offline.
    // Use no-cache so the network fetch bypasses the HTTP cache (GitHub Pages sets a
    // ~10-min max-age); otherwise the worker can serve stale modules after a deploy.
    e.respondWith(
      fetch(req, { cache: "no-cache" }).then(function (res) {
        var copy = res.clone();
        caches.open(CACHE).then(function (c) { c.put(req, copy); });
        return res;
      }).catch(function () {
        return caches.match(req).then(function (m) { return m || caches.match("./index.html"); });
      })
    );
  } else {
    // Card images + fonts (cross-origin): stale-while-revalidate. Serve the
    // cached copy instantly (fast + offline), and refresh it in the background.
    // Cross-origin responses are opaque (status unreadable), so a rate-limited
    // error can still be cached — but because we always revalidate, a bad tile
    // heals on the next view instead of sticking forever (the old cache-first bug).
    e.respondWith(
      caches.open(CACHE).then(function (c) {
        return c.match(req).then(function (cached) {
          var fresh = fetch(req).then(function (res) {
            c.put(req, res.clone());
            return res;
          }).catch(function () { return cached; });
          return cached || fresh;
        });
      })
    );
  }
});
