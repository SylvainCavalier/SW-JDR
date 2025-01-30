import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button"];

  connect() {
    console.log("Rules controller connected");

    const scrollToTopButton = this.buttonTarget;
    const container = this.element;

    // Affiche le bouton lorsque l'utilisateur fait défiler vers le bas
    container.addEventListener("scroll", () => {
      if (container.scrollTop > 200) {
        scrollToTopButton.style.display = "block";
      } else {
        scrollToTopButton.style.display = "none";
      }
    });

    // Ajoute un comportement de défilement vers le haut au clic
    scrollToTopButton.addEventListener("click", () => {
      container.scrollTo({ top: 0, behavior: "smooth" });
    });
  }
}