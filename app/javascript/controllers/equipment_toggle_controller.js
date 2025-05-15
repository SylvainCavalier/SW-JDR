// app/javascript/controllers/equipment_toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    userId: Number
  }

  equip(event) {
    event.preventDefault()
    const equipmentId = event.currentTarget.dataset.equipmentToggleEquipmentIdValue

    fetch(`/users/${this.userIdValue}/equip_equipment`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ equipment_id: equipmentId })
    }).then(response => {
      if (response.ok) location.reload()
    })
  }

  remove(event) {
    event.preventDefault()
    const slot = event.currentTarget.dataset.equipmentToggleSlotValue

    fetch(`/users/${this.userIdValue}/equipment/${encodeURIComponent(slot)}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      }
    }).then(response => {
      if (response.ok) location.reload()
    })
  }

  delete(event) {
    event.preventDefault()
    const equipmentId = event.currentTarget.dataset.equipmentToggleEquipmentIdValue

    fetch(`/users/${this.userIdValue}/equipment/delete/${equipmentId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      }
    }).then(response => {
      if (response.ok) location.reload()
    })
  }

  add(event) {
    event.preventDefault()
    const form = event.target
    const slot = form.dataset.equipmentToggleSlotValue
    const formData = new FormData(form)
    formData.append("slot", slot)

    fetch(`/users/${this.userIdValue}/add_equipment`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: formData
    }).then(response => {
      if (response.ok) location.reload()
    })
  }
}