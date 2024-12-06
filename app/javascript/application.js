// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import "@popperjs/core";
import "bootstrap";
import * as ActionCable from "@rails/actioncable";

console.log("✅ Application JS chargée.");

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/service-worker.js')
    .then(function(registration) {
      console.log('Service Worker enregistré avec succès:', registration);
    })
    .catch(function(error) {
      console.log('Échec de l\'enregistrement du Service Worker:', error);
    });
}

// Réduire le délai de la barre de progression Turbo
Turbo.setProgressBarDelay(0);