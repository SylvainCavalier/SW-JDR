import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["icon", "shieldCurrent", "credits", "popup", "popupMessage"];

  connect() {
    this.shieldType = this.element.dataset.shieldType;
    this.active = this.element.dataset.shieldState === "true";
    this.updateIcon();
    console.log(`Shield ${this.shieldType} connecté avec état :`, this.active);
    this.observeTurboFrame();
  }

  observeTurboFrame() {
    const frameId = `user_${this.element.dataset.userId}_${this.shieldType}_shield_frame`;
    const frame = document.getElementById(frameId);

    if (!frame) {
      console.warn(`Aucun turbo-frame trouvé avec l'ID : ${frameId}`);
      return;
    }

    console.log(`Observateur configuré pour le turbo-frame avec ID : ${frame.id}`);

    frame.addEventListener("turbo:frame-load", () => {
      console.log(`Événement turbo:frame-load détecté pour le frame ID : ${frame.id}`);
      const shieldCurrentAttr = this.shieldCurrentTarget.dataset.shieldCurrent;
      const shieldCurrent = parseInt(shieldCurrentAttr, 10);

      console.log(`Valeur actuelle du bouclier (${this.shieldType}) : ${shieldCurrent}`);

      if (isNaN(shieldCurrent)) {
        console.warn("⚠️ Valeur du bouclier non valide :", shieldCurrentAttr);
        return;
      }

      if (shieldCurrent === 0 && this.active) {
        console.log(`💡 Désactivation du bouclier ${this.shieldType} car valeur à 0.`);
        this.active = false;
        this.updateIcon();
      } else if (shieldCurrent > 0 && !this.active) {
        console.log(`💡 Activation possible du bouclier ${this.shieldType} avec valeur : ${shieldCurrent}`);
      }
    });
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
    console.log(
      `Mise à jour de l'icône pour le bouclier ${this.shieldType}. État actif : ${this.active}`
    );
  
    // Si actif, on applique "active" et on enlève "inactive"
    if (this.active) {
      this.iconTarget.classList.add("active");
      this.iconTarget.classList.remove("inactive");
    } else {
      // Si inactif, on applique "inactive" et on enlève "active"
      this.iconTarget.classList.add("inactive");
      this.iconTarget.classList.remove("active");
    }
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