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
    event.preventDefault();

    const button = event.currentTarget;
    const targetType = button.dataset.targetType;  // "user" ou "pet"
    const targetId = targetType === "user" ? button.dataset.userId : button.dataset.petId;

    const itemElement = this.healItemTargets.find(
      (item) => item.dataset[targetType + "Id"] === String(targetId)
    );

    if (!itemElement) {
      alert("Veuillez sélectionner un objet de soin !");
      return;
    }

    const itemId = itemElement.value;

    try {
      // 🔹 Désactiver bouton et select pendant la requête
      button.disabled = true;
      button.textContent = "Chargement...";
      itemElement.disabled = true;

      const response = await fetch(`/users/${this.currentUserIdValue}/heal_player`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        },
        body: JSON.stringify({ target_type: targetType, target_id: targetId, item_id: itemId }),
      });

      button.textContent = "Utiliser";
      button.disabled = false;
      itemElement.disabled = false;

      if (response.ok) {
        const data = await response.json();

        if (data.error_message) {
          alert(data.error_message);
          return;
        }

        this.updateTargetHp(targetType, targetId, data.new_hp, data.item_quantity, itemId);
        alert(`🎉 ${data.target_name} a été soigné. PV repris : ${data.healed_points}`);

        // Mise à jour du statut
        this.updateStatus(targetType, targetId, data.new_status);

      } else {
        const error = await response.json();
        alert(error.error || "Cet objet de soin ne peut pas être utilisé.");
      }
    } catch (error) {
      button.textContent = "Utiliser";
      button.disabled = false;
      itemElement.disabled = false;
      alert("Une erreur inattendue s'est produite. Veuillez réessayer.");
    }
  }

  updateTargetHp(targetType, targetId, newHp, itemQuantity, itemId) {
    const targetBox = this.element.querySelector(`[data-${targetType}-id="${targetId}"]`);
    if (!targetBox) return;

    const hpElement = targetBox.querySelector(".player-hp");
    if (hpElement) {
      const maxHp = hpElement.dataset.hpMax;
      hpElement.textContent = `PV : ${newHp} / ${maxHp}`;
    }

    const healItemSelect = targetBox.querySelector(`[data-heal-target="healItem"]`);
    if (healItemSelect) {
      const optionToUpdate = healItemSelect.querySelector(`option[value="${itemId}"]`);
      if (optionToUpdate) {
        if (itemQuantity > 0) {
          optionToUpdate.textContent = `${optionToUpdate.textContent.split(" (")[0]} (x${itemQuantity})`;
        } else {
          optionToUpdate.remove();
        }

        if (!healItemSelect.querySelector("option[disabled]") && healItemSelect.options.length === 0) {
          const emptyOption = document.createElement("option");
          emptyOption.textContent = "Aucun objet disponible";
          emptyOption.disabled = true;
          healItemSelect.appendChild(emptyOption);
        }
      }
    }
  }

  updateStatus(targetType, targetId, newStatus) {
    const targetBox = this.element.querySelector(`[data-${targetType}-id="${targetId}"]`);
    if (!targetBox) return;

    if (newStatus !== null) {
      const statusElement = targetBox.querySelector(".player-status");
      if (statusElement) {
        statusElement.textContent = `Statut : ${newStatus}`;
        console.log(`🔄 Statut mis à jour pour ${targetId} (${targetType}): ${newStatus}`);
      }
    }
  }
}