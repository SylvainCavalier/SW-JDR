self.addEventListener("install", (event) => {
  console.log("Service worker installed.");
})

self.addEventListener("activate", (event) => {
  console.log("Service worker activated.");
})

self.addEventListener("push", (event) => {
  console.log("Push notification received.");

  // Vérifie si l'événement push contient des données
  let data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (error) {
      console.error("Erreur lors du parsing JSON :", error);
    }
  }

  // Affiche une notification
  self.registration.showNotification(data.title || "Nouvelle notification", {
    body: data.body || "Vous avez un nouveau message.",
    icon: "/icon.png",
    badge: "/badge.png"
  });
});