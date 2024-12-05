import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["popupMessage"];

  connect() {
    this.userId = this.element.dataset.userId;
    this.shieldMax = parseInt(this.element.dataset.shieldMax);
    this.shieldCurrent = parseInt(this.element.dataset.shieldCurrent);
    console.log("Contrôleur shieldRecharge connecté !");
    console.log("popupMessage target:", this.popupMessageTarget);
  }

  openRechargePopup() {
    const rechargeCost = (this.shieldMax - this.shieldCurrent) * 10;

    console.log("Bouclier actuel:", this.shieldCurrent);
    console.log("Bouclier max:", this.shieldMax);
    console.log("Coût de recharge:", rechargeCost);

    this.popupMessageTarget.innerText = `Recharger pour ${rechargeCost} Crédits ?`;
    const modal = new bootstrap.Modal(document.getElementById("rechargeModal"));
    modal.show();
  }

  async confirmRecharge() {
    console.log("Recharge confirmée !");
    const response = await fetch(`/users/${this.userId}/recharger_bouclier`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
      },
    });

    if (!response.ok) {
      const data = await response.json();
      alert(data.message || "Erreur lors de la recharge");
    }
  }
}