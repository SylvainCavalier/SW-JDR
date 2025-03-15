import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["icon", "shieldCurrent"];
  static values = { shieldType: String };

  connect() {
    this.shieldType = this.element.dataset.shieldType;
    this.locked = false;
    this.updateState();
    this.observeShieldChanges();
  }

  observeShieldChanges() {
    const observer = new MutationObserver(() => this.updateState());

    observer.observe(this.shieldCurrentTarget, {
      attributes: true,          // surveiller changements d'attributs
      attributeFilter: ["data-shield-state", "data-shield-current"],
      subtree: false
    });
  }

  updateState() {
    this.active = this.shieldCurrentTarget.dataset.shieldState === "true";
    this.shieldCurrent = parseInt(this.shieldCurrentTarget.dataset.shieldCurrent, 10);

    this.updateIcon();
  }

  toggle() {
    if (this.locked) {
      console.log("Action en attente...");
      return;
    }

    if (this.shieldCurrent === 0) {
      alert(`Le bouclier ${this.shieldType === "energy" ? "d'énergie" : "Échani"} est vide. Rechargez avant de l'activer.`);
      return;
    }

    this.locked = true;
    setTimeout(() => { this.locked = false; }, 3000);

    this.updateServer(this.shieldType)
      .then((data) => {
        this.active = this.shieldType === "energy" ? data.shield_state : data.echani_shield_state;
        this.updateIcon();

        if (this.active) {
          this.playSound();
        }
      })
      .catch((error) => {
        console.error("Erreur lors du toggle shield :", error);
      });
  }

  updateIcon() {
    if (this.active) {
      this.iconTarget.classList.add("active");
      this.iconTarget.classList.remove("inactive");
    } else {
      this.iconTarget.classList.add("inactive");
      this.iconTarget.classList.remove("active");
    }
  }

  playSound() {
    const audio = document.getElementById("shield-sound");
    if (audio) {
      audio.currentTime = 0;
      audio.play();
    }
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

    if (!response.ok) throw new Error("Erreur serveur");

    return response.json();
  }
}