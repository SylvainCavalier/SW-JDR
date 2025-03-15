import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      console.warn("Notifications push non supportées.");
      return;
    }

    const vapidPublicKey = this.element.dataset.pushVapidPublicKey;
    if (!vapidPublicKey) {
      console.error("Erreur : Clé VAPID non définie !");
      return;
    }

    console.log("🔑 VAPID PUBLIC KEY:", vapidPublicKey);

    navigator.serviceWorker.register("/service-worker.js").then(registration => {
      return registration.pushManager.getSubscription().then(subscription => {
        if (subscription) {
          console.log("ℹ️ Abonnement existant trouvé :", subscription.endpoint);
          return subscription; // Ne pas recréer un abonnement inutilement
        }
        return registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.base64ToUint8Array(vapidPublicKey)
        });
      });
    }).then(subscription => {
      if (subscription) {
        console.log("📨 Envoi de l'abonnement au serveur...");
        this.saveSubscription(subscription);
      }
    }).catch(error => {
      console.error("❌ Erreur d'abonnement aux notifications :", error);
    });
  }

  saveSubscription(subscription) {
    fetch("/subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({
        subscription: {
          endpoint: subscription.endpoint,
          p256dh: btoa(String.fromCharCode.apply(null, new Uint8Array(subscription.getKey("p256dh")))),
          auth: btoa(String.fromCharCode.apply(null, new Uint8Array(subscription.getKey("auth"))))
        }
      })
    }).then(response => response.json())
      .then(data => console.log("✅ Réponse du serveur :", data))
      .catch(error => console.error("❌ Erreur lors de l'envoi de l'abonnement :", error));
  }

  base64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
    const rawData = atob(base64);
    return new Uint8Array([...rawData].map(char => char.charCodeAt(0)));
  }
}