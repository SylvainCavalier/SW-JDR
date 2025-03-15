import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content"];

  toggle(event) {
    event.preventDefault();
    const content = event.currentTarget.previousElementSibling;

    content.classList.toggle("text-truncate");
    event.currentTarget.textContent = content.classList.contains("text-truncate")
      ? "Voir plus"
      : "Voir moins";
  }
}