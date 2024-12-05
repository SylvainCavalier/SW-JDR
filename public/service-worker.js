self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open("sw-jdr-cache").then((cache) => {
      return cache.addAll([
        "/",
        "/manifest.json",
        "/icon-192x192.png",
        "/icon-512x512.png",
        "/stylesheets/application.css",
        "/javascripts/application.js",
        // Ajoute ici les fichiers à mettre en cache
      ]);
    })
  );
});

self.addEventListener("fetch", (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});