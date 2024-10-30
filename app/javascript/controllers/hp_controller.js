import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hpCurrent"];

  connect() {
    this.csrfToken = document.querySelector("[name='csrf-token']").content;
    this.userId = this.element.dataset.userId;
    this.maxHp = parseInt(this.element.dataset.maxHp);
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
      this.hpCurrentTarget.innerText = `PV : ${data.hp_current} / ${this.maxHp}`;
    } else {
      console.error("Erreur lors de la mise à jour des PV");
    }
  }

  decrement(event) {
    event.preventDefault();
    let currentHp = parseInt(this.hpCurrentTarget.innerText.split(' ')[2]);
    if (currentHp > -10) {
      currentHp = Math.max(currentHp - 1, -10);
      this.updateHp(currentHp);
    }
  }

  increment(event) {
    event.preventDefault();
    let currentHp = parseInt(this.hpCurrentTarget.innerText.split(' ')[2]);
    if (currentHp < this.maxHp) {
      currentHp = Math.min(currentHp + 1, this.maxHp);
      this.updateHp(currentHp);
    }
  }
}
