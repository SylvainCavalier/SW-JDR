self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open("sw-jdr-cache").then((cache) => {
      return cache.addAll([
        "<%= root_path %>", // Page d'accueil
        "<%= asset_path('manifest.json') %>", // Manifest PWA
        "<%= asset_path('icon-192x192.png') %>", // Icône 192x192
        "<%= asset_path('icon-512x512.png') %>", // Icône 512x512
        "<%= asset_path('application.css') %>", // CSS compilé
        "<%= asset_path('application.js') %>", // JS compilé
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

/* "/assets/bottom-bar.svg", // Autres fichiers
"/assets/cadre2.svg",
"/assets/function.svg",
"/assets/de6.png",
"/assets/de12.png",
"/assets/screen.svg",
"/assets/top-bar.svg",
"/assets/red-bar.svg",
"/assets/shield.mp3", */