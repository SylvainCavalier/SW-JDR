self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open("sw-jdr-cache").then((cache) => {
      return cache.addAll([
        "/", // Page d'accueil
        "/manifest.json", // Manifest PWA
        "/assets/icon-192x192.png", // Icône 192x192
        "/assets/icon-512x512.png", // Icône 512x512
        "/assets/application.css", // CSS compilé
        "/assets/application.js", // JS compilé
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