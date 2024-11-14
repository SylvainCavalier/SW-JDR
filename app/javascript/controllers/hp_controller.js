import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["hpText", "hpBarFill", "buyHpInput", "xpCost", "currentXp"]

  connect() {
    this.csrfToken = document.querySelector("[name='csrf-token']").content;
    this.userId = this.element.dataset.userId;
    this.maxHp = parseInt(this.element.dataset.maxHp);
    this.currentHp = parseInt(this.element.dataset.currentHp);
    this.currentXp = parseInt(this.currentXpTarget.textContent);

    console.log("Contrôleur HP connecté.");

    this.updateHpDisplay(this.currentHp);
    this.updateXpCost();
  }

  async updateHp(value) {
    const formData = new FormData();
    formData.append("hp_current", value);

    const response = await fetch(`/users/${this.userId}/update_hp`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.csrfToken,
      },
      body: formData,
    });

    const data = await response.json();
    if (data.success) {
      this.currentHp = data.hp_current;
      this.updateHpDisplay(this.currentHp);
    } else {
      console.error("Erreur lors de la mise à jour des PV");
    }
  }

  updateHpDisplay(currentHp) {
    this.hpTextTarget.innerHTML = `PV : ${currentHp} / ${this.maxHp}`;

    // Calcule le pourcentage de remplissage de la barre de vie
    const hpPercentage = (currentHp / this.maxHp) * 100;

    // Met à jour clip-path dynamiquement en ajustant les points de découpe avec polygon
    this.hpBarFillTarget.style.clipPath = `polygon(0 80px, ${hpPercentage}% 50px, ${hpPercentage}% 100%, 0 100%)`;
  }

  updateXpCost() {
    const buyAmount = parseInt(this.buyHpInputTarget.value) || 0;
    let totalCost = 0;
    let simulatedMaxHp = this.maxHp;

    for (let i = 0; i < buyAmount; i++) {
      let costPerPoint;
  
      if (this.element.dataset.robustesse === "true") {
        costPerPoint = Math.floor((simulatedMaxHp + 1) / 10);
        if ((simulatedMaxHp % 2) === 0) {
        totalCost += costPerPoint;
        }
        simulatedMaxHp += 1;
      } else {
        costPerPoint = Math.floor(simulatedMaxHp / 10);
        totalCost += costPerPoint;
        simulatedMaxHp++;
      }
    }

    this.xpCostTarget.textContent = totalCost;
  }

  async purchaseMaxHp(event) {
    event.preventDefault();
    const buyAmount = parseInt(this.buyHpInputTarget.value);
    const xpCost = parseInt(this.xpCostTarget.textContent);

    if (xpCost > this.currentXp) {
      alert("Vous n'avez pas assez de points d'XP !");
      return;
    }

    const response = await fetch(`/users/${this.userId}/purchase_hp`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.csrfToken,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ hp_increase: buyAmount, xp_cost: xpCost }),
    });

    const data = await response.json();
    if (data.success) {
      this.currentXp -= xpCost;
      this.maxHp += buyAmount;

      this.currentXpTarget.textContent = this.currentXp;
      this.hpTextTarget.innerHTML = `PV : ${this.currentHp} / ${this.maxHp}`;
      this.buyHpInputTarget.value = 1;
      this.updateXpCost();

      this.updateHpDisplay(this.currentHp);
    } else {
      alert("Erreur lors de l'achat de PV max.");
    }
  }

  decrement(event) {
    event.preventDefault();
    if (this.currentHp > -10) {
      const newHp = Math.max(this.currentHp - 1, -10);
      this.updateHp(newHp);
    }
  }

  increment(event) {
    event.preventDefault();
    if (this.currentHp < this.maxHp) {
      const newHp = Math.min(this.currentHp + 1, this.maxHp);
      this.updateHp(newHp);
    }
  }
}