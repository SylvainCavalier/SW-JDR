import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "editForm", "input", "editButton"]

  showEdit(event) {
    const field = event.currentTarget.dataset.field
    const displayElement = event.currentTarget.parentElement.querySelector('[data-info-section-target="display"]')
    const editForm = event.currentTarget.parentElement.querySelector('[data-info-section-target="editForm"]')
    const input = editForm.querySelector('[data-info-section-target="input"]')
    
    // Extraire la valeur numérique du texte affiché
    let currentValue = displayElement.textContent.trim()
    if (field === 'age') currentValue = currentValue.replace(' ans', '')
    if (field === 'height') currentValue = currentValue.replace(' cm', '')
    if (field === 'weight') currentValue = currentValue.replace(' kg', '')
    if (currentValue === 'Non spécifié') currentValue = ''
    
    // Configurer le champ de saisie
    input.value = currentValue
    input.dataset.field = field
    
    // Afficher le formulaire d'édition et masquer le texte et le bouton d'édition
    displayElement.classList.add('hidden')
    event.currentTarget.classList.add('hidden')
    editForm.classList.remove('hidden')
    editForm.classList.add('flex')
    
    // Focus sur le champ de saisie
    input.focus()
  }

  saveEdit(event) {
    const editForm = event.currentTarget.parentElement
    const input = editForm.querySelector('[data-info-section-target="input"]')
    const field = input.dataset.field
    const value = input.value
    const displayElement = editForm.parentElement.querySelector('[data-info-section-target="display"]')
    const editButton = editForm.parentElement.querySelector('[data-info-section-target="editButton"]')
    
    // Récupérer l'ID de l'utilisateur depuis l'URL
    const userId = window.location.pathname.split('/').filter(Boolean)[1]
    
    const data = new FormData()
    data.append(`user[${field}]`, value)
    
    fetch(`/users/${userId}/update_info`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      },
      body: data
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Mettre à jour l'affichage avec la nouvelle valeur
        const displayValue = field === 'age' ? `${data.value} ans` :
                           field === 'height' ? `${data.value} cm` :
                           field === 'weight' ? `${data.value} kg` :
                           data.value || 'Non spécifié'
        
        displayElement.textContent = displayValue
        
        // Masquer le formulaire d'édition et afficher le texte et le bouton d'édition
        editForm.classList.add('hidden')
        editForm.classList.remove('flex')
        displayElement.classList.remove('hidden')
        editButton.classList.remove('hidden')
      } else {
        alert('Une erreur est survenue lors de la mise à jour')
      }
    })
    .catch(error => {
      console.error('Erreur:', error)
      alert('Une erreur est survenue lors de la mise à jour')
    })
  }
} 