import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["healItem", "useHealBtn"];
  static values = { currentUserId: Number };

  connect() {
    console.log("✅ Heal Controller connecté");
    console.log("🔄 Heal Item Targets:", this.healItemTargets);
    console.log("🆔 ID utilisateur actuel:", this.currentUserIdValue);
  }

  async useHeal(event) {
    const button = event.currentTarget;
    const userId = button.dataset.userId;

    const itemElement = this.healItemTargets.find(
      (item) => item.dataset.userId === String(userId)
    );

    if (!itemElement) {
      alert("Veuillez sélectionner un objet de soin !");
      return;
    }

    const itemId = itemElement.value;

    try {
      button.disabled = true;
      button.textContent = "Chargement...";

      const response = await fetch(`/users/${this.currentUserIdValue}/heal_player`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        },
        body: JSON.stringify({ player_id: userId, item_id: itemId }),
      });

      button.textContent = "Utiliser";
      button.disabled = false;

      if (response.ok) {
        const data = await response.json();
        this.updatePlayerHp(userId, data.new_hp, data.item_quantity, itemId);
        alert(`🎉 ${data.player_name} a été soigné. PV repris : ${data.healed_points}`);
      } else {
        const error = await response.json();
        alert(error.error || "Une erreur s'est produite.");
      }
    } catch (error) {
      button.textContent = "Utiliser";
      button.disabled = false;
      alert("Une erreur inattendue s'est produite. Veuillez réessayer.");
    }
  }

  updatePlayerHp(userId, newHp, itemQuantity, itemId) {
    const playerBox = this.element.querySelector(`[data-user-id="${userId}"]`);
    if (!playerBox) return;

    const hpElement = playerBox.querySelector(".player-hp");
    if (hpElement) {
      const maxHp = hpElement.dataset.hpMax;
    hpElement.textContent = `PV : ${newHp} / ${maxHp}`;
    }

    const healItemSelect = playerBox.querySelector(`[data-heal-target="healItem"]`);
    if (healItemSelect) {
      const optionToUpdate = healItemSelect.querySelector(`option[value="${itemId}"]`);
      if (optionToUpdate) {
        if (itemQuantity > 0) {
          optionToUpdate.textContent = `${optionToUpdate.textContent.split(" (")[0]} (x${itemQuantity})`;
        } else {
          optionToUpdate.remove();
        }

        if (!healItemSelect.querySelector('option[disabled]') && healItemSelect.options.length === 0) {
          const emptyOption = document.createElement("option");
          emptyOption.textContent = "Aucun objet disponible";
          emptyOption.disabled = true;
          healItemSelect.appendChild(emptyOption);
        }
      }
    }
  }
}