import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  lancer() {
    fetch("/science/recherche_gene", {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({})
    })
      .then(async response => {
        const data = await response.json();

        if (!response.ok) {
          // Affichage de l’erreur renvoyée par Rails
          this.showModal(data.error || "Une erreur inconnue est survenue.");
          return;
        }

        if (data.success === false) {
          this.showModal("Cela ne mène à rien. Réessayons !");
        } else if (data.upgrade) {
          this.showModal(`Amélioration du trait : ${data.property} (niveau ${data.level})`);
        } else {
          this.showModal(`Nouveau trait découvert : ${data.property} (niveau 1)`);
        }
      })
      .catch(error => {
        this.showModal("Erreur réseau ou serveur.");
        console.error("Erreur lors de la requête : ", error);
      });
  }

  showModal(message) {
    const modal = new bootstrap.Modal(document.getElementById('rechercheResultModal'));
    document.getElementById('recherche-result-title').innerText = message;
    modal.show();
  }
}