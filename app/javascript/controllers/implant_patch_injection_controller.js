// app/javascript/controllers/implant_patch_injection_controller.js
import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = {
    userId: Number
  }

  connect() {
    if (!this.hasUserIdValue) {
      const meta = document.querySelector("meta[name='current-user-id']")
      if (meta) {
        this.userIdValue = meta.content
      }
    }
  }

  usePatch(event) {
    const button = event.currentTarget
    const name = button.dataset.patchName || "inconnu"
    const description = button.dataset.patchDescription || ""
  
    const confirmation = confirm(`Vous êtes sûr de vouloir utiliser ce patch : « ${name} » - ${description} ?`)
    if (!confirmation) return
  
    this._post(`/users/${this.userIdValue}/use_patch`)
  }

  equipImplant(event) {
    const implantId = event.currentTarget.dataset.implantId
    if (!implantId) {
      console.error("Aucun ID d'implant trouvé")
      return
    }

    this._post(`/users/${this.userIdValue}/equip_implant`, { implant_id: implantId })
  }

  unequipImplant(event) {
    event.preventDefault()
    this._post(`/users/${this.userIdValue}/unequip_implant`)
  }

  equipPatch(event) {
    const patchId = event.currentTarget.dataset.patchId
    if (!patchId) {
      console.error("Aucun ID de patch trouvé")
      return
    }

    this._post(`/users/${this.userIdValue}/equip_patch`, { patch_id: patchId })
  }

  equipInjection(event) {
    const injectionId = event.currentTarget.dataset.injectionId
    if (!injectionId) {
      console.error("Aucun ID d'injection trouvé")
      return
    }

    const isJunkie = event.currentTarget.closest('[data-junkie]')?.dataset.junkie === 'true'
    const confirmation = isJunkie ? 
      confirm("Êtes-vous sûr de vouloir utiliser cette injection ?") :
      confirm("Cette injection va vous coûter 2 PV. Êtes-vous sûr ?")
    if (!confirmation) return

    this._post(`/users/${this.userIdValue}/equip_injection`, { injection_id: injectionId })
  }

  deactivateInjection(event) {
    event.preventDefault()
    this._post(`/users/${this.userIdValue}/deactivate_injection`)
  }

  _post(url, data = {}) {
    fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(data)
    })
      .then(response => {
        if (!response.ok) {
          return response.json().then(data => {
            throw new Error(data.error || "Une erreur est survenue.")
          })
        }
        return response.json()
      })
      .then(data => {
        if (data.success) {
          alert(data.success)
          Turbo.visit(window.location.href, { action: "replace" })
        } else if (data.error) {
          alert(data.error)
        } else {
          Turbo.visit(window.location.href, { action: "replace" })
        }
      })
      .catch(error => {
        console.error("Erreur:", error)
        alert(error.message || "Une erreur réseau est survenue.")
      })
  }
}