import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["healItem", "useHealBtn"];
  static values = { currentUserId: Number }; // Définit une valeur connectée au HTML

  connect() {
    console.log("Controller connected");
    console.log("healItemTargets on connect:", this.healItemTargets);
    console.log("currentUserId value:", this.currentUserIdValue);
  }

  async useHeal(event) {
    const button = event.currentTarget;

    console.log("Button clicked:", button);

    const userId = button.dataset.userId; // ID du joueur à soigner
    console.log("User ID from button dataset:", userId);

    console.log("healItemTargets:", this.healItemTargets);

    const itemElement = this.healItemTargets.find(item => item.dataset.userId === String(userId));
    console.log("Found itemElement for userId:", itemElement);

    if (!itemElement) {
      console.error("No item found for userId:", userId);
      alert("Aucun objet de soin trouvé pour cet utilisateur !");
      return;
    }

    const itemId = itemElement.value; // ID de l'objet de soin sélectionné
    console.log("Selected item ID:", itemId);

    try {
      const response = await fetch(`/users/${this.currentUserIdValue}/heal_player`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        },
        body: JSON.stringify({ player_id: userId, item_id: itemId }),
      });

      console.log("Fetch response:", response);

      if (response.ok) {
        const data = await response.json();
        console.log("Heal successful, response data:", data);
        alert(`Le joueur ${userId} a été soigné avec succès. PV : ${data.new_hp}`);
        this.updatePlayerHp(userId, data.new_hp);
      } else {
        const error = await response.json();
        console.error("Error response from server:", error);
        alert(error.error || "Une erreur s'est produite.");
      }
    } catch (error) {
      console.error("Network or server error:", error);
      alert("Impossible de soigner le joueur, problème réseau ou serveur.");
    }
  }

  updatePlayerHp(userId, newHp) {
    const playerBox = document.querySelector(`.player-box [data-user-id="${userId}"]`);
    const hpElement = playerBox.querySelector(".player-hp");
    if (hpElement) {
      hpElement.textContent = `PV : ${newHp}`;
    }
  }
}