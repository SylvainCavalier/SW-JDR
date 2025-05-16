import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  editField(event) {
    const field = event.currentTarget.dataset.field
    const currentValue = event.currentTarget.parentElement.querySelector('span').textContent
    const newValue = prompt(`Modifier ${field}:`, currentValue)
    
    if (newValue !== null && newValue !== currentValue) {
      const data = new FormData()
      data.append('user[' + field + ']', newValue)
      
      fetch('/users/update_info', {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        },
        body: data
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          event.currentTarget.parentElement.querySelector('span').textContent = data.value
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
} 