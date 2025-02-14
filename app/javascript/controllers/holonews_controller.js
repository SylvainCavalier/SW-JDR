import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["counter"];

  connect() {
    this.updateCounter();
  }

  updateCounter() {
    fetch("/holonews/count")
      .then(response => response.json())
      .then(data => {
        if (data.count > 0) {
          this.counterTarget.textContent = data.count;
          this.counterTarget.style.display = "inline-block";
        } else {
          this.counterTarget.style.display = "none";
        }
      });
  }
}