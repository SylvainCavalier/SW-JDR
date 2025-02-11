import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["preview"];

  preview(event) {
    const input = event.target;
    const file = input.files[0];

    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        this.previewTarget.src = e.target.result;
      };
      reader.readAsDataURL(file);

      input.closest("form").submit();
    }
  }
}