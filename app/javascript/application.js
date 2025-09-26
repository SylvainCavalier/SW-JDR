import "@hotwired/turbo-rails";
import "controllers";
import "@popperjs/core";
import "bootstrap";
import * as ActionCable from "@rails/actioncable";

console.log("✅ Application JS chargée.");

if ("serviceWorker" in navigator) {
  navigator.serviceWorker
    .register("/service-worker.js")
    .then((registration) => {
      registration.addEventListener("updatefound", () => {
        // If updatefound is fired, it means that there's
        // a new service worker being installed.
        const installingWorker = registration.installing;
        console.log(
          "A new service worker is being installed:",
          installingWorker,
        );
        // You can listen for changes to the installing service worker's
        // state via installingWorker.onstatechange
      });
    })
    .catch((error) => {
      console.error(`Service worker registration failed: ${error}`);
    });
} else {
  console.error("Service workers are not supported.");
}

document.addEventListener("DOMContentLoaded", () => {
  console.log("DOM entièrement chargé, configuration du cadre...");
  const frame = document.querySelector(".ui-frame");

  if (frame) {
    const updateFrameHeight = () => {
      const pageHeight = Math.max(
        document.body.scrollHeight,
        document.documentElement.scrollHeight
      );

      // Ajuste la hauteur du cadre pour qu'elle corresponde à la page
      frame.style.height = `${pageHeight}px`;
    };

    // Ajustement initial et à chaque redimensionnement
    updateFrameHeight();
    window.addEventListener("resize", updateFrameHeight);
  }
});

// Initialisation des tooltips Bootstrap après chaque navigation Turbo
document.addEventListener("turbo:load", () => {
  try {
    const tooltipTriggerList = [].slice.call(
      document.querySelectorAll('[data-bs-toggle="tooltip"]')
    );
    tooltipTriggerList.forEach((tooltipTriggerEl) => {
      // eslint-disable-next-line no-undef
      new bootstrap.Tooltip(tooltipTriggerEl);
    });
  } catch (e) {
    console.warn("Bootstrap Tooltip init error:", e);
  }
});

// Réduire le délai de la barre de progression Turbo
Turbo.setProgressBarDelay(0);