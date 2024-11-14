import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["flashMessageContainer"]

  connect() {
    console.log("xpForm controller connected");
  }
}