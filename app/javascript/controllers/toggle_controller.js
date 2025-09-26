import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggleTourelles(event) {
    const select = document.getElementById('turrets-count');
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

  toggleTurrets(event) {
    const turretOptions = document.getElementById('turret-options');
    if (event.target.checked) {
      turretOptions.style.display = 'block';
    } else {
      turretOptions.style.display = 'none';
    }
  }
} 