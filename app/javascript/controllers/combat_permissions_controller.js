import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.checkPermissions()
  }

  checkPermissions() {
    const userRole = document.body.dataset.userRole
    const userId = document.body.dataset.userId
    const userPetId = document.body.dataset.userPetId
    const participantId = this.element.dataset.participantId
    const participantType = this.element.dataset.participantType

    let canModify = false

    if (userRole === "MJ") {
      canModify = true
    } else if (participantType === "turn") {
      canModify = false
    } else if (participantType === "Enemy") {
      canModify = false
    } else if (participantType === "User") {
      canModify = participantId === userId
    } else if (participantType === "Pet") {
      canModify = participantId === userPetId
    }

    if (canModify) {
      this.element.classList.add('can-modify')
    } else {
      this.element.classList.remove('can-modify')
    }
  }
} 