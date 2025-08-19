import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="aliases"
export default class extends Controller {
  static values = { data: Array };

  connect() {
    console.log("Aliases controller connected");
  }
}
