import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["counter"]

  connect() {
    console.log("Turn counter controller connected");
  }

  async updateTurn(increment) {
    try {
      const response = await fetch(increment ? '/combat/increment_turn' : '/combat/decrement_turn', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
        }
      })

      if (!response.ok) {
        throw new Error('Erreur lors de la mise à jour du tour')
      }
    } catch (error) {
      console.error('Erreur:', error)
    }
  }

  incrementTurn(event) {
    event.preventDefault()
    this.updateTurn(true)
  }

  decrementTurn(event) {
    event.preventDefault()
    this.updateTurn(false)
  }
} 