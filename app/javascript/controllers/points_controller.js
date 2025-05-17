import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "forceValue", "cyberValue"]

  async updatePoints(userId, type, increment) {
    try {
      const response = await fetch(`/mj/update_points/${userId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/vnd.turbo-stream.html, application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({
          type: type,
          increment: increment
        })
      })

      if (!response.ok) {
        throw new Error('Erreur lors de la mise à jour des points')
      }
    } catch (error) {
      console.error('Erreur:', error)
    }
  }

  incrementForce(event) {
    const userId = event.currentTarget.dataset.userIdParam
    this.updatePoints(userId, 'force', true)
  }

  decrementForce(event) {
    const userId = event.currentTarget.dataset.userIdParam
    this.updatePoints(userId, 'force', false)
  }

  incrementCyber(event) {
    const userId = event.currentTarget.dataset.userIdParam
    this.updatePoints(userId, 'cyber', true)
  }

  decrementCyber(event) {
    const userId = event.currentTarget.dataset.userIdParam
    this.updatePoints(userId, 'cyber', false)
  }

  async reset(event) {
    const userId = event.currentTarget.dataset.userIdParam
    try {
      const response = await fetch(`/mj/reset_points/${userId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/vnd.turbo-stream.html, application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
        }
      })

      if (!response.ok) {
        throw new Error('Erreur lors de la réinitialisation des points')
      }
    } catch (error) {
      console.error('Erreur:', error)
    }
  }
} 