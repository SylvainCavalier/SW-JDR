import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["title", "message", "confirmButton"];

  connect() {
    const modalElement = document.getElementById("genericModal");

    // Listener pour configurer la modale à l'ouverture
    this.element.addEventListener("show.bs.modal", (event) => {
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
        } else {
          console.error("Cible 'confirmButton' introuvable !");
        }
      } else {
        this.hideTransferSection();
        if (this.hasConfirmButtonTarget) {
          this.confirmButtonTarget.textContent = confirmButtonText;
          this.confirmButtonTarget.onclick = () => {
            if (action === "sell#confirm") {
              this.handleSell(button.getAttribute("data-delete-path"));
            } else if (action === "delete#confirm") {
              this.handleDelete(button.getAttribute("data-delete-path"));
            } else if (action === "dissociate#confirm") {
              this.handleDissociate(button.getAttribute("data-delete-path"));
            }
          };
        }
      }
    });

    // Listener pour réinitialiser l'état de la modale à la fermeture
    modalElement.addEventListener("hidden.bs.modal", () => {
      this.hideTransferSection();
      document.body.classList.remove("modal-open"); // Suppression de la classe Bootstrap
      document.querySelectorAll(".modal-backdrop").forEach((el) => el.remove()); // Suppression des éléments backdrop
      console.log("Modale fermée, état nettoyé.");
    });
  }

  attemptCraft(event) {
    event.preventDefault();
  
    const button = event.currentTarget;
    const itemId = button.getAttribute("data-item-id");
    const difficulty = button.getAttribute("data-difficulty");
    const category = button.getAttribute("data-category");
  
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
      .then((response) => {
        if (!response.ok) {
          return response.json().then((error) => {
            throw new Error(error.error || "Une erreur s'est produite lors du craft.");
          });
        }
        return response.json();
      })
      .then((data) => {
        if (data.success) {
          console.log("Craft réussi :", data);
      
          if (data.modal && (category === "patch" || category === "injection")) {
            this.injectModalData(button, data);
      
            const modal = new bootstrap.Modal(document.getElementById("genericModal"));
            modal.show();
          } else {
            alert(`Craft réussi : ${data.item.name}`);
          }
        } else {
          console.warn("Craft échoué :", data.error);

          setTimeout(() => {
            const modal = bootstrap.Modal.getInstance(document.getElementById("genericModal"));
            if (modal) modal.hide();
          }, 50);
        }
      })
      .catch((error) => {
        console.error("Erreur lors du craft :", error);
        alert(error.message || "Une erreur s'est produite lors du craft.");
      })
      .finally(() => {
        console.log("Requête de craft terminée.");
        window.location.reload();
      });
  }

  showTransferSection(itemId) {
    const transferSection = document.querySelector("#transfer-section");
    if (!transferSection) {
      console.error("L'élément transfer-section est introuvable !");
      return;
    }
  
    transferSection.style.display = "block";
  
    const transferInput = document.querySelector("#transfer-item-id");
    if (transferInput) {
      transferInput.value = itemId;
    } else {
      console.error("L'élément transfer-item-id est introuvable !");
    }
  
    // L'appel à /science/players est encapsulé dans une vérification stricte
    if (itemId) {
      fetch("/science/players")
        .then((response) => {
          if (!response.ok) throw new Error("Impossible de charger la liste des joueurs.");
          return response.json();
        })
        .then((players) => {
          const playerSelect = document.querySelector("#player-select");
          if (playerSelect) {
            playerSelect.innerHTML = players.map(
              (player) => `<option value="${player.id}">${player.username}</option>`
            ).join("");
          }
        })
        .catch((error) => {
          console.error("Erreur lors du chargement des joueurs :", error);
          alert("Impossible de charger la liste des joueurs.");
        });
    } else {
      console.warn("Aucun itemId fourni, aucun joueur chargé.");
    }
  }

  hideTransferSection() {
    const transferSection = document.querySelector("#transfer-section");
    const playerSelect = document.querySelector("#player-select");

    if (transferSection) {
      transferSection.style.display = "none";
    }

    if (playerSelect) {
      playerSelect.innerHTML = "";
    }

    console.log("Section de transfert masquée et réinitialisée.");
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
      .then((response) => {
        if (!response.ok) return response.json().then((data) => { throw new Error(data.error); });
        return response.json();
      })
      .then((data) => {
        if (data.success) {
          alert(data.message);
          location.reload();
        } else {
          throw new Error(data.error || "Une erreur s'est produite lors du transfert.");
        }
      })
      .catch((error) => {
        console.error("Erreur lors du transfert :", error);
        alert(error.message || "Une erreur s'est produite lors du transfert.");
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