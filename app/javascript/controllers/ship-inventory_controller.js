import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["list", "form"]

  connect() {
    console.log("Ship inventory controller connected")
  }

  addItem(event) {
    event.preventDefault();
    const form = event.target;
    const formData = new FormData(form);

    fetch(form.action, {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.listTarget.insertAdjacentHTML('beforeend', data.html);
        form.reset();
      } else {
        console.error('Erreur:', data.error);
      }
    })
    .catch(error => {
      console.error('Erreur:', error);
    });
  }

  removeItem(event) {
    event.preventDefault();
    const button = event.target;
    const itemId = button.dataset.id;
    const shipId = button.dataset.shipId;
    const url = `/ships/${shipId}/ship_objects/${itemId}`;

    fetch(url, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        button.closest('tr').remove();
      } else {
        console.error('Erreur:', data.error);
      }
    })
    .catch(error => {
      console.error('Erreur:', error);
    });
  }
} 