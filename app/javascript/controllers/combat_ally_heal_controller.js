import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["targetName", "enemyId", "healItem", "hpDisplay", "resultMessage", "healButton"];

  connect() {
    const modalElement = this.element;
    modalElement.addEventListener("shown.bs.modal", (event) => {
      const trigger = event.relatedTarget;
      if (!trigger) return;

      const enemyId = trigger.getAttribute("data-enemy-id");
      const enemyName = trigger.getAttribute("data-enemy-name");
      const enemyHp = trigger.getAttribute("data-enemy-hp");
      const enemyHpMax = trigger.getAttribute("data-enemy-hp-max");

      this.targetNameTarget.textContent = enemyName || "—";
      this.enemyIdTarget.value = enemyId || "";
      this.hpDisplayTarget.textContent = `${enemyHp} / ${enemyHpMax}`;
      this.resultMessageTarget.innerHTML = "";
    });
  }

  async heal() {
    const enemyId = this.enemyIdTarget.value;
    const itemSelect = this.healItemTarget;
    const itemId = itemSelect.value;

    if (!itemId) {
      alert("Veuillez sélectionner un objet de soin !");
      return;
    }

    this.healButtonTarget.disabled = true;
    this.healButtonTarget.textContent = "Chargement...";

    try {
      const response = await fetch("/combat/heal_enemy", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        },
        body: JSON.stringify({ enemy_id: enemyId, item_id: itemId }),
      });

      if (response.ok) {
        const data = await response.json();

        if (data.error_message) {
          this.resultMessageTarget.innerHTML = `<div class="alert alert-warning mt-2">${data.error_message}</div>`;
        } else {
          // Update HP display
          this.hpDisplayTarget.textContent = `${data.new_hp} / ${data.hp_max || "?"}`;

          // Update item quantity in select
          const option = itemSelect.querySelector(`option[value="${itemId}"]`);
          if (option) {
            if (data.item_quantity === "illimité" || data.item_quantity > 0) {
              const baseName = option.textContent.split(" (")[0].trim();
              option.textContent = data.item_quantity === "illimité"
                ? baseName
                : `${baseName} (x${data.item_quantity})`;
            } else {
              option.remove();
            }
          }

          this.resultMessageTarget.innerHTML = `<div class="alert alert-success mt-2">${data.target_name} a été soigné de ${data.healed_points} PV.</div>`;
        }
      } else {
        const error = await response.json();
        this.resultMessageTarget.innerHTML = `<div class="alert alert-danger mt-2">${error.error || error.error_message || "Erreur lors du soin."}</div>`;
      }
    } catch (error) {
      this.resultMessageTarget.innerHTML = `<div class="alert alert-danger mt-2">Une erreur inattendue s'est produite.</div>`;
    } finally {
      this.healButtonTarget.disabled = false;
      this.healButtonTarget.innerHTML = '<i class="fa-solid fa-kit-medical"></i> Soigner';
    }
  }
}
