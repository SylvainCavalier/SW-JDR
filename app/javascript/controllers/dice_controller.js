import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["d6", "d12", "resultD6", "resultD12", "diceCount"];

  rollD6() {
    const diceCount = parseInt(this.diceCountTarget.value) || 1; // Nombre de dés à lancer
    let total = 0;
    for (let i = 0; i < diceCount; i++) {
      total += Math.floor(Math.random() * 6) + 1; // Lancer un dé à 6 faces
    }
    this.resultD6Target.value = total; // Affiche le total des résultats
  }

  rollD12() {
    const luckBonus = this.element.dataset.luck === "true" ? 1 : 0; // Vérifie si le bonus est actif
    const result = Math.floor(Math.random() * 12) + 1 + luckBonus;
    this.resultD12Target.value = result;
  }
}