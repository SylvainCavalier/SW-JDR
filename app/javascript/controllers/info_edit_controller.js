import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "input"]

  toggleEdit(event) {
    const field = event.target.closest("p")
    const display = field.querySelector("[data-info-edit-target='display']")
    const input = field.querySelector("[data-info-edit-target='input']")
    const icon = field.querySelector(".edit-icon")

    if (input.classList.contains("d-none")) {
      // Passer en mode édition
      display.classList.add("d-none")
      input.classList.remove("d-none")
      input.focus()
      icon.classList.add("d-none")

      // Ajouter les écouteurs d'événements
      input.addEventListener("blur", this.saveChanges.bind(this))
      input.addEventListener("keypress", (e) => {
        if (e.key === "Enter") {
          this.saveChanges({ target: input })
        }
      })
    }
  }

  async saveChanges(event) {
    const input = event.target
    const field = input.closest("p")
    const display = field.querySelector("[data-info-edit-target='display']")
    const icon = field.querySelector(".edit-icon")
    const url = input.dataset.url
    const fieldName = input.dataset.field
    const value = input.value

    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({
          user: {
            [fieldName]: value
          }
        })
      })

      if (response.ok) {
        // Mettre à jour l'affichage
        let displayValue = value
        if (fieldName === "age") displayValue += " ans"
        if (fieldName === "height") displayValue += " cm"
        if (fieldName === "weight") displayValue += " kg"
        display.textContent = displayValue || "Non défini"

        // Revenir à l'affichage normal
        display.classList.remove("d-none")
        input.classList.add("d-none")
        icon.classList.remove("d-none")
      } else {
        console.error("Erreur lors de la sauvegarde")
      }
    } catch (error) {
      console.error("Erreur:", error)
    }
  }
} 