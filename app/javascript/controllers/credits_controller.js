import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["amount"];

  update(newAmount) {
    this.amountTarget.innerText = `Crédits : ${newAmount}`;
  }
}