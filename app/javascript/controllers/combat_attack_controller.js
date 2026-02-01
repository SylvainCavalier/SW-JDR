import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "skillSelect", "precisionDice", "precisionBonus", "precisionResult", "precisionDetails",
    "weaponSelect", "damageDice", "damageBonus", "damageResult", "damageDetails",
    "targetName"
  ];

  connect() {
    const modalElement = this.element;
    modalElement.addEventListener("shown.bs.modal", (event) => {
      const trigger = event.relatedTarget;
      if (trigger) {
        this.targetNameTarget.textContent = trigger.getAttribute("data-enemy-name") || "—";
      }
      // Reset results on open
      this.precisionResultTarget.value = "";
      this.precisionDetailsTarget.innerHTML = "";
      this.damageResultTarget.value = "";
      this.damageDetailsTarget.innerHTML = "";
      this.precisionResultTarget.classList.remove("low", "high");
      this.damageResultTarget.classList.remove("low", "high");
    });
  }

  skillChanged() {
    const option = this.skillSelectTarget.selectedOptions[0];
    if (!option) return;
    this.precisionDiceTarget.value = option.getAttribute("data-mastery") || 0;
    this.precisionBonusTarget.value = option.getAttribute("data-bonus") || 0;
  }

  weaponChanged() {
    const option = this.weaponSelectTarget.selectedOptions[0];
    if (!option) return;
    this.damageDiceTarget.value = option.getAttribute("data-mastery") || 0;
    this.damageBonusTarget.value = option.getAttribute("data-bonus") || 0;
  }

  async roll() {
    // Precision roll
    const precDice = Math.min(parseInt(this.precisionDiceTarget.value) || 0, 20);
    const precBonus = parseInt(this.precisionBonusTarget.value) || 0;

    // Damage roll
    const dmgDice = Math.min(parseInt(this.damageDiceTarget.value) || 0, 20);
    const dmgBonus = parseInt(this.damageBonusTarget.value) || 0;

    // Clear previous results
    this.precisionResultTarget.value = "";
    this.precisionDetailsTarget.innerHTML = "";
    this.damageResultTarget.value = "";
    this.damageDetailsTarget.innerHTML = "";
    this.precisionResultTarget.classList.remove("low", "high");
    this.damageResultTarget.classList.remove("low", "high");

    // Roll precision dice
    const precRolls = [];
    let precTotal = 0;
    for (let i = 0; i < precDice; i++) {
      const roll = Math.floor(Math.random() * 6) + 1;
      precRolls.push(roll);
      precTotal += roll;
    }
    precTotal += precBonus;

    // Roll damage dice
    const dmgRolls = [];
    let dmgTotal = 0;
    for (let i = 0; i < dmgDice; i++) {
      const roll = Math.floor(Math.random() * 6) + 1;
      dmgRolls.push(roll);
      dmgTotal += roll;
    }
    dmgTotal += dmgBonus;

    // Animate precision
    await this.displayRollsWithAnimation(precRolls, this.precisionDetailsTarget);
    this.precisionResultTarget.value = precTotal;
    this.applyResultStyle(this.precisionResultTarget, precTotal, precDice);

    // Animate damage
    await this.displayRollsWithAnimation(dmgRolls, this.damageDetailsTarget);
    this.damageResultTarget.value = dmgTotal;
    this.applyResultStyle(this.damageResultTarget, dmgTotal, dmgDice);
  }

  async displayRollsWithAnimation(rolls, container) {
    const animationDelay = 50;
    for (let i = 0; i < rolls.length; i++) {
      const roll = rolls[i];
      await this.displayRollWithAnimation(roll, i, animationDelay, container);
      if ((i + 1) % 5 === 0) {
        container.appendChild(document.createElement("br"));
      }
    }
  }

  displayRollWithAnimation(roll, index, animationDelay, container) {
    return new Promise((resolve) => {
      const el = document.createElement("span");
      el.textContent = roll;
      el.classList.add("dice-number");
      if (roll === 6) el.classList.add("six");
      if (roll === 1) el.classList.add("one");
      el.style.opacity = "0";
      container.appendChild(el);

      setTimeout(() => {
        el.style.opacity = "1";
        el.style.animation = "zoom-dice 0.3s ease-in-out";
      }, animationDelay * index);

      setTimeout(() => resolve(), 300);
    });
  }

  applyResultStyle(element, total, diceCount) {
    if (diceCount <= 0) return;
    const min = diceCount;
    const max = 6 * diceCount;
    const range = max - min;
    const low = min + Math.ceil(range * 0.2);
    const high = max - Math.ceil(range * 0.2);

    element.classList.remove("low", "high");
    if (total <= low) element.classList.add("low");
    else if (total >= high) element.classList.add("high");
  }
}
