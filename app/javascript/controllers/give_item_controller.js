import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["playerSelect", "categorySelect", "objectSelect", "quantityInput", "message"];
  static values = { objects: Array };

  connect() {
    try {
      this.originalObjects = this.objectsValue || [];
    } catch (error) {
      console.error("Erreur lors de l'analyse des données des objets :", error);
      this.originalObjects = [];
    }
  }

  selectPlayer(event) {
    const playerId = this.playerSelectTarget.value;
    console.log("Joueur sélectionné :", playerId);
    // Ajoutez ici une logique si nécessaire en fonction du joueur
  }

  filterObjects(event) {
    const selectedCategory = this.categorySelectTarget.value;
    console.log("Catégorie sélectionnée :", selectedCategory);

    let filteredObjects = this.originalObjects;
    if (selectedCategory !== "Toutes les catégories") {
      filteredObjects = this.originalObjects.filter(
        (object) => object.category === selectedCategory
      );
    }

    this.objectSelectTarget.innerHTML = "";
    filteredObjects.forEach((object) => {
      const option = document.createElement("option");
      option.value = object.id;
      option.textContent = object.name;
      this.objectSelectTarget.appendChild(option);
    });

    console.log("Menu des objets mis à jour :", filteredObjects);
  }

  submit(event) {
    event.preventDefault();

    const userId = this.playerSelectTarget.value;
    const objectId = this.objectSelectTarget.value;
    const quantity = this.quantityInputTarget.value;

    if (!userId || !objectId || !quantity) {
      this.displayMessage("Veuillez remplir tous les champs.", "error");
      return;
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute("content");

    fetch(this.element.action, {
      method: "POST",
      headers: { 
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ user_id: userId, object_id: objectId, quantity }),
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error("Erreur lors de l'envoi.");
        }
        return response.json();
      })
      .then((data) => {
        if (data.success) {
          this.displayMessage(data.message, "success");
        } else {
          this.displayMessage(data.error, "error");
        }
      })
      .catch(() => {
        this.displayMessage("Une erreur est survenue lors de l'envoi.", "error");
      });
  }


  displayMessage(message, type) {
    this.messageTarget.textContent = message;
    this.messageTarget.className = type === "success" ? "alert alert-success" : "alert alert-danger";
  }
}