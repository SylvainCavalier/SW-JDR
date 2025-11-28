import { Controller } from "@hotwired/stimulus"

// Controller pour les interactions lors des événements
export default class extends Controller {
  connect() {
    console.log("Chatouille event controller connected")
  }

  selectChoice(event) {
    const mood = event.currentTarget.dataset.mood || "happy"
    this.updateKessarMood(mood)
  }

  updateKessarMood(mood) {
    const portrait = document.getElementById("kessar-portrait")
    if (portrait) {
      const moodCapitalized = mood.charAt(0).toUpperCase() + mood.slice(1)
      portrait.src = `/assets/Kessar${moodCapitalized}.png`
      
      // Animation de transition
      portrait.style.transform = "scale(1.1)"
      setTimeout(() => {
        portrait.style.transform = "scale(1)"
      }, 200)
    }
  }
}

