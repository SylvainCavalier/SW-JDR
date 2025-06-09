import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]
  static values = {
    ships: Array,
    parentCapacity: Number,
    parentUsed: Number
  }

  connect() {
    this.ensureDefaultSelection()
    this.checkCapacity()
  }

  ensureDefaultSelection() {
    const select = this.element.querySelector("select")
    if (select && !select.value && select.options.length > 0) {
      select.selectedIndex = 0
    }
  }

  checkCapacity() {
    const select = this.element.querySelector("select")
    if (!select) {
      this.submitTarget.disabled = true
      return
    }
    const selectedShipId = parseInt(select.value)
    const ships = this.shipsValue
    const parentCapacity = this.parentCapacityValue
    const parentUsed = this.parentUsedValue
    const selectedShip = ships.find(ship => ship.id === selectedShipId)
    if (!selectedShip) {
      this.submitTarget.disabled = true
      return
    }
    const canAdd = parentUsed + selectedShip.capacity <= parentCapacity
    this.submitTarget.disabled = !canAdd
  }
} 