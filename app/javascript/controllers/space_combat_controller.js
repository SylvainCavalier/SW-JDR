import { Controller } from "@hotwired/stimulus"

// Assistant de combat spatial : toutes les actions passent par le serveur,
// qui rejoue les règles et rediffuse le plateau via Turbo Stream.
export default class extends Controller {
  connect() {
    this.busy = false
  }

  // --- Utilitaires ----------------------------------------------------------

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }

  async send(method, url, body = {}) {
    if (this.busy) return null
    this.busy = true

    try {
      const response = await fetch(url, {
        method: method,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify(body)
      })

      let data = {}
      try {
        data = await response.json()
      } catch (error) {
        data = {}
      }

      if (!response.ok || data.success === false) {
        this.toast(data.error || "Action impossible", "error")
        return null
      }

      if (data.summary) {
        this.toast(data.summary, data.hit === false || data.won === false ? "warning" : "info")
      }
      return data
    } catch (error) {
      this.toast("Erreur réseau", "error")
      return null
    } finally {
      this.busy = false
    }
  }

  toast(message, kind = "info") {
    const container = document.getElementById("space_combat_toast")
    if (!container) return

    const node = document.createElement("div")
    node.className = `space-combat-toast-item space-combat-toast-${kind}`
    node.textContent = message
    container.appendChild(node)
    setTimeout(() => node.remove(), 8000)
  }

  // --- Statistiques ---------------------------------------------------------

  currentValue(button) {
    const valueEl = button.closest(".d-flex")?.querySelector("[data-stat-value]")
    if (!valueEl) return null
    return parseInt(valueEl.textContent.split("/")[0].trim(), 10)
  }

  async incrementStat(event) {
    const { participantId, field } = event.currentTarget.dataset
    const current = this.currentValue(event.currentTarget)
    if (current === null || Number.isNaN(current)) return

    await this.send("PATCH", "/space_combat/update_stat", {
      participant_id: participantId, field: field, value: current + 1
    })
  }

  async decrementStat(event) {
    const { participantId, field } = event.currentTarget.dataset
    const current = this.currentValue(event.currentTarget)
    if (current === null || Number.isNaN(current)) return

    await this.send("PATCH", "/space_combat/update_stat", {
      participant_id: participantId, field: field, value: current - 1
    })
  }

  // --- Conduite du combat (MJ) ---------------------------------------------

  async rollInitiative() {
    await this.send("POST", "/space_combat/roll_initiative")
  }

  async nextTurn() {
    await this.send("PATCH", "/space_combat/next_turn")
  }

  async endCombat() {
    if (!confirm("Terminer le combat spatial ? Le journal et les vaisseaux ennemis seront effacés.")) return
    await fetch("/space_combat/end_combat", {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.csrfToken }
    })
    window.location.reload()
  }

  async removeParticipant(event) {
    const { participantId, shipName } = event.currentTarget.dataset
    if (!confirm(`Retirer ${shipName || "ce vaisseau"} du combat ?`)) return

    await fetch(`/space_combat/remove_participant/${participantId}`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": this.csrfToken }
    })
    window.location.reload()
  }

  async toggleStealth(event) {
    await this.send("PATCH", "/space_combat/toggle_stealth", {
      participant_id: event.currentTarget.dataset.participantId
    })
  }

  async toggleDamageFlag(event) {
    const { participantId, flag } = event.currentTarget.dataset
    await this.send("PATCH", "/space_combat/update_damage_flag", {
      participant_id: participantId, flag: flag
    })
  }

  async overridePosition(event) {
    await this.send("PATCH", "/space_combat/override_position", {
      position_id: event.currentTarget.dataset.positionId,
      new_position: event.currentTarget.value
    })
  }

  // --- Mouvement ------------------------------------------------------------

  movementPayload(event) {
    const { moverId, targetId } = event.currentTarget.dataset
    return { mover_id: moverId, target_id: targetId }
  }

  async changePosition(event) {
    await this.send("PATCH", "/space_combat/change_position", {
      ...this.movementPayload(event),
      desired_position: event.currentTarget.dataset.desiredPosition
    })
  }

  async boostThrusters(event) {
    await this.send("PATCH", "/space_combat/boost_thrusters", this.movementPayload(event))
  }

  async attemptBlindSpot(event) {
    await this.send("PATCH", "/space_combat/attempt_blind_spot", this.movementPayload(event))
  }

  // --- Actions offensives ---------------------------------------------------

  async fireWeapon(event) {
    const { attackerId, targetId, weaponId } = event.currentTarget.dataset
    await this.send("POST", "/space_combat/fire_weapon", {
      attacker_id: attackerId, target_id: targetId, weapon_id: weaponId
    })
  }

  async tractorBeam(event) {
    const { attackerId, targetId } = event.currentTarget.dataset
    await this.send("POST", "/space_combat/tractor_beam", {
      attacker_id: attackerId, target_id: targetId
    })
  }

  // --- Défense et équipage --------------------------------------------------

  async countermeasure(event) {
    await this.send("PATCH", "/space_combat/countermeasure", {
      participant_id: event.currentTarget.dataset.participantId
    })
  }

  async repairWithKit(event) {
    await this.send("PATCH", "/space_combat/repair", {
      participant_id: event.currentTarget.dataset.participantId, mode: "kit"
    })
  }

  async repairWithComponents(event) {
    const amount = prompt("Combien de composants utiliser ? (1 composant = 1 PB)")
    if (!amount) return

    await this.send("PATCH", "/space_combat/repair", {
      participant_id: event.currentTarget.dataset.participantId,
      mode: "components",
      amount: parseInt(amount, 10)
    })
  }

  async command(event) {
    await this.send("PATCH", "/space_combat/command", {
      participant_id: event.currentTarget.dataset.participantId
    })
  }

  async detect(event) {
    const { participantId, targetId } = event.currentTarget.dataset
    await this.send("PATCH", "/space_combat/detect", {
      participant_id: participantId, target_id: targetId
    })
  }

  // --- Fuite ----------------------------------------------------------------

  async flee(event) {
    await this.send("PATCH", "/space_combat/flee", {
      participant_id: event.currentTarget.dataset.participantId
    })
  }

  async startAstrogation(event) {
    await this.send("PATCH", "/space_combat/start_astrogation", {
      participant_id: event.currentTarget.dataset.participantId
    })
  }

  async hyperspaceJump(event) {
    await this.send("PATCH", "/space_combat/hyperspace_jump", {
      participant_id: event.currentTarget.dataset.participantId
    })
  }

  // --- Tour -----------------------------------------------------------------

  async endParticipantTurn(event) {
    const data = await this.send("PATCH", "/space_combat/end_turn", {
      participant_id: event.currentTarget.dataset.participantId
    })
    if (data?.turn_advanced) this.toast("Tous les vaisseaux ont joué : tour suivant", "info")
  }

  // --- Diagramme de positions ----------------------------------------------

  highlightShip(event) {
    const shipId = event.currentTarget.dataset.shipId
    const diagram = event.currentTarget.closest(".position-diagram")
    if (!diagram) return

    diagram.classList.add("highlighting")

    diagram.querySelectorAll(".diagram-line").forEach(line => {
      const ids = (line.dataset.shipIds || "").split(",")
      if (ids.includes(shipId)) line.classList.add("highlighted")
    })

    const connectedIds = new Set([shipId])
    diagram.querySelectorAll(".diagram-line.highlighted").forEach(line => {
      (line.dataset.shipIds || "").split(",").forEach(id => connectedIds.add(id))
    })

    diagram.querySelectorAll(".diagram-node").forEach(node => {
      if (connectedIds.has(node.dataset.shipId)) node.classList.add("highlighted")
    })
  }

  unhighlightShip() {
    this.clearHighlight()
  }

  highlightLine(event) {
    const ids = (event.currentTarget.dataset.shipIds || "").split(",")
    const diagram = event.currentTarget.closest(".position-diagram")
    if (!diagram) return

    diagram.classList.add("highlighting")
    event.currentTarget.classList.add("highlighted")

    diagram.querySelectorAll(".diagram-node").forEach(node => {
      if (ids.includes(node.dataset.shipId)) node.classList.add("highlighted")
    })
  }

  unhighlightLine() {
    this.clearHighlight()
  }

  clearHighlight() {
    const diagram = this.element.querySelector(".position-diagram")
    if (!diagram) return

    diagram.classList.remove("highlighting")
    diagram.querySelectorAll(".highlighted").forEach(el => el.classList.remove("highlighted"))
  }
}
