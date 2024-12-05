import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button"];

  connect() {
    console.log("Popup controller connected");
    this.locked = false; // État initial du bouton
  }

  disableButton(event) {
    if (this.locked) {
      event.preventDefault();
      alert("Veuillez attendre 5 minutes avant de relancer un jet de groupe.");
    } else {
      this.locked = true;
      this.buttonTarget.disabled = true;
      setTimeout(() => {
        this.locked = false;
        this.buttonTarget.disabled = false;
      }, 300); // 5 minutes en millisecondes
    }
  }

  close(event) {
    event.preventDefault();
    const popup = document.getElementById("group-luck-popup");
    if (popup) popup.style.display = "none";
  }
}