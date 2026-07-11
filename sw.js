/* Nightmare Troubadour Card Codex — offline service worker.
   Bump CACHE when the app shell or data changes to force a refresh. */
var CACHE = "nt-codex-v4";
var SHELL = [
  "./", "./index.html",
  "./cards.json", "./packs.json", "./vocabulary.json",
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
    e.respondWith(
      fetch(req).then(function (res) {
        var copy = res.clone();
        caches.open(CACHE).then(function (c) { c.put(req, copy); });
        return res;
      }).catch(function () {
        return caches.match(req).then(function (m) { return m || caches.match("./index.html"); });
      })
    );
  } else {
    // Card images + fonts (cross-origin): cache-first so viewed cards work offline.
    e.respondWith(
      caches.match(req).then(function (m) {
        return m || fetch(req).then(function (res) {
          var copy = res.clone();
          caches.open(CACHE).then(function (c) { c.put(req, copy); });
          return res;
        }).catch(function () { return m; });
      })
    );
  }
});
