import { Controller } from "@hotwired/stimulus"

// Contrôleur Stimulus pour la persistance de l'état des accordéons Bootstrap
export default class extends Controller {
  connect() {
    // Sélectionne tous les triggers d'accordéon de la page
    document.querySelectorAll('[data-bs-toggle="collapse"]').forEach((toggle) => {
      const targetId = toggle.getAttribute('data-bs-target');
      if (!targetId) return;
      const storageKey = "accordion_" + targetId;
      const target = document.querySelector(targetId);
      if (!target) return;

      // Applique l'état sauvegardé au chargement
      const savedState = localStorage.getItem(storageKey);
      if (savedState === "false") {
        target.classList.remove("show");
        toggle.setAttribute("aria-expanded", "false");
      } else if (savedState === "true") {
        target.classList.add("show");
        toggle.setAttribute("aria-expanded", "true");
      }

      // Ajoute un écouteur pour sauvegarder l'état à chaque clic
      toggle.addEventListener("click", () => {
        setTimeout(() => {
          const isOpen = target.classList.contains("show");
          localStorage.setItem(storageKey, isOpen);
        }, 350); // délai pour laisser l'animation Bootstrap finir
      });
    });
  }
} 