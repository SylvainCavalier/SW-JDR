import { Controller } from "@hotwired/stimulus";

// Applique / retire la classe `active-turn` sur la ligne du participant en cours,
// d'après l'état porté par le marqueur (rafraîchi via Turbo Streams).
// Met aussi à jour le style du bouton de surbrillance côté MJ.
export default class extends Controller {
  static values = {
    activeRowId: String,
    activeType: String,
    activeId: Number
  };

  connect() {
    this.apply();
  }

  activeRowIdValueChanged() {
    this.apply();
  }

  apply() {
    document.querySelectorAll("tr.active-turn").forEach((tr) => {
      tr.classList.remove("active-turn");
    });

    if (this.activeRowIdValue) {
      const row = document.getElementById(this.activeRowIdValue);
      if (row) row.classList.add("active-turn");
    }

    document
      .querySelectorAll("[data-action*='combat#highlightParticipant']")
      .forEach((btn) => {
        const matches =
          this.activeTypeValue &&
          btn.dataset.participantType === this.activeTypeValue &&
          btn.dataset.participantId === String(this.activeIdValue);
        btn.classList.toggle("btn-warning", matches);
        btn.classList.toggle("btn-outline-warning", !matches);
        btn.title = matches
          ? "Retirer la surbrillance"
          : "Mettre en surbrillance (à son tour)";
      });
  }
}
