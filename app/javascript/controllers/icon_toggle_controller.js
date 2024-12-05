// app/javascript/controllers/icon_toggle_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["icon", "attackType"];

  connect() {
    this.activateDefaultIcon();
  }

  activate(event) {
    // Désactiver toutes les icônes
    this.iconTargets.forEach(icon => icon.classList.remove("active"));
  
    // Activer l'icône cliquée
    const currentIcon = event.currentTarget;
    currentIcon.classList.add("active");
  
    // Mettre à jour le champ masqué avec le type d'attaque
    const attackType = currentIcon.dataset.attackType;
    this.attackTypeTarget.value = attackType;
  
    console.log("Icône activée :", attackType); // Ajout de log pour vérifier
    console.log("Valeur actuelle dans le champ masqué :", this.attackTypeTarget.value);
  }

  activateDefaultIcon() {
    if (this.iconTargets.length > 0) {
      this.iconTargets[0].classList.add("active");
      this.attackTypeTarget.value = this.iconTargets[0].dataset.attackType;
    }
  }
}