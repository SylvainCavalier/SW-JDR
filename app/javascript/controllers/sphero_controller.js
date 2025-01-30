import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

  connect() {
    const modalElement = document.getElementById("genericModal");

    modalElement.addEventListener("hidden.bs.modal", () => this.hideTransferSection());
  }

  showMedipackTransferSection(event) {
    const button = event.currentTarget;
    const spheroId = button.dataset.spheroId; // ✅ Extraction du spheroId
    console.log("🔍 Vérification spheroId :", spheroId); // Debugging

    if (!spheroId) {
        alert("Erreur : ID du sphéro-droïde introuvable.");
        return;
    }

    const transferSection = document.querySelector("#transfer-section");
    const playerSelect = document.querySelector("#player-select");
    const confirmButton = document.querySelector("#genericModal .modal-footer .btn-primary"); // ✅ Sélectionne le bon bouton

    if (transferSection) transferSection.style.display = "block";

    if (playerSelect) {
      fetch("/science/players")
        .then(response => response.json())
        .then(players => {
          playerSelect.innerHTML = players
            .map(player => `<option value="${player.id}">${player.username}</option>`)
            .join("");

          confirmButton.onclick = () => { // ✅ Utilisation du bon bouton
            const playerId = playerSelect.value;
            this.useMedipack(spheroId, playerId);
          } ;
        })
        .catch(error => console.error("Erreur lors du chargement des joueurs :", error));
    }
  }

  hideTransferSection() {
    const transferSection = document.querySelector("#transfer-section");
    const playerSelect = document.querySelector("#player-select");

    if (transferSection) transferSection.style.display = "none";
    if (playerSelect) playerSelect.innerHTML = "";
  }

  useMedipack(spheroId, playerId) {
    if (!playerId) {
        alert("Veuillez sélectionner un équipier.");
        return;
    }

    fetch(`/spheros/${spheroId}/use_medipack`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ player_id: playerId })
    })
    .then(response => {
        if (!response.ok) throw new Error("Erreur lors de l'utilisation du medipack.");
        return response.text();
    })
    .then(() => {
        const modalElement = document.getElementById("genericModal");
        const modalInstance = bootstrap.Modal.getInstance(modalElement);
        if (modalInstance) modalInstance.hide(); // ✅ Fermeture de la modale
        location.reload();
    })
    .catch(error => console.error("Erreur :", error));
  }
  
  /**
   * ✅ Ajoute un medipack au sphéro-droïde directement.
   */
  addMedipack(event) {
    const spheroId = event.currentTarget.dataset.spheroId;
    const medipackDisplay = document.getElementById(`medipack-count-${spheroId}`);
  
    fetch(`/spheros/${spheroId}/add_medipack`, { 
      method: "POST",
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            if (medipackDisplay) {
                medipackDisplay.textContent = data.new_medipack_count;
            }
            this.showFlashMessage(data.message, "success"); // ✅ On affiche `data.message`
        } else {
            this.showFlashMessage(data.error, "danger"); // ✅ On affiche `data.error`
        }
    })
    .catch(error => console.error("Erreur :", error));
  }

  /**
   * ✅ Effectue un jet de protection avec l'habileté du sphéro-droïde.
   */
  protect(event) {
    const button = event.currentTarget;
    const spheroId = button.dataset.spheroId;
  
    fetch(`/spheros/${spheroId}/protect`, {
      method: "POST",
      headers: { 
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json()) // ✅ Maintenant Rails renvoie bien du JSON
    .then(data => {
      if (data.success) {
        this.showFlashMessage(data.message, "success");
      } else {
        this.showFlashMessage(data.message, "danger");
      }
    })
    .catch(error => console.error("Erreur :", error));
  }
  
  /**
   * ✅ Affiche un message flash sans recharger la page.
   */
  showFlashMessage(message, type) {
    const flashContainer = document.getElementById("flash-container");
    const flashMessage = document.createElement("div");
  
    flashMessage.className = `alert alert-${type} alert-dismissible fade show`;
    flashMessage.role = "alert";
    flashMessage.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `;
  
    flashContainer.appendChild(flashMessage);
  
    // Disparaît après 3 secondes
    setTimeout(() => {
      flashMessage.classList.remove("show");
      flashMessage.classList.add("fade");
      setTimeout(() => flashMessage.remove(), 500);
    }, 3000);
  }

  /**
   * ✅ Effectue un jet d'attaque avec le skill de tir du sphéro-droïde.
   */
  attack(event) {
    const button = event.currentTarget;
    const spheroId = button.dataset.spheroId;
  
    fetch(`/spheros/${spheroId}/attack`, {
      method: "POST",
      headers: { 
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json()) // ✅ Assure que Rails renvoie du JSON
    .then(data => {
      if (data.success) {
        this.showFlashMessage(data.message, "success");
      } else {
        this.showFlashMessage(data.message, "danger");
      }
    })
    .catch(error => console.error("Erreur :", error));
  }
}