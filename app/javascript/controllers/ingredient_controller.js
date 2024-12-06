import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["quantity"];
  static values = {
    objectId: Number,
    userId: Number
  };

  connect() {
    console.log("User ID:", this.userIdValue);
    console.log("Object ID:", this.objectIdValue);
  }

  async buy() {
    const objectId = this.objectIdValue;
    const userId = this.userIdValue;

    const response = await fetch(`/science/buy_inventory_object?inventory_object_id=${objectId}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    });

    if (response.ok) {
      const data = await response.json();
      this.quantityTarget.textContent = data.new_quantity;
    } else {
      const error = await response.json();
      alert(error.error || "Une erreur s'est produite.");
    }
  }
}