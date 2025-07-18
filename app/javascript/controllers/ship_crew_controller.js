import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["flashMessage"]

  // Met à jour le type assignable en fonction de la sélection
  updateAssignableType(event) {
    const select = event.target
    const selectedOption = select.options[select.selectedIndex]
    const assignableType = selectedOption.dataset.assignableType || ""
    
    const form = select.closest("form")
    const assignableTypeInput = form.querySelector('input[name="assignable_type"]')
    if (assignableTypeInput) {
      assignableTypeInput.value = assignableType
    }
  }

  // Assigne un membre d'équipage à un poste
  async assignCrewMember(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    const position = formData.get('position')
    
    try {
      const response = await fetch(form.action, {
        method: form.method,
        body: formData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      const data = await response.json()
      
      if (response.ok) {
        this.showFlashMessage("success", data.message)
        this.updatePositionDisplay(position, data)
      } else {
        this.showFlashMessage("danger", data.error)
      }
    } catch (error) {
      console.error("Erreur lors de l'assignation:", error)
      this.showFlashMessage("danger", "Une erreur est survenue lors de l'assignation")
    }
  }

  // Met à jour l'affichage d'un poste spécifique
  updatePositionDisplay(position, data) {
    const positionElement = this.element.querySelector(`[data-position="${position}"]`)
    if (!positionElement) return

    const memberInfo = positionElement.querySelector('.member-info')
    if (!memberInfo) return

    if (data.assignable_name) {
      // Poste occupé
      memberInfo.className = 'member-info p-2 bg-success bg-opacity-25 rounded'
      memberInfo.innerHTML = `
        <div class="d-flex align-items-center">
          <div class="member-avatar-placeholder me-2">
            <i class="fa-solid fa-user"></i>
          </div>
          <div class="flex-grow-1">
            <strong>${data.assignable_name}</strong><br>
            <small class="text-muted">${data.assignable_type}</small>
          </div>
        </div>
      `
      
      // Mettre à jour la carte du poste
      const positionCard = positionElement.closest('.position-card')
      if (positionCard) {
        positionCard.classList.remove('vacant')
        positionCard.classList.add('occupied')
      }
    } else {
      // Poste libéré
      memberInfo.className = 'member-info p-2 bg-secondary bg-opacity-25 rounded text-center'
      memberInfo.innerHTML = `
        <i class="fa-solid fa-user-slash text-muted"></i>
        <small class="text-muted d-block">Poste vacant</small>
      `
      
      // Mettre à jour la carte du poste
      const positionCard = positionElement.closest('.position-card')
      if (positionCard) {
        positionCard.classList.remove('occupied')
        positionCard.classList.add('vacant')
      }
      
      // Réinitialiser le formulaire
      const form = positionElement.closest('.position-card').querySelector('form')
      if (form) {
        const select = form.querySelector('select[name="assignable_id"]')
        if (select) select.value = ""
        
        const assignableTypeInput = form.querySelector('input[name="assignable_type"]')
        if (assignableTypeInput) assignableTypeInput.value = ""
      }
    }
  }

  // Affichage des messages flash
  showFlashMessage(type, message) {
    const alertHtml = `
      <div class="alert alert-${type} alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    `
    this.flashMessageTarget.innerHTML = alertHtml
    
    // Auto-supprimer le message après 5 secondes
    setTimeout(() => {
      const alert = this.flashMessageTarget.querySelector('.alert')
      if (alert) {
        alert.remove()
      }
    }, 5000)
  }
} 