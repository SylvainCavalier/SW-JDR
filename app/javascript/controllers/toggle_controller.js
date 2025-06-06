import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggleTourelles(event) {
    const select = document.getElementById('tourelles-count');
    select.disabled = !event.target.checked;
  }

  toggleTorpilles(event) {
    const select = document.getElementById('torpilles-count');
    select.disabled = !event.target.checked;
  }

  toggleMissiles(event) {
    const select = document.getElementById('missiles-count');
    select.disabled = !event.target.checked;
  }
} 