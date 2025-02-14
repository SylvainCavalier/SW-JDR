import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      console.warn("Notifications push non supportées.");
      return;
    }

    // Récupération propre de la clé publique
    const vapidPublicKey = this.element.dataset.pushVapidPublicKey;

    if (!vapidPublicKey) {
      console.error("Erreur : Clé VAPID non définie !");
      return;
    }

    console.log("VAPID PUBLIC KEY:", vapidPublicKey);

    navigator.serviceWorker.register("/service-worker.js").then(registration => {
      return registration.pushManager.getSubscription().then(subscription => {
        if (subscription) return subscription;
        return registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.base64ToUint8Array(vapidPublicKey)
        });
      });
    }).then(subscription => {
      this.saveSubscription(subscription);
    }).catch(error => {
      console.error("Erreur d'abonnement aux notifications :", error);
    });
  }

  saveSubscription(subscription) {
    fetch("/subscriptions", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content },
      body: JSON.stringify({
        endpoint: subscription.endpoint,
        p256dh: btoa(String.fromCharCode.apply(null, new Uint8Array(subscription.getKey("p256dh")))),
        auth: btoa(String.fromCharCode.apply(null, new Uint8Array(subscription.getKey("auth"))))
      })
    });
  }

  base64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
    const rawData = atob(base64);
    return new Uint8Array([...rawData].map(char => char.charCodeAt(0)));
  }
}