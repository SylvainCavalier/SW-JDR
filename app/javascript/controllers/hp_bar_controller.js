import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar"]

  connect() {
    this.updateBarColor()
  }

  updateBarColor() {
    const bar = this.barTarget
    const width = parseFloat(bar.style.width)
    
    if (width <= 25) {
      bar.style.background = 'linear-gradient(90deg, #ef4444 0%, #dc2626 100%)'
    } else if (width <= 50) {
      bar.style.background = 'linear-gradient(90deg, #f59e0b 0%, #d97706 100%)'
    } else if (width <= 75) {
      bar.style.background = 'linear-gradient(90deg, #10b981 0%, #059669 100%)'
    } else {
      bar.style.background = 'linear-gradient(90deg, #22c55e 0%, #16a34a 100%)'
    }
  }
} 