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
    console.log("updateXpCost() appelé");
    const buyAmount = parseInt(this.buyHpInputTarget.value) || 0;
    console.log("buyAmount:", buyAmount);

    let totalCost = 0; // Coût total en XP
    let simulatedMaxHp = this.maxHp; // PV max simulés
    console.log("maxHp initial:", simulatedMaxHp);

    let actualBuyCount = 0; // Nombre de PV réellement achetés (sans les gratuits)

    for (let i = 0; i < buyAmount; i++) {
        // Pour chaque PV max (achetés + gratuits), on ne compte que ceux réellement achetés
        if (this.element.dataset.robustesse === "true") {
          console.log("Robustesse activée");

          // Calcul du coût basé sur le HP après l'achat et le bonus
          if (actualBuyCount % 2 === 0) {
              const costPerPoint = Math.floor((this.maxHp + actualBuyCount) / 10);
              totalCost += costPerPoint;
              console.log(`CostPerPoint pour HP acheté ${actualBuyCount + 1} :`, costPerPoint);
          }

          // On ajoute 2 PV (1 acheté + 1 gratuit)
          simulatedMaxHp += 2;
          actualBuyCount++;
        } else {
            console.log("Robustesse désactivée");
            const costPerPoint = Math.floor(simulatedMaxHp / 10);
            totalCost += costPerPoint;
            simulatedMaxHp++;
        }

        console.log("simulatedMaxHp mis à jour:", simulatedMaxHp);
        console.log("TotalCost mis à jour:", totalCost);
    }

    console.log("TotalCost final:", totalCost);
    this.xpCostTarget.textContent = totalCost; // Met à jour l'affichage du coût total
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