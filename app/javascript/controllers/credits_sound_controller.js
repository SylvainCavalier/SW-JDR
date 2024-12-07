import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { soundPath: String };

  connect() {
    // Attache un listener pour détecter les mises à jour du Turbo Stream
    document.addEventListener("turbo:frame-load", (event) => {
      if (event.target.id === `user_${this.element.dataset.userId}_credits_frame`) {
        this.playSound();
      }
    });
  }

  playSound() {
    const audio = new Audio(this.soundPathValue);
    audio.play();
  }
}