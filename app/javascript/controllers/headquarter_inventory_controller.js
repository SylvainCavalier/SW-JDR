import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["list", "input"];

  connect() {
    console.log("HeadquarterInventoryController chargé !");
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute("content");
  }

  increment(event) {
    event.preventDefault();
    const itemId = event.currentTarget.dataset.itemId;
    this.updateQuantity(itemId, 1);
  }

  decrement(event) {
    event.preventDefault();
    const itemId = event.currentTarget.dataset.itemId;
    this.updateQuantity(itemId, -1);
  }

  updateQuantity(itemId, change) {
    fetch(`/headquarter/update_quantity/${itemId}?change=${change}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
      },
    })
    .then(response => response.json())
    .then(data => {
      if (data.removed) {
        document.querySelector(`#item-row-${itemId}`)?.remove();
      } else {
        this.updateObjectQuantity(itemId, data.new_quantity);
      }
    })
    .catch(error => console.error("Erreur:", error));
  }

  removeItem(event) {
    event.preventDefault();
    const itemId = event.currentTarget.dataset.itemId;
  
    fetch(`/headquarter/remove_item/${itemId}`, {
      method: "DELETE",
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "X-CSRF-Token": this.csrfToken
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.removed) {
        document.querySelector(`#item-row-${data.item_id}`)?.remove();
      }
    })
    .catch(error => console.error("Erreur:", error));
  }

  updateObjectQuantity(itemId, newQuantity) {
    const input = this.inputTargets.find(input => input.dataset.itemId === itemId);
    if (input) {
      input.value = newQuantity;
    }
  }

  addItem(event) {
    event.preventDefault();
    const form = event.target;
    const url = form.action;
    const formData = new FormData(form);
  
    fetch(url, {
      method: "POST",
      body: formData,
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "X-CSRF-Token": this.csrfToken
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.error) {
        console.error("Erreur:", data.error);
        return;
      }
  
      this.insertNewItem(data);
      form.reset();
    })
    .catch(error => console.error("Erreur:", error));
  }
  
  insertNewItem(data) {
    const userInventory = document.querySelector(`#collapse${data.user_id} tbody`);
    
    if (!userInventory) {
      console.error("Impossible de trouver l'inventaire de l'utilisateur.");
      return;
    }
  
    // Création de la nouvelle ligne
    const newRow = document.createElement("tr");
    newRow.id = `item-row-${data.item_id}`;
    newRow.innerHTML = `
      <td>${data.name}</td>
      <td>
        <input type="text"
               value="${data.new_quantity}"
               readonly
               class="form-control text-center"
               data-headquarter-inventory-target="input"
               data-item-id="${data.item_id}">
      </td>
      <td>
        <div class="d-flex">
          <button class="btn btn-outline-warning btn-sm mx-1"
                  data-action="click->headquarter-inventory#decrement"
                  data-item-id="${data.item_id}">-
          </button>
          <button class="btn btn-outline-success btn-sm mx-1"
                  data-action="click->headquarter-inventory#increment"
                  data-item-id="${data.item_id}">+
          </button>
          <button class="btn btn-outline-danger btn-sm mx-1"
                  data-action="click->headquarter-inventory#removeItem"
                  data-item-id="${data.item_id}">❌
          </button>
        </div>
      </td>
    `;
  
    userInventory.appendChild(newRow);
  }
}