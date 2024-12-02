// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import "@popperjs/core";
import "bootstrap";
import * as ActionCable from "@rails/actioncable";

console.log("✅ Application JS chargée.");

// Réduire le délai de la barre de progression Turbo
Turbo.setProgressBarDelay(0);