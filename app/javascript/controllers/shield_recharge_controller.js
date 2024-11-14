import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["popupMessage"];

  connect() {
    this.userId = this.element.dataset.userId;
    this.shieldMax = parseInt(this.element.dataset.shieldMax);
    this.shieldCurrent = parseInt(this.element.dataset.shieldCurrent);
    this.credits = parseInt(this.element.dataset.credits);
    console.log("Contrôleur shieldRecharge connecté !");
    console.log("popupMessage target:", this.popupMessageTarget);
  }

  openRechargePopup() {
    const rechargeCost = (this.shieldMax - this.shieldCurrent) * 10;

    console.log("Bouclier actuel:", this.shieldCurrent);
    console.log("Bouclier max:", this.shieldMax);
    console.log("Crédits disponibles:", this.credits);
    console.log("Coût de recharge:", rechargeCost);


    if (this.credits >= rechargeCost) {
      this.popupMessageTarget.innerText = `Recharger pour ${rechargeCost} Crédits ?`;
      const modal = new bootstrap.Modal(document.getElementById('rechargeModal'));
        modal.show();
    } else {
      alert("Crédits insuffisants pour la recharge.");
    }
  }

  async confirmRecharge() {
    console.log("Recharge confirmée !");
    const response = await fetch(`/users/${this.userId}/recharger_bouclier`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
      },
    });

    const data = await response.json();
    if (data.success) {
      document.querySelector('[data-shield-target="shieldCurrent"]').innerText = `Bouclier : ${data.shield_current} / ${this.shieldMax}`;

        const creditsElement = document.querySelector("[data-controller~='credits']");
        const creditsController = this.application.getControllerForElementAndIdentifier(creditsElement, "credits");

        console.log("creditsController:", creditsController);

        if (creditsController) {
        creditsController.update(data.credits);
        } else {
        console.error("Contrôleur `credits` introuvable.");
        }
    } else {
        alert(data.message || "Erreur lors de la recharge");
    }
  }
}
