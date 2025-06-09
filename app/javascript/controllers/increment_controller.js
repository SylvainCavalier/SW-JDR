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
    this.updateQuantity();
  }

  decrement(event) {
    event.preventDefault();
    let currentValue = parseInt(this.inputTarget.value) || 0;
    if (currentValue > 0) {
      this.inputTarget.value = currentValue - 1;
      this.updateQuantity();
    }
  }

  updateQuantity() {
    const shipId = this.inputTarget.dataset.shipId;
    const objectId = this.inputTarget.dataset.objectId;
    const quantity = this.inputTarget.value;
    const url = `/ships/${shipId}/ship_objects/${objectId}`;

    fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        ship_object: {
          quantity: quantity
        }
      })
    })
    .then(response => response.json())
    .then(data => {
      if (!data.success) {
        console.error('Erreur:', data.error);
      }
    })
    .catch(error => {
      console.error('Erreur:', error);
    });
  }
}