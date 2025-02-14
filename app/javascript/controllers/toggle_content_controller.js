import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "button"];

  toggle(event) {
    const button = event.currentTarget;
    const content = button.previousElementSibling;

    content.classList.toggle("d-none");
    button.innerText = content.classList.contains("d-none") ? "Voir plus" : "Voir moins";
  }
}