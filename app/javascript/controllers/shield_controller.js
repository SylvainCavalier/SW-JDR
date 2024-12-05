import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["icon", "shieldCurrent", "credits", "popup", "popupMessage"];

  connect() {
    this.shieldType = this.element.dataset.shieldType;
    this.active = this.element.dataset.shieldState === "true";
    this.updateIcon();
    console.log(`Shield ${this.shieldType} connecté avec état :`, this.active);
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

    const shieldMax = parseInt(this.element.dataset.shieldMax);
    const shieldCurrent = parseInt(this.element.dataset.shieldCurrent);

    if (shieldMax === 0) {
      alert(
        `Bouclier ${
          this.shieldType === "energy" ? "d'énergie" : "Échani"
        } non disponible. Consultez le MJ pour en activer un.`
      );
      return;
    }

    if (shieldCurrent === 0) {
      alert(
        `Bouclier ${
          this.shieldType === "energy" ? "d'énergie" : "Échani"
        } est vide. Rechargez avant de l'activer.`
      );
      return;
    }

    this.updateServer(this.shieldType)
      .then((data) => {
        // Mise à jour de l'état du bouclier actuel
        this.active =
          this.shieldType === "energy"
            ? data.shield_state
            : data.echani_shield_state;

        this.updateIcon();
        this.updateDomState(data);

        if (this.active) {
          this.playSound();
        }
      })
      .catch((error) => {
        console.error("Erreur lors de la mise à jour du bouclier :", error);
      });
  }

  updateIcon() {
    this.iconTarget.classList.toggle("active", this.active);
  }

  updateDomState(data) {
    // Mettre à jour les données des boucliers dans le DOM
    const otherShieldType = this.shieldType === "energy" ? "echani" : "energy";
    const otherShieldElement = document.querySelector(`[data-shield-type="${otherShieldType}"]`);

    // Mise à jour du bouclier actuel
    this.element.dataset.shieldState = this.active.toString();

    // Mise à jour de l'autre bouclier
    if (otherShieldElement) {
      otherShieldElement.dataset.shieldState = this.shieldType === "energy"
        ? data.echani_shield_state.toString()
        : data.shield_state.toString();

      const icon = otherShieldElement.querySelector(".fa-shield");
      if (icon) {
        icon.classList.toggle("active", false); // Désactiver visuellement
      }
    }
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