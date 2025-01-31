import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["enemyRow", "hp", "shield"];

  updateEnemyStat(enemyId, field, value) {
    fetch(`/mj/combat/update_enemy_stat/${enemyId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content },
      body: JSON.stringify({ [field]: value })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        let enemyRow = this.enemyRowTargets.find(row => row.dataset.enemyId == enemyId);
        if (enemyRow) {
          if (field === "hp_current") enemyRow.querySelector("[data-combat-target='hp']").textContent = data.hp_current;
          if (field === "shield_current") enemyRow.querySelector("[data-combat-target='shield']").textContent = data.shield_current;
        }
      }
    })
    .catch(error => console.error("Erreur de mise à jour :", error));
  }

  incrementHp(event) {
    let enemyId = event.currentTarget.dataset.enemyId;
    let currentHp = parseInt(this.hpTargets.find(el => el.closest("tr").dataset.enemyId == enemyId).textContent, 10);
    this.updateEnemyStat(enemyId, "hp_current", currentHp + 1);
  }

  decrementHp(event) {
    let enemyId = event.currentTarget.dataset.enemyId;
    let currentHp = parseInt(this.hpTargets.find(el => el.closest("tr").dataset.enemyId == enemyId).textContent, 10);
    this.updateEnemyStat(enemyId, "hp_current", currentHp - 1);
  }

  incrementShield(event) {
    let enemyId = event.currentTarget.dataset.enemyId;
    let currentShield = parseInt(this.shieldTargets.find(el => el.closest("tr").dataset.enemyId == enemyId).textContent, 10);
    this.updateEnemyStat(enemyId, "shield_current", currentShield + 1);
  }

  decrementShield(event) {
    let enemyId = event.currentTarget.dataset.enemyId;
    let currentShield = parseInt(this.shieldTargets.find(el => el.closest("tr").dataset.enemyId == enemyId).textContent, 10);
    this.updateEnemyStat(enemyId, "shield_current", currentShield - 1);
  }
}