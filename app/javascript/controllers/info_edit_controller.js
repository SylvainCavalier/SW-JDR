import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "editForm", "input", "editIcon"]

  toggleEdit(event) {
    this.displayTarget.classList.add('d-none')
    this.editFormTarget.classList.remove('d-none')
    this.editIconTarget.classList.add('d-none')
    this.inputTarget.focus()
  }

  saveEdit(event) {
    event.preventDefault()
    
    const data = new FormData()
    data.append(`user[${this.inputTarget.dataset.field}]`, this.inputTarget.value)
    
    fetch(this.inputTarget.dataset.url, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      },
      body: data
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      return response.json()
    })
    .then(data => {
      if (data.success) {
        // Mettre à jour l'affichage avec la nouvelle valeur
        const field = this.inputTarget.dataset.field
        const displayValue = field === 'age' ? `${data.value} ans` :
                           field === 'height' ? `${data.value} cm` :
                           field === 'weight' ? `${data.value} kg` :
                           data.value || 'Non défini'
        
        this.displayTarget.textContent = displayValue
        
        // Masquer le formulaire d'édition et afficher le texte
        this.editFormTarget.classList.add('d-none')
        this.displayTarget.classList.remove('d-none')
        this.editIconTarget.classList.remove('d-none')
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