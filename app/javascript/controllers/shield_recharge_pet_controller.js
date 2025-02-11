import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["confirmButton"];

  connect() {
    console.log("✅ shield-recharge-pet Controller connecté !");
  }

  openRechargePopup(event) {
    const button = event.currentTarget;
    this.petId = button.dataset.petId;
    this.shieldMax = parseInt(button.dataset.shieldMax, 10) || 0;
    this.shieldCurrent = parseInt(button.dataset.shieldCurrent, 10) || 0;
    
    const rechargeCost = (this.shieldMax - this.shieldCurrent) * 10; // Prix : 10 crédits par point

    console.log(`🔹 Pet ID: ${this.petId}, Max Shield: ${this.shieldMax}, Current Shield: ${this.shieldCurrent}, Cost: ${rechargeCost}`);

    if (this.shieldMax === 0) {
      this.showModal("Impossible de recharger", "Ce pet ne possède pas de bouclier.");
      return;
    }

    if (this.shieldCurrent === this.shieldMax) {
      this.showModal("Bouclier plein", "Le bouclier du pet est déjà au maximum !");
      return;
    }

    // Afficher la modale avec le coût
    this.showModal(
      "Recharger le bouclier ?",
      `Cela coûtera ${rechargeCost} crédits. Confirmer la recharge ?`,
      "Recharger"
    );
  }

  showModal(title, message, confirmButtonText) {
    const modalTitle = document.querySelector("[data-modal-target='title']");
    const modalMessage = document.querySelector("[data-modal-target='message']");
    this.confirmButton = document.querySelector("[data-modal-target='confirmButton']");

    if (!modalTitle || !modalMessage || !this.confirmButton) {
      console.error("⚠️ Impossible de trouver la modale générique.");
      return;
    }

    modalTitle.innerText = title;
    modalMessage.innerText = message;
    this.confirmButton.innerText = confirmButtonText;

    // Ajout d'un gestionnaire d'événement dynamique
    this.confirmButton.removeEventListener("click", this.boundConfirmRecharge);
    this.boundConfirmRecharge = this.confirmRecharge.bind(this);
    this.confirmButton.addEventListener("click", this.boundConfirmRecharge);
  }

  confirmRecharge() {
    const rechargePath = `/pets/${this.petId}/recharger_bouclier`;

    fetch(rechargePath, {
      method: "POST",
      headers: { "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content },
    })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          // Mettre à jour l'affichage du bouclier
          const shieldValue = document.querySelector("#shield-value");
          if (shieldValue) shieldValue.innerText = data.shield_current;

          // Fermer la modale
          const modal = bootstrap.Modal.getInstance(document.getElementById("genericModal"));
          modal.hide();
        } else {
          alert(data.message || "Erreur lors de la recharge.");
        }
      })
      .catch(error => console.error("❌ Erreur de recharge :", error));
  }
}