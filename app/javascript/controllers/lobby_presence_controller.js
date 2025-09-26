import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.interval = setInterval(() => this.ping(), 10000)
    this.ping()
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  ping() {
    const token = document.querySelector('meta[name="csrf-token"]').content
    fetch("/pazaak/lobbies/ping", { method: "POST", headers: { "X-CSRF-Token": token } })
  }
}


