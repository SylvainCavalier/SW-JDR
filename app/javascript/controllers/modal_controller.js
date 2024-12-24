import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["title", "message", "confirmButton"];

  connect() {
    this.element.addEventListener("show.bs.modal", (event) => {
      const button = event.relatedTarget;

      // Récupération des valeurs dynamiques
      const title = button.getAttribute("data-modal-title");
      const message = button.getAttribute("data-modal-message");
      const confirmButtonText = button.getAttribute("data-modal-confirm-button");
      const action = button.getAttribute("data-modal-confirm-action");
      const path = button.getAttribute("data-delete-path");

      // Mise à jour de la modale
      this.titleTarget.textContent = title;
      this.messageTarget.textContent = message;
      this.confirmButtonTarget.textContent = confirmButtonText;

      // Gestion de l'action spécifique
      this.confirmButtonTarget.onclick = () => {
        if (action === "sell#confirm") {
          this.handleSell(path);
        } else if (action === "delete#confirm") {
          this.handleDelete(path);
        } else if (action === "dissociate#confirm") {
          this.handleDissociate(path);
        }
      };
    });
  }

  handleSell(path) {
    const form = document.createElement("form");
    form.method = "POST";
    form.action = path;

    const csrfInput = document.createElement("input");
    csrfInput.type = "hidden";
    csrfInput.name = "authenticity_token";
    csrfInput.value = document.querySelector('meta[name="csrf-token"]').content;

    form.appendChild(csrfInput);
    document.body.appendChild(form);
    form.submit();
  }

  handleDelete(path) {
    const form = document.createElement("form");
    form.method = "POST";
    form.action = path;

    const methodInput = document.createElement("input");
    methodInput.type = "hidden";
    methodInput.name = "_method";
    methodInput.value = "delete";

    const csrfInput = document.createElement("input");
    csrfInput.type = "hidden";
    csrfInput.name = "authenticity_token";
    csrfInput.value = document.querySelector('meta[name="csrf-token"]').content;

    form.appendChild(methodInput);
    form.appendChild(csrfInput);
    document.body.appendChild(form);
    form.submit();
  }

  handleDissociate(path) {
    const form = document.createElement("form");
    form.method = "POST";
    form.action = path;

    const csrfInput = document.createElement("input");
    csrfInput.type = "hidden";
    csrfInput.name = "authenticity_token";
    csrfInput.value = document.querySelector('meta[name="csrf-token"]').content;

    form.appendChild(csrfInput);
    document.body.appendChild(form);
    form.submit();
  }
}