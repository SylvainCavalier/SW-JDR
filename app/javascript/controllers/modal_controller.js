import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["title", "message", "confirmButton"];

  connect() {
    const modalElement = document.getElementById("genericModal");

    modalElement.addEventListener("show.bs.modal", (event) => {
      const button = event.relatedTarget;
      if (!button) return;

      const title = button.getAttribute("data-modal-title");
      const message = button.getAttribute("data-modal-message");
      const confirmButtonText = button.getAttribute("data-modal-confirm-button");
      const action = button.getAttribute("data-modal-confirm-action");
      const itemId = button.getAttribute("data-item-id");
      const spheroId = button.getAttribute("data-sphero-id");
      const deletePath = button.getAttribute("data-delete-path");

      if (this.hasTitleTarget && title) this.titleTarget.textContent = title;
      if (this.hasMessageTarget && message) this.messageTarget.textContent = message;

      if (action === "craft#transfer" && itemId) {
        this.showTransferSection(itemId);
        if (this.hasConfirmButtonTarget) {
          this.confirmButtonTarget.textContent = confirmButtonText;
          this.confirmButtonTarget.onclick = () => this.handleTransfer(itemId);
        }
      } else if (action === "craft#attempt") {
        this.confirmButtonTarget.textContent = confirmButtonText;
        this.confirmButtonTarget.onclick = () => this.attemptCraft(itemId);
      } else if (["sell#confirm", "delete#confirm", "dissociate#confirm"].includes(action) && deletePath) {
        this.confirmButtonTarget.textContent = confirmButtonText;
        this.confirmButtonTarget.onclick = () => this.submitForm(deletePath, action);
      } else if (["sphero#activate", "sphero#deactivate", "sphero#delete", "sphero#repair", "sphero#repair_kit", "sphero#recharge"].includes(action) && spheroId) {
        this.confirmButtonTarget.textContent = confirmButtonText;
      
        if (action === "sphero#repair") {
          const repairCost = button.getAttribute("data-repair-cost");
          this.messageTarget.textContent = `Voulez-vous réparer ce sphéro-droïde pour ${repairCost} composants ?`;
          this.confirmButtonTarget.onclick = () => this.updateSphero(action, spheroId, repairCost);
        } else if (action === "sphero#recharge") {
          const rechargeCost = button.getAttribute("data-recharge-cost");
          this.messageTarget.textContent = `Voulez-vous recharger ce bouclier pour ${rechargeCost} crédits ?`;
          this.confirmButtonTarget.onclick = () => this.updateSphero(action, spheroId, rechargeCost);
        } else {
          this.confirmButtonTarget.onclick = () => this.updateSphero(action, spheroId);
        }
      } else if (action === "sphero#transfer" && spheroId) {
        this.showSpheroTransferSection(spheroId);
      }
    });

    modalElement.addEventListener("hidden.bs.modal", () => this.hideTransferSection());
  }

  /**
   * ✅ Gère l'activation, désactivation et suppression des sphéro-droïdes
   */
  updateSphero(action, spheroId, rechargeCost = null) {
    let url = `/spheros/${spheroId}`;
    let method = "POST";
    let body = null;

    if (action === "sphero#activate") url += "/activate";
    else if (action === "sphero#deactivate") url += "/deactivate";
    else if (action === "sphero#delete") method = "DELETE";
    else if (action === "sphero#repair") url += "/repair";
    else if (action === "sphero#repair_kit") url += "/repair_kit";
    else if (action === "sphero#recharge") {
      url += "/recharge";
      body = JSON.stringify({ recharge_cost: rechargeCost });
    }

    fetch(url, {
      method: method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: body
    })
    .then((response) => {
      if (!response.ok) throw new Error("Erreur lors de l'opération.");
      this.closeModal();
      location.reload();
    })
    .catch((error) => console.error("Erreur :", error));
  }

  /**
   * ✅ Gestion du transfert d'un sphéro-droïde
   */
  showSpheroTransferSection(spheroId) {
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

          if (this.hasConfirmButtonTarget) {
            this.confirmButtonTarget.onclick = () => {
              const playerId = playerSelect.value;
              this.updateSpheroTransfer(spheroId, playerId);
            };
          }
        })
        .catch((error) => console.error("Erreur lors du chargement des joueurs :", error));
    }
  }

  /**
   * ✅ Effectue le transfert du sphéro-droïde
   */
  updateSpheroTransfer(spheroId, playerId) {
    fetch(`/spheros/${spheroId}/transfer`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify({ player_id: playerId }),
    })
    .then((response) => {
      if (!response.ok) throw new Error("Erreur lors du transfert.");
      this.closeModal(); // ✅ Ferme la modale immédiatement
      location.reload(); // ✅ Recharge la page
    })
    .catch((error) => console.error("Erreur :", error));
  }

  /**
   * ✅ Affiche la section cachée du transfert et récupère la liste des joueurs
   */
  showTransferSection(itemId) {
    const transferSection = document.querySelector("#transfer-section");
    const playerSelect = document.querySelector("#player-select");

    if (transferSection) transferSection.style.display = "block";

    if (playerSelect) {
      fetch("/science/players")
        .then((response) => response.json())
        .then((players) => {
          playerSelect.innerHTML = players
            .map(player => `<option value="${player.id}">${player.username}</option>`)
            .join("");
        })
        .catch(error => console.error("Erreur lors du chargement des joueurs :", error));
    }
  }

  /**
   * ✅ Cache la section de transfert
   */
  hideTransferSection() {
    const transferSection = document.querySelector("#transfer-section");
    const playerSelect = document.querySelector("#player-select");

    if (transferSection) transferSection.style.display = "none";
    if (playerSelect) playerSelect.innerHTML = "";
  }

  /**
   * ✅ Gère le transfert d'un objet vers un autre joueur
   */
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
          console.log("Transfert réussi :", data);
  
          // Récupère le controller craft depuis le parent contenant le controller craft
          const craftElement = document.querySelector("[data-controller~='craft']");
          if (!craftElement) {
            console.warn("Controller 'craft' introuvable.");
            return;
          }
  
          const craftController = this.application.getControllerForElementAndIdentifier(craftElement, "craft");
          if (craftController) {
            craftController.updateObjectQuantity(data.item.id, data.item.new_quantity);
          } else {
            console.warn("Controller 'craft' introuvable sur l'élément.");
          }
  
          alert(data.message);
          const modalElement = document.getElementById("genericModal");
          const modalInstance = bootstrap.Modal.getInstance(modalElement);
          if (modalInstance) modalInstance.hide();
        } else {
          alert(data.error);
        }
      });
  }

  /**
   * ✅ Gère les actions de vente, suppression et dissociation
   */
  submitForm(path, action) {
    if (!path) return;
    const method = action === "delete#confirm" ? "DELETE" : "POST";
    const form = document.createElement("form");
    form.method = "POST";
    form.action = path;

    if (method !== "POST") {
      const methodInput = document.createElement("input");
      methodInput.type = "hidden";
      methodInput.name = "_method";
      methodInput.value = method;
      form.appendChild(methodInput);
    }

    const csrfInput = document.createElement("input");
    csrfInput.type = "hidden";
    csrfInput.name = "authenticity_token";
    csrfInput.value = document.querySelector('meta[name="csrf-token"]').content;
    form.appendChild(csrfInput);

    document.body.appendChild(form);
    form.submit();
  }

  /**
   * ✅ Ferme la modale après une action réussie
   */
  closeModal() {
    const modalElement = document.getElementById("genericModal");
    const modalInstance = bootstrap.Modal.getInstance(modalElement);
    if (modalInstance) modalInstance.hide();
  }

  /**
   * ✅ Gère la tentative de craft
   */
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

          const craftController = this.application.getControllerForElementAndIdentifier(this.element, "craft");
      
          if (data.ingredients) {
            data.ingredients.forEach((ingredient) => {
              craftController.updateIngredientQuantity(ingredient.name, ingredient.new_quantity);
            });
          }
      
          craftController.updateObjectQuantity(data.item.id, data.item.new_quantity);
      
          alert(`Craft réussi : ${data.item.name}`);
        } else {
          console.warn("Craft échoué :", data.error);
          alert(`Échec du craft : ${data.error}`);
        }
      });
  }
}