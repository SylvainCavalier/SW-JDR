import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form"];

  connect() {
    this.csrfToken = document.querySelector("[name='csrf-token']").content;
  }

  applyDamage(event) {
    event.preventDefault();

    const damageValue = this.inputTarget.value;
    const formData = new FormData(this.formTarget);

    fetch(this.formTarget.action, {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.csrfToken,
      },
      body: formData,
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Mise à jour des PV ou du bouclier directement dans l'interface
        const pvElement = this.formTarget.querySelector('.pv-current'); // Sélectionne l'élément PV
        if (pvElement) {
          pvElement.innerHTML = data.hp_current; // Mise à jour des PV
        }
      } else {
        console.error("Erreur lors de l'application des dégâts");
      }
    });
  }
}
