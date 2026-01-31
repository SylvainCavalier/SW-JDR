import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter", "submit"]
  static values = { max: Number }

  connect() {
    this.update()
  }

  update() {
    const length = this.inputTarget.value.length
    const max = this.maxValue
    const remaining = max - length

    this.counterTarget.textContent = `${length} / ${max}`

    if (remaining < 0) {
      this.counterTarget.classList.add("text-danger")
      this.counterTarget.classList.remove("text-warning", "text-muted")
      this.submitTarget.disabled = true
    } else if (remaining < max * 0.1) {
      this.counterTarget.classList.add("text-warning")
      this.counterTarget.classList.remove("text-danger", "text-muted")
      this.submitTarget.disabled = false
    } else {
      this.counterTarget.classList.add("text-muted")
      this.counterTarget.classList.remove("text-danger", "text-warning")
      this.submitTarget.disabled = false
    }
  }
}
