import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  decrement(event) {
    event.preventDefault()
    let currentValue = parseInt(this.inputTarget.value)
    if (currentValue > 0) {
      this.inputTarget.value = currentValue - 1
    }
  }

  increment(event) {
    event.preventDefault()
    let currentValue = parseInt(this.inputTarget.value)
    this.inputTarget.value = currentValue + 1
  }
}
