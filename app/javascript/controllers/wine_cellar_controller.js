import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    addUrl: String,
    removeUrl: String
  }

  add(event) {
    const button = event.currentTarget
    const drinkId = button.dataset.drinkId
    const inventoryObjectId = button.dataset.inventoryObjectId

    const quantity = prompt("Combien de bouteilles voulez-vous ajouter ?", "1")
    if (quantity === null || quantity === "") return

    fetch(this.addUrlValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        drink_id: drinkId,
        quantity: parseInt(quantity)
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        const quantityCell = document.getElementById('quantity_' + inventoryObjectId)
        if (quantityCell) {
          quantityCell.textContent = data.new_quantity
        }
      } else {
        alert('Erreur : ' + data.error)
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('Une erreur est survenue.')
    })
  }

  remove(event) {
    const button = event.currentTarget
    const drinkId = button.dataset.drinkId
    const inventoryObjectId = button.dataset.inventoryObjectId

    const quantity = prompt("Combien de bouteilles voulez-vous retirer ?", "1")
    if (quantity === null || quantity === "") return

    fetch(this.removeUrlValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        drink_id: drinkId,
        quantity: parseInt(quantity)
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        if (data.deleted) {
          const row = document.getElementById('wine_cellar_drink_' + inventoryObjectId)
          if (row) {
            row.remove()
          }
        } else {
          const quantityCell = document.getElementById('quantity_' + inventoryObjectId)
          if (quantityCell) {
            quantityCell.textContent = data.new_quantity
          }
        }
      } else {
        alert('Erreur : ' + data.error)
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('Une erreur est survenue.')
    })
  }
}

