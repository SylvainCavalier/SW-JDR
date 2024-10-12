import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["icon"];

  connect() {
    console.log("Le contrôleur Shield est bien connecté !");
    this.active = this.element.dataset.shieldState === "true";
    this.updateIcon();
  }

  toggle() {
    console.log("Bouclier cliqué !");
    this.active = !this.active;
    this.updateIcon();
    this.updateServer();

    if (this.active) {
      this.playSound();
    }
  }

  updateIcon() {
    if (this.active) {
      this.iconTarget.classList.add("active");
      console.log("Bouclier activé");
    } else {
      this.iconTarget.classList.remove("active");
      console.log("Bouclier désactivé");
    }
  }

  playSound() {
    const audio = document.getElementById('shield-sound');
    audio.currentTime = 0;
    audio.play();
  }

  updateServer() {
    // Envoyer la mise à jour au serveur via une requête fetch
    fetch(`/users/${this.element.dataset.userId}/toggle_shield`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
      },
      body: JSON.stringify({ shield_state: this.active }),
    });
  }
}
