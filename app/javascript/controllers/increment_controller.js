import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    console.log("Increment controller is connected");
  }

  increment(event) {
    event.preventDefault();
    let currentValue = parseInt(this.inputTarget.value) || 0;
    this.inputTarget.value = currentValue + 1;
    // Optionnel : déclencher un événement personnalisé si d'autres composants veulent l'écouter
    this.inputTarget.dispatchEvent(new CustomEvent('value-changed', { detail: { value: this.inputTarget.value } }));
  }

  decrement(event) {
    event.preventDefault();
    let currentValue = parseInt(this.inputTarget.value) || 0;
    if (currentValue > 0) {
      this.inputTarget.value = currentValue - 1;
      // Optionnel : déclencher un événement personnalisé si d'autres composants veulent l'écouter
      this.inputTarget.dispatchEvent(new CustomEvent('value-changed', { detail: { value: this.inputTarget.value } }));
    }
  }
}