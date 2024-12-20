import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["d6", "d12", "resultD6", "resultD12", "diceCount", "details"];

  async rollD6() {
    const MAX_DICE = 20;
    const diceCount = Math.min(parseInt(this.diceCountTarget.value) || 0, MAX_DICE);
    let total = 0;
    const rollResults = [];

    if (diceCount > 0) {
      for (let i = 0; i < diceCount; i++) {
        const roll = Math.floor(Math.random() * 6) + 1;
        rollResults.push(roll);
        total += roll;
      }
    }

    this.resultD6Target.value = ""; // Réinitialise le champ du total
    this.detailsTarget.innerHTML = ""; // Réinitialise les détails

    // Désactiver temporairement le clic sur le dé
    this.d6Target.style.pointerEvents = "none";

    // Affiche les résultats séquentiellement
    await this.displayRollsWithAnimation(rollResults);

    // Affiche le total uniquement à la fin
    this.resultD6Target.value = total;

    // Applique le style basé sur les probabilités
    this.applyResultStyle(total, diceCount);

    // Réactiver le clic
    this.d6Target.style.pointerEvents = "auto";
  }

  async displayRollsWithAnimation(rolls) {
    const animationDelay = 50; // Réduire le délai entre chaque chiffre
    for (let i = 0; i < rolls.length; i++) {
      const roll = rolls[i];
      await this.displayRollWithAnimation(roll, i, animationDelay);

      // Ajouter un saut de ligne tous les 5 chiffres
      if ((i + 1) % 5 === 0) {
        const lineBreak = document.createElement("br");
        this.detailsTarget.appendChild(lineBreak);
      }
    }
  }

  displayRollWithAnimation(roll, index, animationDelay) {
    return new Promise((resolve) => {
      const resultElement = document.createElement("span");
      resultElement.textContent = roll;
      resultElement.classList.add("dice-number");

      // Appliquer les couleurs spécifiques pour les 1 et les 6
      if (roll === 6) resultElement.classList.add("six");
      if (roll === 1) resultElement.classList.add("one");

      resultElement.style.opacity = "0"; // Ajouter invisible au départ
      this.detailsTarget.appendChild(resultElement);

      // Utiliser une temporisation pour appliquer l'animation
      setTimeout(() => {
        resultElement.style.opacity = "1"; // Rendre visible
        resultElement.style.animation = `zoom-dice 0.3s ease-in-out`;
      }, animationDelay * index);

      // Résoudre la promesse après un délai constant
      setTimeout(() => {
        resolve();
      }, 300); // Durée de l'animation
    });
  }

  applyResultStyle(total, diceCount) {
    const minResult = diceCount; // Le minimum possible
    const maxResult = 6 * diceCount; // Le maximum possible
    const range = maxResult - minResult;

    // Seuils pour les 10 % les plus faibles et les 10 % les plus élevés
    const lowThreshold = minResult + Math.ceil(range * 0.2);
    const highThreshold = maxResult - Math.ceil(range * 0.2);

    // Supprime les classes existantes
    this.resultD6Target.classList.remove("low", "high");

    // Ajoute la classe appropriée
    if (total <= lowThreshold) {
      this.resultD6Target.classList.add("low");
    } else if (total >= highThreshold) {
      this.resultD6Target.classList.add("high");
    }
  }

  rollD12() {
    const luckBonus = this.element.dataset.luck === "true" ? 1 : 0;
    const result = Math.floor(Math.random() * 12) + 1 + luckBonus;
    this.resultD12Target.value = result;
  }
}