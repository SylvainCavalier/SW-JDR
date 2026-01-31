import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Space combat controller connected")
  }

  getCSRFToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }

  async postAction(url, body = {}) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.getCSRFToken()
      },
      body: JSON.stringify(body)
    })
    return response
  }

  async patchAction(url, body = {}) {
    const response = await fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.getCSRFToken()
      },
      body: JSON.stringify(body)
    })
    return response
  }

  async deleteAction(url) {
    const response = await fetch(url, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": this.getCSRFToken()
      }
    })
    return response
  }

  // Stat management
  async incrementStat(event) {
    const { participantId, field } = event.currentTarget.dataset
    const valueEl = event.currentTarget.closest(".d-flex").querySelector(".fw-bold")
    if (!valueEl) return

    const [current, max] = valueEl.textContent.split("/").map(n => parseInt(n.trim(), 10))
    const newValue = current + 1

    await this.patchAction("/space_combat/update_stat", {
      participant_id: participantId,
      field: field,
      value: newValue
    })
  }

  async decrementStat(event) {
    const { participantId, field } = event.currentTarget.dataset
    const valueEl = event.currentTarget.closest(".d-flex").querySelector(".fw-bold")
    if (!valueEl) return

    const [current, max] = valueEl.textContent.split("/").map(n => parseInt(n.trim(), 10))
    const newValue = Math.max(-10, current - 1)

    await this.patchAction("/space_combat/update_stat", {
      participant_id: participantId,
      field: field,
      value: newValue
    })
  }

  // Initiative
  async rollInitiative() {
    await this.postAction("/space_combat/roll_initiative")
  }

  // Position change
  async changePosition(event) {
    const { moverId, targetId, desiredPosition } = event.currentTarget.dataset
    await this.patchAction("/space_combat/change_position", {
      mover_id: moverId,
      target_id: targetId,
      desired_position: desiredPosition
    })
  }

  // Override position (MJ)
  async overridePosition(event) {
    const { positionId } = event.currentTarget.dataset
    const newPosition = event.currentTarget.value
    await this.patchAction("/space_combat/override_position", {
      position_id: positionId,
      new_position: newPosition
    })
  }

  // Fire weapon
  async fireWeapon(event) {
    const { attackerId, targetId, weaponName, weaponType } = event.currentTarget.dataset
    await this.postAction("/space_combat/fire_weapon", {
      attacker_id: attackerId,
      target_id: targetId,
      weapon_name: weaponName,
      weapon_type: weaponType
    })
  }

  // Defend
  async defend(event) {
    const { participantId } = event.currentTarget.dataset
    await this.patchAction("/space_combat/defend", {
      participant_id: participantId
    })
  }

  // End participant turn
  async endParticipantTurn(event) {
    const { participantId } = event.currentTarget.dataset
    await this.patchAction("/space_combat/end_turn", {
      participant_id: participantId
    })
  }

  // Next turn
  async nextTurn() {
    await this.patchAction("/space_combat/next_turn")
  }

  // End combat
  async endCombat() {
    if (!confirm("Terminer le combat spatial ?")) return
    await this.patchAction("/space_combat/end_combat")
    window.location.reload()
  }

  // Remove participant
  async removeParticipant(event) {
    const { participantId } = event.currentTarget.dataset
    if (!confirm("Retirer ce vaisseau du combat ?")) return
    await this.deleteAction(`/space_combat/remove_participant/${participantId}`)
    window.location.reload()
  }

  // Toggle damage flag
  async toggleDamageFlag(event) {
    const { participantId, flag } = event.currentTarget.dataset
    await this.patchAction("/space_combat/update_damage_flag", {
      participant_id: participantId,
      flag: flag
    })
  }

  // Position diagram hover interactions
  highlightShip(event) {
    const shipId = event.currentTarget.dataset.shipId
    const diagram = event.currentTarget.closest(".position-diagram")
    if (!diagram) return

    diagram.classList.add("highlighting")

    // Highlight connected lines
    diagram.querySelectorAll(".diagram-line").forEach(line => {
      const ids = (line.dataset.shipIds || "").split(",")
      if (ids.includes(shipId)) {
        line.classList.add("highlighted")
      }
    })

    // Highlight connected nodes
    const connectedIds = new Set([shipId])
    diagram.querySelectorAll(".diagram-line.highlighted").forEach(line => {
      (line.dataset.shipIds || "").split(",").forEach(id => connectedIds.add(id))
    })

    diagram.querySelectorAll(".diagram-node").forEach(node => {
      if (connectedIds.has(node.dataset.shipId)) {
        node.classList.add("highlighted")
      }
    })
  }

  unhighlightShip() {
    const diagram = this.element.querySelector(".position-diagram")
    if (!diagram) return

    diagram.classList.remove("highlighting")
    diagram.querySelectorAll(".highlighted").forEach(el => el.classList.remove("highlighted"))
  }

  highlightLine(event) {
    const ids = (event.currentTarget.dataset.shipIds || "").split(",")
    const diagram = event.currentTarget.closest(".position-diagram")
    if (!diagram) return

    diagram.classList.add("highlighting")

    // Highlight this line
    event.currentTarget.classList.add("highlighted")

    // Highlight connected nodes
    diagram.querySelectorAll(".diagram-node").forEach(node => {
      if (ids.includes(node.dataset.shipId)) {
        node.classList.add("highlighted")
      }
    })
  }

  unhighlightLine() {
    const diagram = this.element.querySelector(".position-diagram")
    if (!diagram) return

    diagram.classList.remove("highlighting")
    diagram.querySelectorAll(".highlighted").forEach(el => el.classList.remove("highlighted"))
  }
}
