import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["xp"];

  connect() {
    this.csrfToken = document.querySelector("[name='csrf-token']").content;
    this.userId = this.element.dataset.userId;
    console.log("Contrôleur xp-spend connecté.");
  }

  async decrement(event) {
    event.preventDefault();
    let currentXp = parseInt(this.xpTarget.innerText.split(' ')[2]);

    if (currentXp > 0) {
      currentXp -= 1;
      this.updateXp(currentXp);
    } else {
      alert("Vous n'avez plus assez de points d'XP.");
    }
  }

  async updateXp(value) {
    const formData = new FormData();
    formData.append("xp", value);

    const response = await fetch(`/users/${this.userId}/spend_xp`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.csrfToken,
      },
      body: formData,
    });

    const data = await response.json();
    if (data.xp !== undefined) {
      this.xpTarget.innerText = `XP : ${data.xp}`;
    } else {
      console.error(data.error || "Erreur lors de la mise à jour de l'XP");
    }
  }
}