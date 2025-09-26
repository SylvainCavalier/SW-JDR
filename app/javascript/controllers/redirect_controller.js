import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { delay: Number }
  connect() {
    const url = this.element.dataset.url
    const delay = this.delayValue || 0
    if (url) {
      if (delay > 0) {
        setTimeout(() => Turbo.visit(url), delay)
      } else {
        Turbo.visit(url)
      }
    }
  }
}


