import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["categorySelect", "objectSelect"];
  static values = { userId: Number };

  connect() {
    try {
      this.originalObjects = JSON.parse(this.element.dataset.objects || "[]");
    } catch (error) {
      console.error("Invalid JSON data for objects:", error);
      this.originalObjects = [];
    }
    console.log("Category Select Target:", this.categorySelectTarget); // Vérifie la cible
    console.log("Object Select Target:", this.objectSelectTarget); // Vérifie la cible
  }

  filterObjects(event) {
    const selectedCategory = this.categorySelectTarget.value;

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
  }
}