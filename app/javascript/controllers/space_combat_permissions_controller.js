import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.checkPermissions()
  }

  checkPermissions() {
    const container = this.element.closest("[data-user-role]") || document.querySelector("[data-user-role]")
    if (!container) return

    const userRole = container.dataset.userRole
    const userGroupId = container.dataset.userGroupId
    const participantSide = this.element.dataset.participantSide

    let canModify = false

    if (userRole === "MJ") {
      canModify = true
    } else if (participantSide === "0") {
      // Joueurs peuvent modifier les vaisseaux de leur côté
      canModify = true
    }

    if (canModify) {
      this.element.classList.add("can-modify")
    } else {
      this.element.classList.remove("can-modify")
    }
  }
}
