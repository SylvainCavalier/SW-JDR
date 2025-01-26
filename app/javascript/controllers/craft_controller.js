import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { userId: Number };

  updateIngredientQuantity(ingredientName, newQuantity) {
    const ingredientElements = document.querySelectorAll(`[data-ingredient-name='${ingredientName}']`);
    
    if (ingredientElements.length > 0) {
      ingredientElements.forEach((ingredientElement) => {
        const quantityElement = ingredientElement.querySelector("[data-craft-target='ingredientQuantity']");
        if (quantityElement) {
          quantityElement.textContent = newQuantity;
          ingredientElement.style.color = newQuantity > 0 ? "green" : "red";
        } else {
          console.warn(`Quantité introuvable pour l'ingrédient '${ingredientName}' dans un des éléments.`);
        }
      });
    } else {
      console.warn(`Élément pour l'ingrédient '${ingredientName}' introuvable ou mal structuré.`);
    }
  }

  updateObjectQuantity(objectId, newQuantity) {
    const objectElement = document.querySelector(`[data-item-id='${objectId}']`);
    const quantityElement = objectElement?.querySelector("[data-craft-target='objectQuantity']");
    if (quantityElement) {
      quantityElement.textContent = newQuantity;
      quantityElement.style.color = newQuantity === 0 ? "red" : "white";
    } else {
      console.warn(`Élément pour l'objet ID '${objectId}' introuvable ou mal structuré.`);
    }
  }
}