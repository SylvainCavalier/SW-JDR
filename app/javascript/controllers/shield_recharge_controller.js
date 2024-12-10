import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["popupMessage"];

  connect() {
    console.log("Contrôleur shieldRecharge connecté !");
    console.log("popupMessage target:", this.popupMessageTarget);
  }

  openRechargePopup(event) {
    const clickedButton = event.currentTarget;

    // Récupération dynamique des données à partir du bouton cliqué
    this.shieldType = clickedButton.dataset.shieldType;
    this.shieldMax = parseInt(clickedButton.dataset.shieldMax, 10) || 0;
    this.shieldCurrent = parseInt(clickedButton.dataset.shieldCurrent, 10) || 0;

    // Vérification des valeurs
    console.log("Type de bouclier :", this.shieldType);
    console.log("Bouclier max :", this.shieldMax);
    console.log("Bouclier actuel :", this.shieldCurrent);

    const modal = new bootstrap.Modal(document.getElementById("rechargeModal"));

    if (this.shieldMax === 0) {
      // Cas où le bouclier n'existe pas
      this.popupMessageTarget.innerText = `Impossible de recharger un bouclier ${
        this.shieldType === "energy" ? "d'énergie" : "Échani"
      } inexistant ! Demandez au MJ d'activer votre bouclier, héros en carton.`;
      modal.show();
      return;
    }

    if (this.shieldCurrent === this.shieldMax) {
      this.popupMessageTarget.innerText = `Le bouclier ${
          this.shieldType === "energy" ? "d'énergie" : "Échani"
      } est déjà plein !`;
      modal.show();
      return;
    }

    if (this.shieldCurrent === 0) {
      // Cas où le bouclier est épuisé (mais existe)
      const rechargeCost = this.shieldMax * 10; // Recharge complète
      this.popupMessageTarget.innerText = `Votre bouclier ${
        this.shieldType === "energy" ? "d'énergie" : "Échani"
      } est vide. Rechargez-le pour ${rechargeCost} Crédits ?`;
      modal.show();
      return;
    }

    // Cas normal de recharge partielle
    const rechargeCost = (this.shieldMax - this.shieldCurrent) * 10;
    console.log("Coût de recharge calculé :", rechargeCost);
    this.popupMessageTarget.innerText = `Recharger le bouclier ${
      this.shieldType === "energy" ? "d'énergie" : "Échani"
    } pour ${rechargeCost} Crédits ?`;
    modal.show();
  }

  async confirmRecharge() {
    console.log("Recharge confirmée !");
    const response = await fetch(`/users/${this.userId}/recharger_bouclier`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
      },
      body: JSON.stringify({ shield_type: this.shieldType }),
    });
  
    if (!response.ok) {
      const data = await response.json();
      alert(data.message || "Erreur lors de la recharge");
    } else {
      console.log("Recharge réussie !");
      // Optionnel : forcer une mise à jour ciblée si nécessaire
      Turbo.visit(window.location.href); // Recharge ciblée uniquement si nécessaire
    }
  }
}