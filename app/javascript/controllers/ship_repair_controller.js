import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["flashMessage", "repairKitCount", "componentCount", "astromechCount"];

  connect() {
    console.log("Ship repair controller connected");
  }

  useRepairKit(event) {
    event.preventDefault();
    const form = event.target;

    fetch(form.action, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.message) {
        this.showFlashMessage(data.message + '<br><small>' + data.dice_details + '</small>', 'success');
        if (this.hasRepairKitCountTarget) {
          this.repairKitCountTarget.textContent = data.repair_kit_count;
        }
        // Recharger la page pour mettre à jour les barres de HP
        window.location.reload();
      } else if (data.error) {
        this.showFlashMessage(data.error, 'danger');
      }
    })
    .catch(error => {
      console.error('Error:', error);
      this.showFlashMessage('Une erreur est survenue', 'danger');
    });
  }

  deployAstromech(event) {
    event.preventDefault();
    const form = event.target;

    fetch(form.action, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.message) {
        // Créer une modal pour afficher le résultat de la mission
        this.showAstromechModal(data);
        
        // Mettre à jour les compteurs
        if (this.hasAstromechCountTarget) {
          this.astromechCountTarget.textContent = data.astromech_droids;
        }
        if (this.hasComponentCountTarget) {
          this.componentCountTarget.textContent = data.component_count;
        }
        
        // Recharger la page après 3 secondes pour mettre à jour les barres de HP
        setTimeout(() => {
          window.location.reload();
        }, 3000);
      } else if (data.error) {
        this.showFlashMessage(data.error, 'danger');
      }
    })
    .catch(error => {
      console.error('Error:', error);
      this.showFlashMessage('Une erreur est survenue', 'danger');
    });
  }

  showAstromechModal(data) {
    // Créer une modal Bootstrap pour afficher le résultat
    const modalHtml = `
      <div class="modal fade" id="astromechModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
          <div class="modal-content bg-dark text-light">
            <div class="modal-header border-secondary">
              <h5 class="modal-title">
                <i class="fa-solid fa-robot me-2"></i>
                Mission du Droïde Astromec
              </h5>
              <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
              <div class="text-center mb-3">
                <img src="/assets/ships/astromec.png" alt="Droïde Astromec" style="max-width: 150px;" class="mb-3">
              </div>
              <div class="alert alert-${data.droid_destroyed ? 'warning' : 'success'}">
                ${data.message}
              </div>
              <div class="row text-center">
                <div class="col-md-4">
                  <div class="bg-success bg-opacity-25 p-2 rounded">
                    <strong>HP Restaurés</strong><br>
                    <span class="text-success">${data.hp_restored}</span>
                  </div>
                </div>
                <div class="col-md-4">
                  <div class="bg-warning bg-opacity-25 p-2 rounded">
                    <strong>Composants</strong><br>
                    <span class="text-warning">${data.components_used}</span>
                  </div>
                </div>
                <div class="col-md-4">
                  <div class="bg-${data.droid_destroyed ? 'danger' : 'info'} bg-opacity-25 p-2 rounded">
                    <strong>Droïdes</strong><br>
                    <span class="text-${data.droid_destroyed ? 'danger' : 'info'}">${data.astromech_droids}</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="modal-footer border-secondary">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Fermer</button>
            </div>
          </div>
        </div>
      </div>
    `;
    
    // Ajouter la modal au body
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    
    // Afficher la modal
    const modal = new bootstrap.Modal(document.getElementById('astromechModal'));
    modal.show();
    
    // Supprimer la modal après fermeture
    document.getElementById('astromechModal').addEventListener('hidden.bs.modal', function() {
      this.remove();
    });
  }

  showFlashMessage(message, type) {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
    alertDiv.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    this.flashMessageTarget.appendChild(alertDiv);
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      if (alertDiv.parentNode) {
        alertDiv.remove();
      }
    }, 5000);
  }
} 