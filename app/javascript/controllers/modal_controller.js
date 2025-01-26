import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["title", "message", "confirmButton"];

  connect() {
    const modalElement = document.getElementById("genericModal");

    // Listener pour configurer la modale à l'ouverture
    modalElement.addEventListener("show.bs.modal", (event) => {
      const button = event.relatedTarget;

      if (!button) {
        console.warn("Aucun élément déclencheur (relatedTarget) trouvé. La modale a été ouverte programmatique.");
        return;
      }

      const title = button.getAttribute("data-modal-title");
      const message = button.getAttribute("data-modal-message");
      const confirmButtonText = button.getAttribute("data-modal-confirm-button");
      const action = button.getAttribute("data-modal-confirm-action");
      const itemId = button.getAttribute("data-item-id");

      if (this.hasTitleTarget && title) this.titleTarget.textContent = title;
      if (this.hasMessageTarget && message) this.messageTarget.textContent = message;

      if (action === "craft#transfer" && itemId) {
        this.showTransferSection(itemId);
        if (this.hasConfirmButtonTarget) {
          this.confirmButtonTarget.textContent = confirmButtonText;
          this.confirmButtonTarget.onclick = () => this.handleTransfer(itemId);
        }
      } else {
        this.hideTransferSection();
      }
    });

    // Listener pour réinitialiser l'état de la modale à la fermeture
    modalElement.addEventListener("hidden.bs.modal", () => {
      this.hideTransferSection();
    });
  }

  attemptCraft(event) {
    event.preventDefault();

    const button = event.currentTarget;
    const itemId = button.getAttribute("data-item-id");
    const difficulty = button.getAttribute("data-difficulty");

    if (!itemId || !difficulty) {
      console.error("Les attributs 'data-item-id' ou 'data-difficulty' sont manquants.");
      return;
    }

    fetch("/attempt_craft", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify({ craft: { item_id: itemId, difficulty } }),
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.success) {
          console.log("Craft réussi :", data);
          alert(`Craft réussi : ${data.item.name}`);
        } else {
          console.warn("Craft échoué :", data.error);
          alert(`Échec du craft : ${data.error}`);
        }
      })
      .catch((error) => {
        console.error("Erreur lors du craft :", error);
        alert("Une erreur s'est produite lors du craft.");
      });
  }

  showTransferSection(itemId) {
    const transferSection = document.querySelector("#transfer-section");
    const playerSelect = document.querySelector("#player-select");

    if (transferSection) transferSection.style.display = "block";

    if (playerSelect) {
      fetch("/science/players")
        .then((response) => response.json())
        .then((players) => {
          playerSelect.innerHTML = players
            .map((player) => `<option value="${player.id}">${player.username}</option>`)
            .join("");
        })
        .catch((error) => {
          console.error("Erreur lors du chargement des joueurs :", error);
        });
    }
  }

  hideTransferSection() {
    const transferSection = document.querySelector("#transfer-section");
    const playerSelect = document.querySelector("#player-select");

    if (transferSection) transferSection.style.display = "none";
    if (playerSelect) playerSelect.innerHTML = "";
  }

  handleTransfer(itemId) {
    const playerId = document.querySelector("#player-select")?.value;

    if (!playerId) {
      alert("Veuillez sélectionner un joueur pour le transfert.");
      return;
    }

    fetch("/science/attempt_transfer", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify({ item_id: itemId, player_id: playerId }),
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.success) {
          alert(data.message);
          const modalElement = document.getElementById("genericModal");
          const modalInstance = bootstrap.Modal.getInstance(modalElement);
          if (modalInstance) modalInstance.hide();
        } else {
          alert(data.error);
        }
      })
      .catch((error) => {
        console.error("Erreur lors du transfert :", error);
        alert("Une erreur s'est produite lors du transfert.");
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