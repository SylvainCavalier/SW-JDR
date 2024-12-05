import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["icon", "shieldCurrent", "credits", "popup", "popupMessage"];

  connect() {
    console.log("Contrôleur Shield connecté");
    this.active = this.element.dataset.shieldState === "true";
    this.shieldType = this.element.dataset.shieldType;
    this.updateIcon();
  }

  toggle() {
    if (this.locked) {
      console.log("Action en attente...");
      return;
    }

    this.locked = true;
    setTimeout(() => {
      this.locked = false;
    }, 3000);

    // Vérification si le bouclier peut être activé
    if (parseInt(this.element.dataset.shieldMax) === 0) {
      alert(
        `Bouclier ${
          this.shieldType === "energy" ? "d'énergie" : "Échani"
        } non disponible. Consultez le MJ pour en activer un.`
      );
      return;
    }

    this.updateServer(this.shieldType)
      .then(data => {
        this.active = this.shieldType === "energy" ? data.shield_state : data.echani_shield_state;

        // Mise à jour des icônes des boucliers
        this.updateIcon();
        this.toggleOtherShield(this.shieldType === "energy" ? "echani" : "energy", false);

        if (this.active) {
          this.playSound();
        }
      })
      .catch(error => {
        console.error("Erreur lors de la mise à jour du bouclier :", error);
      });
  }

  toggleOtherShield(shieldType, shouldDeactivate) {
    const otherShieldElement = document.querySelector(`[data-shield-type="${shieldType}"]`);
    if (otherShieldElement) {
      const icon = otherShieldElement.querySelector(".fa-shield");
      if (icon) {
        icon.classList.toggle("active", !shouldDeactivate);
      }
    }
  }

  updateIcon() {
    this.iconTarget.classList.toggle("active", this.active);
  }

  playSound() {
    const audio = document.getElementById("shield-sound");
    audio.currentTime = 0;
    audio.play();
  }

  async updateServer(shieldType) {
    const response = await fetch(`/users/${this.element.dataset.userId}/toggle_shield`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
      },
      body: JSON.stringify({ shield_type: shieldType }),
    });

    if (!response.ok) {
      throw new Error("Erreur lors de la requête au serveur");
    }

    return response.json();
  }
}