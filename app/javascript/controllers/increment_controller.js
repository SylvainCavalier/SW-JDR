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
  }

  decrement(event) {
    event.preventDefault();
    let currentValue = parseInt(this.inputTarget.value) || 0;
    if (currentValue > 0) {
      this.inputTarget.value = currentValue - 1;
    }
  }
}