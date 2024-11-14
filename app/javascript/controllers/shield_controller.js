import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["icon", "shieldCurrent", "credits", "popup", "popupMessage"];

  connect() {
    console.log("Contrôleur Shield connecté");
    this.active = this.element.dataset.shieldState === "true";
    this.updateIcon();
  }

  toggle() {
    this.active = !this.active;
    this.updateIcon();
    this.updateServer();

    if (this.active) {
      console.log("Bouclier activé");
      this.playSound();
    }
  }

  updateIcon() {
    this.iconTarget.classList.toggle("active", this.active);
  }

  playSound() {
    const audio = document.getElementById('shield-sound');
    audio.currentTime = 0;
    audio.play();
  }

  updateServer() {
    fetch(`/users/${this.element.dataset.userId}/toggle_shield`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
      },
      body: JSON.stringify({ shield_state: this.active }),
    })
      .then(response => response.json())
      .then(data => {
        if (data.shield_state !== this.active) {
          this.active = data.shield_state;
          this.updateIcon();
        }
      });
  }
}
