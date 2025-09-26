import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "counter", "submit"]

  connect() { this.update() }

  update() {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    // Limite à 10
    if (checked.length > 10) {
      // décocher la plus récente (celle qui a déclenché)
      const last = this.checkboxTargets.find(cb => cb === document.activeElement || cb.matches(':focus')) || checked.at(-1)
      if (last) last.checked = false
    }
    const count = this.checkboxTargets.filter(cb => cb.checked).length
    if (this.hasCounterTarget) this.counterTarget.textContent = `Sélection: ${count}/10`
    if (this.hasSubmitTarget) this.submitTarget.disabled = (count !== 10)
  }

  // Delegate click on labels/checkboxes
  checkboxTargetConnected(element) {
    element.addEventListener('change', () => this.update())
  }
}


