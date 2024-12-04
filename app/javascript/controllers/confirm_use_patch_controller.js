import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    patchName: String,
    patchDescription: String,
  };

  connect() {
    console.log("Controller de confirmation de patch connecté.");
  }

  confirm(event) {
    const confirmation = confirm(
      `Vous êtes sûr de vouloir utiliser ce patch : « ${this.patchNameValue} » - ${this.patchDescriptionValue} ?`
    );
    if (!confirmation) {
      event.preventDefault(); // Annule l'action si l'utilisateur clique sur "Annuler"
    }
  }
}