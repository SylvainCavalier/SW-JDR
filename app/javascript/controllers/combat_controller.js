import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["participantRow", "hp", "shield"];

  connect() {
    console.log("Combat controller connected");
  }

  canModifyParticipant(participantId, type) {
    const userRole = document.body.dataset.userRole;
    const userId = document.body.dataset.userId;
    const userPetId = document.body.dataset.userPetId;

    if (userRole === "MJ") return true;
    if (type === "Enemy") return false;
    if (type === "User") return participantId === userId;
    if (type === "Pet") return participantId === userPetId;
    return false;
  }

  getCurrentValue(participantId, type) {
    const valueElement = document.querySelector(`[data-participant-id="${participantId}"] [data-combat-target="${type}"]`)
    if (!valueElement) return null
    
    const [current] = valueElement.textContent.split('/').map(num => parseInt(num.trim(), 10))
    return current
  }

  async updateStat(participantId, participantType, type, increment) {
    if (!this.canModifyParticipant(participantId, participantType)) {
      console.error("Vous n'avez pas les permissions nécessaires")
      return
    }

    const currentValue = this.getCurrentValue(participantId, type)
    if (currentValue === null) return

    const newValue = increment ? currentValue + 1 : Math.max(0, currentValue - 1)
    const field = type === 'hp' ? 'hp_current' : 'shield_current'

    try {
      const response = await fetch('/combat/update_stat', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({
          id: participantId,
          type: participantType,
          [field]: newValue
        })
      })

      if (!response.ok) {
        console.error('Erreur lors de la mise à jour des stats')
      }
    } catch (error) {
      console.error('Erreur réseau:', error)
    }
  }

  incrementHp(event) {
    const { participantId, participantType } = event.currentTarget.dataset
    this.updateStat(participantId, participantType, 'hp', true)
  }

  decrementHp(event) {
    const { participantId, participantType } = event.currentTarget.dataset
    this.updateStat(participantId, participantType, 'hp', false)
  }

  incrementShield(event) {
    const { participantId, participantType } = event.currentTarget.dataset
    this.updateStat(participantId, participantType, 'shield', true)
  }

  decrementShield(event) {
    const { participantId, participantType } = event.currentTarget.dataset
    this.updateStat(participantId, participantType, 'shield', false)
  }

  async updateStatus(event) {
    const { participantId, participantType } = event.currentTarget.dataset
    const statusId = event.currentTarget.value

    try {
      const response = await fetch('/combat/update_status', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({
          participant_id: participantId,
          participant_type: participantType,
          status_id: statusId
        })
      })

      if (!response.ok) {
        console.error('Erreur lors de la mise à jour du statut')
      }
    } catch (error) {
      console.error('Erreur réseau:', error)
    }
  }
}