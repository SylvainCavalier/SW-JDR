import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modalContent"];
  static values = { modalId: String };

  connect() {
    this.modalElement = document.getElementById(this.modalIdValue || "craftModal");
    this.modalInstance = bootstrap.Modal.getInstance(this.modalElement) || new bootstrap.Modal(this.modalElement);
  }

  attemptCraft(event) {
    event.preventDefault();

    const button = event.currentTarget;
    const itemId = button.getAttribute("data-item-id");
    const difficulty = button.getAttribute("data-difficulty");

    if (!itemId || !difficulty) {
      console.error("Les attributs 'data-item-id' ou 'data-difficulty' sont manquants.");
      return;
    }

    fetch("/attempt_craft", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify({ craft: { item_id: itemId, difficulty } }),
    })
      .then((response) => {
        if (!response.ok) {
          return response.json().then((error) => {
            throw new Error(error.error || "Une erreur s'est produite lors du craft.");
          });
        }
        return response.json();
      })
      .then((data) => {
        if (data.success) {
          console.log("Craft réussi :", data);
          this.showModal(`Craft réussi : ${data.item.name}`);
        } else {
          console.warn("Craft échoué :", data.error);
          this.showModal(`Échec du craft : ${data.error}`);
        }
      })
      .catch((error) => {
        console.error("Erreur lors du craft :", error);
        this.showModal(error.message || "Une erreur s'est produite lors du craft.");
      });
  }

  showModal(message) {
    if (this.hasModalContentTarget) {
      this.modalContentTarget.textContent = message;
    } else {
      console.error("Cible 'modalContent' introuvable.");
    }

    this.modalInstance.show();
  }
}