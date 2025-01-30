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
        // 🔹 Mise à jour dynamique des PV et des boucliers dans l'interface
        const pvElement = this.formTarget.querySelector('.pv-current'); // PV actuels
        const shieldElement = this.formTarget.querySelector('.shield-energy-current'); // Bouclier énergétique
        const shieldEchaniElement = this.formTarget.querySelector('.shield-echani-current'); // Bouclier Echani
    
        if (pvElement) pvElement.innerHTML = data.hp_current;
        if (shieldElement) shieldElement.innerHTML = data.shield_current;
        if (shieldEchaniElement) shieldEchaniElement.innerHTML = data.echani_shield_current;
    
        console.log(`✅ Dégâts appliqués : PV ${data.hp_current}, Bouclier ${data.shield_current}, Bouclier Echani ${data.echani_shield_current}`);
      } else {
        console.error("❌ Erreur lors de l'application des dégâts :", data.error);
      }
    })
  }
}
