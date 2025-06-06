import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"];

  remove(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const url = button.getAttribute("formaction") || button.getAttribute("href") || button.dataset.url;
    if (!url) return;
    if (!confirm(button.dataset.confirm || "Voulez-vous vraiment jeter cet objet ?")) return;
    fetch(url, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      }
    })
      .then(response => response.ok ? response.text() : Promise.reject(response))
      .then(() => {
        // Supprime la ligne ou décrémente la quantité
        const row = button.closest("tr");
        if (row) {
          // Si quantité > 1, décrémente, sinon supprime la ligne
          const qtyCell = row.querySelector("td:nth-child(2)");
          if (qtyCell && parseInt(qtyCell.textContent) > 1) {
            qtyCell.textContent = parseInt(qtyCell.textContent) - 1;
          } else {
            row.remove();
          }
        }
        this.showMessage("Objet jeté avec succès.", "success");
      })
      .catch(() => this.showMessage("Erreur lors de la suppression.", "error"));
  }

  give(event) {
    event.preventDefault();
    const form = event.target;
    const url = form.action;
    const formData = new FormData(form);
    fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: formData
    })
      .then(response => response.ok ? response.text() : Promise.reject(response))
      .then(() => {
        // Met à jour la quantité ou supprime la ligne
        const row = form.closest("tr");
        const qtyInput = form.querySelector('input[name="quantity"]');
        const qty = qtyInput ? parseInt(qtyInput.value) : 1;
        const qtyCell = row.querySelector("td:nth-child(2)");
        if (qtyCell && parseInt(qtyCell.textContent) > qty) {
          qtyCell.textContent = parseInt(qtyCell.textContent) - qty;
        } else {
          row.remove();
        }
        this.showMessage("Objet donné avec succès.", "success");
      })
      .catch(() => this.showMessage("Erreur lors du don.", "error"));
  }

  showMessage(message, type) {
    if (this.hasMessageTarget) {
      this.messageTarget.textContent = message;
      this.messageTarget.className = type === "success" ? "alert alert-success" : "alert alert-danger";
      this.messageTarget.style.display = "block";
    } else {
      alert(message);
    }
  }
} 