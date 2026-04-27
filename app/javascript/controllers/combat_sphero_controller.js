import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "hp",
    "shield",
    "medipacks",
    "resultMessage",
    "playerSelect",
    "useMedipackButton",
    "repairButton",
    "rechargeButton"
  ];
  static values = { spheroId: Number };

  showResult(message, level = "info") {
    if (!this.hasResultMessageTarget) return;
    this.resultMessageTarget.innerHTML =
      `<div class="alert alert-${level} mt-2 mb-0">${message}</div>`;
  }

  async _post(url, body = null) {
    const headers = {
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
    };
    const options = { method: "POST", headers };
    if (body) {
      headers["Content-Type"] = "application/json";
      options.body = JSON.stringify(body);
    }
    return fetch(url, options);
  }

  async addMedipack() {
    const response = await this._post(`/spheros/${this.spheroIdValue}/add_medipack`);
    const data = await response.json().catch(() => ({}));
    if (response.ok && data.success) {
      this.medipacksTarget.textContent = data.new_medipack_count;
      if (this.hasUseMedipackButtonTarget) this.useMedipackButtonTarget.disabled = false;
      this.showResult(data.message || "Medipack ajouté.", "success");
    } else {
      this.showResult(data.error || "Impossible d'ajouter un medipack.", "danger");
    }
  }

  async useMedipack() {
    const playerId = this.playerSelectTarget.value;
    if (!playerId) {
      this.showResult("Veuillez sélectionner un équipier.", "warning");
      return;
    }

    this.useMedipackButtonTarget.disabled = true;
    const response = await this._post(
      `/spheros/${this.spheroIdValue}/use_medipack`,
      { player_id: playerId }
    );
    const data = await response.json().catch(() => ({}));

    if (response.ok && data.success) {
      this.medipacksTarget.textContent = data.new_medipack_count;
      this.showResult(data.message, "success");
      if (data.new_medipack_count <= 0) {
        this.useMedipackButtonTarget.disabled = true;
      } else {
        this.useMedipackButtonTarget.disabled = false;
      }
    } else {
      this.useMedipackButtonTarget.disabled = false;
      this.showResult(data.error || "Erreur lors du soin.", "danger");
    }
  }

  async protect() {
    const response = await this._post(`/spheros/${this.spheroIdValue}/protect`);
    const data = await response.json().catch(() => ({}));
    if (response.ok && data.success) {
      this.showResult(data.message, "success");
    } else {
      this.showResult(data.message || "Impossible de protéger.", "danger");
    }
  }

  async attack() {
    const response = await this._post(`/spheros/${this.spheroIdValue}/attack`);
    const data = await response.json().catch(() => ({}));
    if (response.ok && data.success) {
      this.showResult(data.message, "success");
    } else {
      this.showResult(data.message || "Impossible d'attaquer.", "danger");
    }
  }

  async repair() {
    this.repairButtonTarget.disabled = true;
    const response = await this._post(`/spheros/${this.spheroIdValue}/repair`);
    if (response.ok) {
      this.showResult("Sphéro-Droïde réparé.", "success");
      // L'endpoint repair ne renvoie pas le détail, recharge ciblée des PV via reload léger
      window.location.reload();
    } else {
      this.repairButtonTarget.disabled = false;
      this.showResult(
        "Réparation impossible (compétence Réparation 3D ou composants insuffisants).",
        "danger"
      );
    }
  }

  async recharge() {
    this.rechargeButtonTarget.disabled = true;
    const response = await this._post(`/spheros/${this.spheroIdValue}/recharge`);
    if (response.ok) {
      this.showResult("Bouclier rechargé.", "success");
      window.location.reload();
    } else {
      this.rechargeButtonTarget.disabled = false;
      this.showResult("Recharge impossible (crédits insuffisants).", "danger");
    }
  }
}
